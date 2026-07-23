// SPDX-License-Identifier: Apache-2.0
/* global lpac */

'use strict';
'require view';
'require ui';
'require poll';
'require lpac';

const isReadonlyView = !L.hasViewPermission() || null;

function operationLabel(operation) {
	switch (operation) {
	case 'install':
		return _('Install');
	case 'enable':
		return _('Enable');
	case 'disable':
		return _('Disable');
	case 'delete':
		return _('Delete');
	default:
		return _('Unknown');
	}
}

return view.extend({
	processing: false,
	processBlocked: false,
	notifications: [],
	processAllButton: null,
	removeAllButton: null,
	protectedWarning: null,
	activeNotificationJob: null,
	activeNotificationToken: null,
	activeNotificationOrigin: null,
	activeNotificationPhase: null,
	processQueue: [],
	processIndex: 0,
	processCompleted: 0,
	processRemoveAfterSuccess: false,
	processProgress: null,
	processGeneration: 0,
	notificationStatusFailures: 0,
	pollRegistered: false,

	notificationSequence: function(notification) {
		const seq = notification?.seqNumber;

		return Number.isInteger(seq) && seq >= 0 && seq <= 4294967295
			? String(seq)
			: null;
	},

	validNotifications: function() {
		return this.notifications.filter(function(notification) {
			return this.notificationSequence(notification) !== null;
		}, this);
	},

	notificationReplayBlocked: function(notification) {
		return notification?.replay_blocked === true || [
			'provider_outcome_unknown',
			'provider_accepted_local_record_retained',
			'provider_accepted_remove_failed',
			'safety_state_failed'
		].includes(notification?.safety_state);
	},

	availableNotifications: function() {
		return this.validNotifications().filter(function(notification) {
			return !this.notificationReplayBlocked(notification);
		}, this);
	},

	protectedNotifications: function() {
		return this.validNotifications().filter(this.notificationReplayBlocked.bind(this));
	},

	updateProtectedWarning: function() {
		if (!this.protectedWarning)
			return;

		const count = this.protectedNotifications().length;

		this.protectedWarning.style.display = count ? '' : 'none';
		this.protectedWarning.textContent = count
			? N_(count,
				'One notification is protected from automatic resend because its provider outcome may already be final.',
				'%d notifications are protected from automatic resend because their provider outcomes may already be final.').format(count) + ' ' +
				_('Protected records are excluded from Process all; review them before using Remove all.')
			: '';
	},

	updateProcessControls: function() {
		const available = this.availableNotifications();

		if (this.processAllButton)
			this.processAllButton.disabled = !!(isReadonlyView || this.processing ||
				!available.length || this.processBlocked);

		if (this.removeAllButton)
			this.removeAllButton.disabled = !!(isReadonlyView || this.processing ||
				!this.validNotifications().length);

		this.updateProtectedWarning();
	},

	load: function() {
		this.processing = false;
		this.processBlocked = false;
		this.activeNotificationJob = null;
		this.activeNotificationToken = null;
		this.activeNotificationOrigin = null;
		this.activeNotificationPhase = null;
		this.processQueue = [];
		this.processIndex = 0;
		this.processCompleted = 0;
		this.processProgress = null;
		this.notificationStatusFailures = 0;
		return L.resolveDefault(lpac.listNotifications(), null);
	},

	processNotifications: function(notifications, removeAfterSuccess) {
		notifications = notifications.filter(function(notification) {
			return this.notificationSequence(notification) !== null &&
				!this.notificationReplayBlocked(notification);
		}, this);

		if (this.processing || this.processBlocked || !notifications.length)
			return;

		this.processing = true;
		this.processBlocked = false;
		this.processQueue = notifications.slice();
		this.processIndex = 0;
		this.processCompleted = 0;
		this.processRemoveAfterSuccess = !!removeAfterSuccess;
		this.activeNotificationJob = null;
		this.activeNotificationToken = null;
		this.activeNotificationOrigin = null;
		this.activeNotificationPhase = null;
		this.notificationStatusFailures = 0;
		const generation = ++this.processGeneration;
		this.processProgress = E('span', {}, [
			_('Processing notification 1 of %d…').format(notifications.length)
		]);
		this.updateProcessControls();

		ui.showModal(_('Processing notifications'), [
			E('p', { 'class': 'spinning' }, [ this.processProgress ]),
			E('p', { 'class': 'cbi-value-description', 'role': 'note' }, [
				_('Do not close this page or retry a notification whose provider outcome is reported as unknown.')
			])
		]);

		return this.startNextNotification(generation);
	},

	attachNotificationJob: function(result, origin) {
		const id = result?.data?.job_id;
		const token = result?.data?.owner_token;

		if (!result?.success || result.data?.status !== 'running' ||
		    !Number.isInteger(id) || id < 1)
			return false;

		let normalizedOrigin = origin;

		if (origin === 'owned' &&
		    (typeof token !== 'string' || !/^[A-Za-z0-9_-]{32}$/.test(token)))
			normalizedOrigin = 'uncertain';

		this.activeNotificationJob = id;
		this.activeNotificationToken = normalizedOrigin === 'owned' ? token : null;
		this.activeNotificationOrigin = normalizedOrigin;
		this.activeNotificationPhase = typeof result.data.phase === 'string'
			? result.data.phase : 'retrieving';
		this.notificationStatusFailures = 0;
		return true;
	},

	startNextNotification: function(generation) {
		if (!this.processing || generation !== this.processGeneration)
			return Promise.resolve();

		if (this.processIndex >= this.processQueue.length) {
			this.completeNotificationBatch();
			return Promise.resolve();
		}

		const notification = this.processQueue[this.processIndex];
		const seq = this.notificationSequence(notification);

		if (seq === null || this.notificationReplayBlocked(notification)) {
			this.stopNotificationBatch({
				success: false,
				error: 'retry_blocked'
			});
			return Promise.resolve();
		}

		if (this.processProgress)
			this.processProgress.textContent =
				_('Processing notification %d of %d…').format(
					this.processIndex + 1, this.processQueue.length);

		return lpac.processNotification(seq,
			this.processRemoveAfterSuccess).then(function(result) {
			if (!this.processing || generation !== this.processGeneration)
				return;

			if (this.attachNotificationJob(result, 'owned'))
				return;

			if (!result || result.error === 'transport_error' || result.success === true) {
				return lpac.getNotificationStatus(0, '').then(function(current) {
					if (!this.processing || generation !== this.processGeneration)
						return;

					if (this.attachNotificationJob(current, 'uncertain'))
						return;

					this.stopNotificationBatch(result?.success
						? { success: false, error: 'invalid_response' }
						: result);
				}.bind(this));
			}

			this.stopNotificationBatch(result);
		}.bind(this)).catch(function() {
			if (this.processing && generation === this.processGeneration)
				this.stopNotificationBatch({
					success: false,
					error: 'transport_error',
					reason: 'provider_outcome_unknown'
				});
		}.bind(this));
	},

	validNotificationTerminal: function(result) {
		return result?.success === true && result.data?.status === 'success' &&
			result.data?.phase === 'complete' &&
			[ 'clear', 'provider_outcome_unknown',
				'provider_accepted_local_record_retained',
				'provider_accepted_remove_failed' ].includes(result.data?.safety_state) &&
			typeof result.data?.replay_blocked === 'boolean' &&
			(result.data.safety_state === 'clear') !== result.data.replay_blocked;
	},

	markCurrentNotificationProtected: function(result) {
		const notification = this.processQueue[this.processIndex];
		const state = result?.data?.safety_state || result?.reason;
		const blocked = result?.data?.replay_blocked === true || [
			'provider_outcome_unknown',
			'provider_accepted_local_record_retained',
			'provider_accepted_remove_failed',
			'safety_state_failed'
		].includes(state);

		if (!notification || !blocked)
			return false;

		notification.replay_blocked = true;
		notification.safety_state = state || 'provider_outcome_unknown';
		return true;
	},

	completeNotificationBatch: function() {
		const completed = this.processCompleted;
		const removeAfterSuccess = this.processRemoveAfterSuccess;

		this.processing = false;
		this.processBlocked = false;
		this.activeNotificationJob = null;
		this.activeNotificationToken = null;
		this.activeNotificationOrigin = null;
		this.activeNotificationPhase = null;
		this.processQueue = [];
		this.processIndex = 0;
		this.processProgress = null;
		this.notificationStatusFailures = 0;
		ui.hideModal();
		ui.addNotification(null, E('p', {}, [
			N_(completed,
				'%d notification was processed successfully.',
				'%d notifications were processed successfully.').format(completed)
		]), 'info');
		this.updateProcessControls();

		if (removeAfterSuccess)
			window.location.reload();
	},

	stopNotificationBatch: function(result) {
		const completed = this.processCompleted;
		const total = this.processQueue.length;
		const protectedRecord = this.markCurrentNotificationProtected(result);
		const unknown = protectedRecord || [
			'transport_error', 'timeout', 'execution_failed', 'job_not_found',
			'not_authorized'
		].includes(result?.error);

		this.processing = false;
		this.processBlocked = completed > 0 || unknown;
		this.activeNotificationJob = null;
		this.activeNotificationToken = null;
		this.activeNotificationOrigin = null;
		this.activeNotificationPhase = null;
		this.processQueue = [];
		this.processIndex = 0;
		this.processProgress = null;
		this.notificationStatusFailures = 0;
		ui.hideModal();

		const partial = completed > 0
			? _('%d of %d notifications completed before processing stopped.').format(
				completed, total) + ' '
			: '';

		ui.addNotification(null, E('p', {}, [
			partial,
			lpac.errorMessage(result),
			' ',
			_('Processing stopped. Refresh Notifications and review the remaining records before using Process all again.')
		]), unknown || completed > 0 ? 'warning' : 'error');
		this.updateProcessControls();
	},

	pollNotification: function() {
		if (!this.processing || !this.activeNotificationJob)
			return Promise.resolve();

		const id = this.activeNotificationJob;
		const generation = this.processGeneration;
		const owned = this.activeNotificationOrigin === 'owned';
		const query = owned
			? lpac.getNotificationStatus(id, this.activeNotificationToken || '')
			: lpac.getNotificationStatus(0, '');

		return query.then(function(result) {
			if (!this.processing || generation !== this.processGeneration ||
			    this.activeNotificationJob !== id)
				return;

			if (result?.error === 'transport_error') {
				this.recordNotificationStatusFailure();
				return;
			}

			this.notificationStatusFailures = 0;

			if (result?.success && result.data?.status === 'running' &&
			    result.data?.job_id === id) {
				this.activeNotificationPhase = typeof result.data.phase === 'string'
					? result.data.phase : this.activeNotificationPhase;
				return;
			}

			if (!owned && result?.success && result.data?.status === 'idle') {
				this.stopNotificationBatch({
					success: false,
					error: 'retry_blocked',
					reason: 'provider_outcome_unknown'
				});
				return;
			}

			if (!owned) {
				this.stopNotificationBatch({
					success: false,
					error: 'invalid_response',
					reason: 'provider_outcome_unknown'
				});
				return;
			}

			if (!this.validNotificationTerminal(result)) {
				this.stopNotificationBatch(result?.success === false
					? result
					: { success: false, error: 'invalid_response',
						reason: 'provider_outcome_unknown' });
				return;
			}

			if (this.processRemoveAfterSuccess && result.data.replay_blocked) {
				this.stopNotificationBatch({
					success: false,
					error: 'invalid_response',
					reason: result.data.safety_state
				});
				return;
			}

			this.markCurrentNotificationProtected(result);
			this.processCompleted++;
			this.processIndex++;
			this.activeNotificationJob = null;
			this.activeNotificationToken = null;
			this.activeNotificationOrigin = null;
			this.activeNotificationPhase = null;
			return this.startNextNotification(generation);
		}.bind(this)).catch(function() {
			if (this.processing && generation === this.processGeneration &&
			    this.activeNotificationJob === id)
				this.recordNotificationStatusFailure();
		}.bind(this));
	},

	recordNotificationStatusFailure: function() {
		this.notificationStatusFailures++;

		if (this.notificationStatusFailures >= 3 && this.processProgress)
			this.processProgress.textContent =
				_('Connection to the lpac service was lost. Notification processing may still be running; status checks will continue automatically.');
	},

	showProcessAllModal: function() {
		const notifications = this.availableNotifications();

		if (this.processing || this.processBlocked || !notifications.length)
			return;

		const remove = E('input', {
			'id': 'lpac-notification-remove-after-process',
			'type': 'checkbox',
			'checked': ''
		});

		ui.showModal(_('Process all notifications'), [
			E('p', {}, [
				N_(notifications.length,
					'Send the pending notification to its provider? Processing stops at the first failure.',
					'Send all %d pending notifications to their providers in sequence? Processing stops at the first failure.').format(notifications.length)
			]),
			E('label', { 'class': 'cbi-value' }, [
				remove,
				' ',
				_('Remove each eUICC record after successful provider processing')
			]),
			E('p', { 'class': 'cbi-value-description', 'role': 'note' }, [
				_('If delivery has an unknown outcome, do not process that record again automatically. If delivery succeeded but removal failed, use Remove all.')
			]),
			E('div', { 'class': 'right' }, [
				E('button', { 'class': 'btn', 'type': 'button', 'click': ui.hideModal }, [ _('Cancel') ]),
				' ',
				E('button', {
					'class': 'btn cbi-button-positive important',
					'type': 'button',
					'click': ui.createHandlerFn(this, function() {
						return this.processNotifications(notifications, remove.checked);
					})
				}, [ _('Process all') ])
			])
		]);
	},

	showRemoveAllModal: function() {
		if (this.processing || !this.validNotifications().length)
			return;

		ui.showModal(_('Remove all notifications'), [
			E('p', {}, [
				_('Remove every pending notification record currently stored on the eUICC?')
			]),
			E('p', { 'class': 'alert-message warning' }, [
				_('This standalone operation does not contact any provider. Unprocessed records will be permanently discarded and provider state may remain out of sync.')
			]),
			E('div', { 'class': 'right' }, [
				E('button', { 'class': 'btn', 'type': 'button', 'click': ui.hideModal }, [ _('Cancel') ]),
				' ',
				E('button', {
					'class': 'btn cbi-button-negative important',
					'type': 'button',
					'click': ui.createHandlerFn(this, function() {
						this.processing = true;
						this.updateProcessControls();
						ui.showModal(_('Removing all notifications'), [
							E('p', { 'class': 'spinning' }, [ _('Waiting for lpac…') ])
						]);

						return lpac.removeAllNotifications().then(function(result) {
							if (!result || !result.success)
								throw new Error(lpac.errorMessage(result));

							ui.hideModal();
							window.location.reload();
						}).catch(function(error) {
							ui.hideModal();
							ui.addNotification(null, E('p', {}, [
								error.message,
								' ',
								_('Refresh Notifications before retrying because removal may have stopped after a partial local result.')
							]), 'error');
						}).finally(function() {
							this.processing = false;
							this.updateProcessControls();
						}.bind(this));
					})
				}, [ _('Remove all') ])
			])
		]);
	},

	render: function(result) {
		const notifications = lpac.dataOr(result, []);
		const processable = notifications.filter(function(notification) {
			return this.notificationSequence(notification) !== null;
		}, this);

		this.notifications = processable;
		this.processBlocked = false;
		this.processAllButton = null;
		this.removeAllButton = null;
		this.protectedWarning = null;
		const table = E('table', { 'class': 'table' }, [
			E('tr', { 'class': 'tr table-titles' }, [
				E('th', { 'class': 'th left' }, [ _('Sequence') ]),
				E('th', { 'class': 'th left' }, [ _('Operation') ]),
				E('th', { 'class': 'th left' }, [ _('ICCID') ]),
				E('th', { 'class': 'th left' }, [ _('Notification address') ])
			])
		]);
		const rows = [];

		if (result && result.success) {
			notifications.forEach(function(notification) {
				const seq = this.notificationSequence(notification);

				rows.push([
					seq ?? '-',
					operationLabel(notification.profileManagementOperation),
					notification.iccid || '-',
					notification.notificationAddress || '-'
				]);
			}, this);
		}

		cbi_update_table(table, rows, E('em', {}, [
			result && result.success
				? _('No pending notifications found.')
				: _('Notification data is unavailable.')
		]));

		const processAll = E('button', {
			'class': 'btn cbi-button cbi-button-positive',
			'type': 'button',
			'disabled': isReadonlyView || this.processing || !processable.length || null,
			'click': ui.createHandlerFn(this, 'showProcessAllModal')
		}, [ _('Process all') ]);
		const removeAll = E('button', {
			'class': 'btn cbi-button cbi-button-negative',
			'type': 'button',
			'disabled': isReadonlyView || this.processing || !processable.length || null,
			'click': ui.createHandlerFn(this, 'showRemoveAllModal')
		}, [ _('Remove all') ]);

		this.processAllButton = processAll;
		this.removeAllButton = removeAll;
		this.protectedWarning = E('div', {
			'id': 'lpac-notification-protected-warning',
			'class': 'alert-message warning',
			'role': 'alert',
			'style': this.protectedNotifications().length ? '' : 'display:none'
		});

		if (!this.pollRegistered) {
			poll.add(this.pollNotification.bind(this), 2);
			this.pollRegistered = true;
		}

		this.updateProcessControls();

		return E([
			E('h2', {}, [ _('eUICC notifications') ]),
			E('div', { 'class': 'cbi-map-descr' }, [
				_('Profile operations can create notifications that should normally be sent to the provider.')
			]),
			(!result || !result.success)
				? E('div', { 'class': 'alert-message warning' }, [ lpac.errorMessage(result) ])
				: E([]),
			this.protectedWarning,
			table,
			E('div', { 'class': 'cbi-page-actions' }, [
				processAll,
				' ',
				removeAll,
				' ',
				E('button', {
					'class': 'btn cbi-button cbi-button-action',
					'type': 'button',
					'click': ui.createHandlerFn(this, function() {
						window.location.reload();
					})
				}, [ _('Refresh') ])
			])
		]);
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
