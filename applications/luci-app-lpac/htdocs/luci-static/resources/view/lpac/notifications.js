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
	processBlocked: {},
	removedSequences: {},
	selectedSequences: {},
	selectionInputs: {},
	selectAllInput: null,
	notifications: [],
	processButtons: {},
	removeButtons: [],
	processAllButton: null,
	processSelectedButton: null,
	removeSelectedButton: null,
	removeAllButton: null,

	notificationSequence: function(notification) {
		const seq = notification?.seqNumber;

		return Number.isInteger(seq) && seq >= 0 && seq <= 4294967295
			? String(seq)
			: null;
	},

	updateProcessControls: function() {
		for (const seq in this.processButtons)
			this.processButtons[seq].disabled = !!(isReadonlyView || this.processing ||
				this.processBlocked[seq] || this.removedSequences[seq]);

		this.removeButtons.forEach(function(button) {
			button.disabled = !!(isReadonlyView || this.processing ||
				this.removedSequences[button.sequence]);
		}, this);

		for (const seq in this.selectionInputs)
			this.selectionInputs[seq].disabled = !!(isReadonlyView || this.processing ||
				this.removedSequences[seq]);

		if (this.selectAllInput)
			this.selectAllInput.disabled = !!(isReadonlyView || this.processing ||
				!this.availableNotifications().length);

		const selected = this.selectedNotifications();
		if (this.selectAllInput) {
			const availableCount = this.availableNotifications().length;

			this.selectAllInput.checked = availableCount > 0 &&
				selected.length === availableCount;
			this.selectAllInput.indeterminate = selected.length > 0 &&
				selected.length < availableCount;
		}
		const processSelectedBlocked = selected.some(function(notification) {
			const seq = this.notificationSequence(notification);

			return seq === null || this.processBlocked[seq];
		}, this);

		if (this.processSelectedButton)
			this.processSelectedButton.disabled = !!(isReadonlyView || this.processing ||
				!selected.length || processSelectedBlocked);

		if (this.removeSelectedButton)
			this.removeSelectedButton.disabled = !!(isReadonlyView || this.processing ||
				!selected.length);

		if (this.processAllButton)
			this.processAllButton.disabled = !!(isReadonlyView || this.processing ||
				!this.availableNotifications().length ||
				Object.keys(this.processBlocked).length);

		if (this.removeAllButton)
			this.removeAllButton.disabled = !!(isReadonlyView || this.processing ||
				!this.availableNotifications().length);
	},

	availableNotifications: function() {
		return this.notifications.filter(function(notification) {
			const seq = this.notificationSequence(notification);

			return seq !== null && !this.removedSequences[seq];
		}, this);
	},

	selectedNotifications: function() {
		return this.availableNotifications().filter(function(notification) {
			return this.selectedSequences[this.notificationSequence(notification)] === true;
		}, this);
	},

	setAllSelected: function(selected) {
		this.availableNotifications().forEach(function(notification) {
			const seq = this.notificationSequence(notification);

			this.selectedSequences[seq] = !!selected;
			if (this.selectionInputs[seq])
				this.selectionInputs[seq].checked = !!selected;
		}, this);

		this.updateProcessControls();
	},

	load: function() {
		return L.resolveDefault(lpac.listNotifications(), null);
	},

	processNotifications: function(notifications, removeAfterSuccess) {
		notifications = notifications.filter(function(notification) {
			const seq = this.notificationSequence(notification);

			return seq !== null && !this.removedSequences[seq];
		}, this);

		if (this.processing || !notifications.length)
			return;

		this.processing = true;
		this.updateProcessControls();
		let completed = 0;
		const progress = E('span', {}, [
			_('Processing notification 1 of %d…').format(notifications.length)
		]);

		ui.showModal(notifications.length === 1
			? _('Processing notification')
			: _('Processing notifications'), [
			E('p', { 'class': 'spinning' }, [ progress ]),
			E('p', { 'class': 'cbi-value-description', 'role': 'note' }, [
				_('Do not close this page or retry a notification whose provider outcome is reported as unknown.')
			])
		]);

		let operation = Promise.resolve();

		notifications.forEach(function(notification, index) {
			operation = operation.then(function() {
				const seq = this.notificationSequence(notification);

				if (seq === null)
					throw new Error(lpac.errorMessage({ error: 'invalid_response' }));

				progress.textContent = _('Processing notification %d of %d…').format(
					index + 1, notifications.length);

				return lpac.processNotification(seq,
					removeAfterSuccess).then(function(result) {
					if (!result || !result.success) {
						const error = new Error(lpac.errorMessage(result));

						error.result = result;
						error.sequence = seq;
						throw error;
					}

					completed++;
					this.processBlocked[seq] = true;
					this.selectedSequences[seq] = false;
					if (this.selectionInputs[seq])
						this.selectionInputs[seq].checked = false;
					if (removeAfterSuccess)
						this.removedSequences[seq] = true;
				}.bind(this));
			}.bind(this));
		}, this);

		return operation.then(function() {
			ui.hideModal();
			ui.addNotification(null, E('p', {}, [
				completed === 1
					? _('The notification was processed successfully.')
					: _('%d notifications were processed successfully.').format(completed)
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
			const noRetry = unknown || removeFailed;

			if (noRetry && error.sequence !== undefined)
				this.processBlocked[error.sequence] = true;

			ui.addNotification(null, E('p', {}, [
				partial, error.message, ' ', unknown
					? _('The provider outcome may be unknown; do not process this record again automatically. ')
					: removeFailed
						? _('The provider has processed this record; use Remove instead of processing it again. ')
						: '',
				_('Processing stopped. Refresh Notifications and review the remaining records before using Process all again.')
			]),
				noRetry ? 'warning' : 'error');
		}.bind(this)).finally(function() {
			this.processing = false;
			this.updateProcessControls();
		}.bind(this));
	},

	showProcessModal: function(notifications, scope) {
		notifications = notifications.filter(function(notification) {
			const seq = this.notificationSequence(notification);

			return seq !== null && !this.removedSequences[seq] &&
				!this.processBlocked[seq];
		}, this);

		if (this.processing || !notifications.length)
			return;

		const remove = E('input', {
			'id': 'lpac-notification-remove-after-process',
			'type': 'checkbox',
			'checked': ''
		});
		const multiple = notifications.length > 1;

		ui.showModal(multiple ? _('Process notifications') : _('Process notification'), [
			E('p', {}, [ multiple
				? _('Send %d pending notifications to their providers in sequence? Processing stops at the first failure.').format(notifications.length)
				: _('Send notification sequence %s to its provider?').format(
					notifications[0].seqNumber)
			]),
			E('label', { 'class': 'cbi-value' }, [
				remove,
				' ',
				_('Remove each eUICC record after successful provider processing')
			]),
			E('p', { 'class': 'cbi-value-description', 'role': 'note' }, [
				_('If delivery has an unknown outcome, do not process that record again automatically. If delivery succeeded but removal failed, use the separate Remove action.')
			]),
			E('div', { 'class': 'right' }, [
				E('button', {
					'class': 'btn',
					'click': ui.hideModal
				}, [ _('Cancel') ]),
				' ',
				E('button', {
					'class': 'btn cbi-button-positive important',
					'click': ui.createHandlerFn(this, function() {
						return this.processNotifications(notifications, remove.checked);
					})
				}, [ multiple
					? (scope === 'all' ? _('Process all') : _('Process selected'))
					: _('Process') ])
			])
		]);
	},

	removeNotifications: function(notifications) {
		notifications = notifications.filter(function(notification) {
			const seq = this.notificationSequence(notification);

			return seq !== null && !this.removedSequences[seq];
		}, this);

		if (this.processing || !notifications.length)
			return;

		this.processing = true;
		this.updateProcessControls();
		let completed = 0;
		const progress = E('span', {}, [
			_('Removing notification 1 of %d…').format(notifications.length)
		]);

		ui.showModal(notifications.length === 1
			? _('Removing notification')
			: _('Removing notifications'), [
			E('p', { 'class': 'spinning' }, [ progress ])
		]);

		let operation = Promise.resolve();

		notifications.forEach(function(notification, index) {
			operation = operation.then(function() {
				const seq = this.notificationSequence(notification);

				progress.textContent = _('Removing notification %d of %d…').format(
					index + 1, notifications.length);

				return lpac.removeNotification(seq).then(function(result) {
					if (!result || !result.success)
						throw new Error(lpac.errorMessage(result));

					completed++;
					this.removedSequences[seq] = true;
					this.selectedSequences[seq] = false;
					if (this.selectionInputs[seq])
						this.selectionInputs[seq].checked = false;
				}.bind(this));
			}.bind(this));
		}, this);

		return operation.then(function() {
			ui.hideModal();
			window.location.reload();
		}).catch(function(error) {
			ui.hideModal();
			ui.addNotification(null, E('p', {}, [
				completed
					? _('%d of %d notifications were removed before removal stopped. ').format(
						completed, notifications.length)
					: '',
				error.message,
				' ',
				_('Refresh Notifications before retrying because the local result may be partial.')
			]), 'error');
		}.bind(this)).finally(function() {
			this.processing = false;
			this.updateProcessControls();
		}.bind(this));
	},

	showRemoveModal: function(notifications) {
		if (!Array.isArray(notifications))
			notifications = [ notifications ];

		notifications = notifications.filter(function(notification) {
			const seq = this.notificationSequence(notification);

			return seq !== null && !this.removedSequences[seq];
		}, this);

		if (this.processing || !notifications.length)
			return;

		const multiple = notifications.length > 1;
		const sequences = notifications.map(function(notification) {
			return this.notificationSequence(notification);
		}, this);

		ui.showModal(multiple ? _('Remove selected notifications') : _('Remove notification'), [
			E('p', {}, [ multiple
				? _('Remove %d selected notification records from the eUICC in sequence?').format(notifications.length)
				: _('Remove notification sequence %s from the eUICC?').format(sequences[0])
			]),
			E('p', { 'class': 'alert-message warning' }, [
				_('Removing an unprocessed notification permanently discards its eUICC record without contacting the provider. It does not undo the profile operation and may leave the provider state out of sync. Only continue if the notification was processed elsewhere or is no longer needed.')
			]),
			E('div', { 'class': 'right' }, [
				E('button', {
					'class': 'btn',
					'click': ui.hideModal
				}, [ _('Cancel') ]),
				' ',
				E('button', {
					'class': 'btn cbi-button-negative important',
					'click': ui.createHandlerFn(this, 'removeNotifications', notifications)
				}, [ multiple ? _('Remove selected') : _('Remove') ])
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
		this.selectedSequences = {};
		this.selectionInputs = {};
		this.selectAllInput = E('input', {
			'type': 'checkbox',
			'title': _('Select all notifications'),
			'aria-label': _('Select all notifications'),
			'disabled': isReadonlyView || this.processing || !processable.length || null,
			'change': function(event) {
				this.setAllSelected(!!event.currentTarget.checked);
			}.bind(this)
		});
		this.processButtons = {};
		this.removeButtons = [];
		this.processAllButton = null;
		this.processSelectedButton = null;
		this.removeSelectedButton = null;
		this.removeAllButton = null;
		const table = E('table', { 'class': 'table' }, [
			E('tr', { 'class': 'tr table-titles' }, [
				E('th', { 'class': 'th left' }, [ this.selectAllInput ]),
				E('th', { 'class': 'th left' }, [ _('Sequence') ]),
				E('th', { 'class': 'th left' }, [ _('Operation') ]),
				E('th', { 'class': 'th left' }, [ _('ICCID') ]),
				E('th', { 'class': 'th left' }, [ _('Notification address') ]),
				E('th', { 'class': 'th right' }, [ _('Actions') ])
			])
		]);
		const rows = [];

		if (result && result.success) {
			notifications.forEach(function(notification) {
				const seq = this.notificationSequence(notification);
				const selectInput = E('input', {
					'type': 'checkbox',
					'title': seq === null
						? _('Invalid notification sequence')
						: _('Select notification %s').format(seq),
					'aria-label': seq === null
						? _('Invalid notification sequence')
						: _('Select notification %s').format(seq),
					'disabled': isReadonlyView || this.processing || seq === null || null,
					'change': function(event) {
						if (seq !== null) {
							this.selectedSequences[seq] = !!event.currentTarget.checked;
							this.updateProcessControls();
						}
					}.bind(this)
				});
				const processButton = E('button', {
					'class': 'btn cbi-button-action',
					'disabled': isReadonlyView || this.processing || seq === null ||
						this.processBlocked[seq] || null,
					'click': ui.createHandlerFn(this, 'showProcessModal',
						[ notification ])
				}, [ _('Process') ]);
				const removeButton = E('button', {
					'class': 'btn cbi-button-negative',
					'disabled': isReadonlyView || this.processing || seq === null || null,
					'click': ui.createHandlerFn(this, 'showRemoveModal', notification)
				}, [ _('Remove') ]);

				if (seq !== null) {
					this.selectionInputs[seq] = selectInput;
					this.processButtons[seq] = processButton;
					removeButton.sequence = seq;
					this.removeButtons.push(removeButton);
				}

				rows.push([
					selectInput,
					seq ?? '-',
					operationLabel(notification.profileManagementOperation),
					notification.iccid || '-',
					notification.notificationAddress || '-',
					E('div', { 'class': 'nowrap' }, [
						processButton,
						' ',
						removeButton
					])
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
			'disabled': isReadonlyView || this.processing ||
				!processable.length || Object.keys(this.processBlocked).length || null,
			'click': ui.createHandlerFn(this, 'showProcessModal', processable, 'all')
		}, [ _('Process all') ]);
		const processSelected = E('button', {
			'class': 'btn cbi-button cbi-button-positive',
			'disabled': true,
			'click': ui.createHandlerFn(this, function() {
				return this.showProcessModal(this.selectedNotifications(), 'selected');
			})
		}, [ _('Process selected') ]);
		const removeSelected = E('button', {
			'class': 'btn cbi-button cbi-button-negative',
			'disabled': true,
			'click': ui.createHandlerFn(this, function() {
				return this.showRemoveModal(this.selectedNotifications());
			})
		}, [ _('Remove selected') ]);
		const removeAll = E('button', {
			'class': 'btn cbi-button cbi-button-negative',
			'disabled': isReadonlyView || this.processing || !processable.length || null,
			'click': ui.createHandlerFn(this, 'showRemoveAllModal')
		}, [ _('Remove all') ]);

		processAll.notificationCount = processable.length;
		this.processAllButton = processAll;
		this.processSelectedButton = processSelected;
		this.removeSelectedButton = removeSelected;
		this.removeAllButton = removeAll;
		this.updateProcessControls();

		return E([
			E('h2', {}, [ _('eUICC notifications') ]),
			E('div', { 'class': 'cbi-map-descr' }, [
				_('Profile operations can create notifications that should normally be sent to the provider.')
			]),
			E('div', { 'class': 'alert-message warning', 'role': 'note' }, [
				_('Security warning: the bundled lpac does not verify the provider TLS certificate or hostname. Process uses that inherited transport. Remove only discards the local eUICC record and must not be used before provider processing unless you deliberately accept that loss.')
			]),
			(!result || !result.success)
				? E('div', { 'class': 'alert-message warning' }, [ lpac.errorMessage(result) ])
				: E([]),
			table,
			E('div', { 'class': 'cbi-page-actions' }, [
				processSelected,
				' ',
				processAll,
				' ',
				removeSelected,
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
