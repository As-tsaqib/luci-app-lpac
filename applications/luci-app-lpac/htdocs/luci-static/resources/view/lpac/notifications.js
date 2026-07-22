// SPDX-License-Identifier: Apache-2.0
/* global lpac */

'use strict';
'require view';
'require ui';
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

	notificationSequence: function(notification) {
		const seq = notification?.seqNumber;

		return Number.isInteger(seq) && seq >= 0 && seq <= 4294967295
			? String(seq)
			: null;
	},

	availableNotifications: function() {
		return this.notifications.filter(function(notification) {
			return this.notificationSequence(notification) !== null;
		}, this);
	},

	updateProcessControls: function() {
		const available = this.availableNotifications();

		if (this.processAllButton)
			this.processAllButton.disabled = !!(isReadonlyView || this.processing ||
				!available.length || this.processBlocked);

		if (this.removeAllButton)
			this.removeAllButton.disabled = !!(isReadonlyView || this.processing ||
				!available.length);
	},

	load: function() {
		return L.resolveDefault(lpac.listNotifications(), null);
	},

	processNotifications: function(notifications, removeAfterSuccess) {
		notifications = notifications.filter(function(notification) {
			return this.notificationSequence(notification) !== null;
		}, this);

		if (this.processing || this.processBlocked || !notifications.length)
			return;

		this.processing = true;
		this.updateProcessControls();
		let completed = 0;
		const progress = E('span', {}, [
			_('Processing notification 1 of %d…').format(notifications.length)
		]);

		ui.showModal(_('Processing notifications'), [
			E('p', { 'class': 'spinning' }, [ progress ]),
			E('p', { 'class': 'cbi-value-description', 'role': 'note' }, [
				_('Do not close this page or retry a notification whose provider outcome is reported as unknown.')
			])
		]);

		let operation = Promise.resolve();

		notifications.forEach(function(notification, index) {
			operation = operation.then(function() {
				const seq = this.notificationSequence(notification);

				progress.textContent = _('Processing notification %d of %d…').format(
					index + 1, notifications.length);

				return lpac.processNotification(seq,
					removeAfterSuccess).then(function(result) {
					if (!result || !result.success) {
						const error = new Error(lpac.errorMessage(result));

						error.result = result;
						throw error;
					}

					completed++;
				}.bind(this));
			}.bind(this));
		}, this);

		return operation.then(function() {
			this.processBlocked = true;
			ui.hideModal();
			ui.addNotification(null, E('p', {}, [
				_('%d notifications were processed successfully.').format(completed)
			]), 'info');

			if (removeAfterSuccess)
				window.location.reload();
		}).catch(function(error) {
			ui.hideModal();
			const partial = completed > 0
				? _('%d of %d notifications completed before processing stopped. ').format(
					completed, notifications.length)
				: '';
			const removeFailed =
				error.result?.reason === 'provider_processed_remove_failed';
			const unknown = error.result?.reason === 'provider_outcome_unknown' ||
				[ 'transport_error', 'timeout', 'execution_failed' ]
					.includes(error.result?.error);

			if (completed > 0 || unknown || removeFailed)
				this.processBlocked = true;

			ui.addNotification(null, E('p', {}, [
				partial, error.message, ' ', unknown
					? _('The provider outcome may be unknown; do not process this record again automatically. ')
					: removeFailed
						? _('The provider has processed this record; use Remove all instead of processing the list again. ')
						: '',
				_('Processing stopped. Refresh Notifications and review the remaining records before using Process all again.')
			]), unknown || removeFailed || completed > 0 ? 'warning' : 'error');
		}.bind(this)).finally(function() {
			this.processing = false;
			this.updateProcessControls();
		}.bind(this));
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
				_('Send all %d pending notifications to their providers in sequence? Processing stops at the first failure.').format(notifications.length)
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
				E('button', { 'class': 'btn', 'click': ui.hideModal }, [ _('Cancel') ]),
				' ',
				E('button', {
					'class': 'btn cbi-button-positive important',
					'click': ui.createHandlerFn(this, function() {
						return this.processNotifications(notifications, remove.checked);
					})
				}, [ _('Process all') ])
			])
		]);
	},

	showRemoveAllModal: function() {
		if (this.processing || !this.availableNotifications().length)
			return;

		ui.showModal(_('Remove all notifications'), [
			E('p', {}, [
				_('Remove every pending notification record currently stored on the eUICC?')
			]),
			E('p', { 'class': 'alert-message warning' }, [
				_('This standalone operation does not contact any provider. Unprocessed records will be permanently discarded and provider state may remain out of sync.')
			]),
			E('div', { 'class': 'right' }, [
				E('button', { 'class': 'btn', 'click': ui.hideModal }, [ _('Cancel') ]),
				' ',
				E('button', {
					'class': 'btn cbi-button-negative important',
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
			'disabled': isReadonlyView || this.processing || !processable.length || null,
			'click': ui.createHandlerFn(this, 'showProcessAllModal')
		}, [ _('Process all') ]);
		const removeAll = E('button', {
			'class': 'btn cbi-button cbi-button-negative',
			'disabled': isReadonlyView || this.processing || !processable.length || null,
			'click': ui.createHandlerFn(this, 'showRemoveAllModal')
		}, [ _('Remove all') ]);

		this.processAllButton = processAll;
		this.removeAllButton = removeAll;
		this.updateProcessControls();

		return E([
			E('h2', {}, [ _('eUICC notifications') ]),
			E('div', { 'class': 'cbi-map-descr' }, [
				_('Profile operations can create notifications that should normally be sent to the provider.')
			]),
			(!result || !result.success)
				? E('div', { 'class': 'alert-message warning' }, [ lpac.errorMessage(result) ])
				: E([]),
			table,
			E('div', { 'class': 'cbi-page-actions' }, [
				processAll,
				' ',
				removeAll,
				' ',
				E('button', {
					'class': 'btn cbi-button cbi-button-action',
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
