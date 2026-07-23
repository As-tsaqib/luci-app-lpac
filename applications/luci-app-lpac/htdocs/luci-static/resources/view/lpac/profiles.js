// SPDX-License-Identifier: Apache-2.0
/* global lpac */

'use strict';
'require view';
'require ui';
'require lpac';

const isReadonlyView = !L.hasViewPermission() || null;

function profileLabel(profile) {
	return profile.profileNickname || profile.profileName ||
		profile.serviceProviderName || profile.iccid || profile.isdpAid || _('Unknown profile');
}

function profileStateLabel(state) {
	switch (state) {
	case 'enabled':
		return _('Enabled');
	case 'disabled':
		return _('Disabled');
	default:
		return _('Unknown');
	}
}

function profileStateIndicator(state) {
	const className = state === 'enabled'
		? 'label success'
		: state === 'disabled' ? 'label' : 'label warning';

	return E('span', { 'class': className }, [ profileStateLabel(state) ]);
}

function profileField(label, value) {
	return E('span', { 'class': 'lpac-profile-field' }, [
		E('strong', { 'class': 'lpac-profile-key' }, [ label, ':' ]),
		E('span', { 'class': 'lpac-profile-value' }, [ value ])
	]);
}

function profileIconFallback() {
	return E('span', {
		'class': 'lpac-profile-icon lpac-profile-icon-fallback',
		'aria-hidden': 'true'
	}, []);
}

function profileIcon(profile) {
	const uri = lpac.profileIconUri(profile.iconType, profile.icon);

	if (!uri)
		return profileIconFallback();

	return E('img', {
		'class': 'lpac-profile-icon',
		'src': uri,
		'alt': '',
		'aria-hidden': 'true',
		'error': function() {
			this.replaceWith(profileIconFallback());
		}
	});
}

function validRefreshPreference(result) {
	return result?.success === true && result.data &&
		typeof result.data.asked === 'boolean' &&
		typeof result.data.refresh === 'boolean';
}

return view.extend({
	refreshPreferenceValid: false,
	refreshPreferenceAsked: false,
	refreshPreference: false,
	refreshPreferenceResult: null,
	refreshPreferencePrompted: false,
	refreshPreferenceSaving: false,

	load: function() {
		this.refreshPreferenceValid = false;
		this.refreshPreferenceAsked = false;
		this.refreshPreference = false;
		this.refreshPreferenceResult = null;
		this.refreshPreferencePrompted = false;
		this.refreshPreferenceSaving = false;

		return Promise.all([
			L.resolveDefault(lpac.listProfiles(), null),
			L.resolveDefault(lpac.getProfileRefreshPreference(), null)
		]).then(function(results) {
			const preferenceResult = results[1];

			this.refreshPreferenceResult = preferenceResult;
			this.refreshPreferenceValid = validRefreshPreference(preferenceResult);

			if (this.refreshPreferenceValid) {
				this.refreshPreferenceAsked = preferenceResult.data.asked;
				this.refreshPreference = preferenceResult.data.asked &&
					preferenceResult.data.refresh;
			}

			return results[0];
		}.bind(this));
	},

	runOperation: function(title, operation) {
		ui.showModal(title, [
			E('p', { 'class': 'spinning' }, [ _('Waiting for lpac…') ])
		]);

		return operation.then(function(result) {
			if (!result || !result.success)
				throw new Error(lpac.errorMessage(result));

			ui.hideModal();
			window.location.reload();
		}).catch(function(error) {
			ui.hideModal();
			ui.addNotification(null, E('p', {}, [ error.message ]), 'error');
		});
	},

	preferenceError: function(result) {
		result = result?.success
			? { success: false, error: 'invalid_response' }
			: result;

		ui.addNotification(null, E('p', {}, [ lpac.errorMessage(result) ]), 'error');
	},

	showRefreshPreferencePrompt: function(profile, enable) {
		if (isReadonlyView || this.refreshPreferenceSaving)
			return;

		ui.showModal(_('Request eUICC refresh by default?'), [
			E('p', { 'class': 'cbi-value-description' }, [
				_('Requests a logical UICC refresh after the profile change; it does not reboot the modem. Some eUICCs require this flag, while others reject it.')
			]),
			E('div', { 'class': 'right' }, [
				E('button', {
					'class': 'btn',
					'type': 'button',
					'click': ui.createHandlerFn(this,
						'setRefreshPreferenceAndOpen', profile, enable, false)
				}, [ _('No') ]),
				' ',
				E('button', {
					'class': 'btn cbi-button-positive important',
					'type': 'button',
					'click': ui.createHandlerFn(this,
						'setRefreshPreferenceAndOpen', profile, enable, true)
				}, [ _('Yes') ])
			])
		]);
	},

	setRefreshPreferenceAndOpen: function(profile, enable, refresh) {
		if (isReadonlyView || this.refreshPreferenceSaving || typeof refresh !== 'boolean')
			return;

		this.refreshPreferenceSaving = true;

		return lpac.setProfileRefreshPreference(refresh).then(function(result) {
			this.refreshPreferenceResult = result;

			if (!validRefreshPreference(result) || result.data.asked !== true ||
			    result.data.refresh !== refresh) {
				this.preferenceError(result);
				this.showStateModal(profile, enable, false);
				return;
			}

			this.refreshPreferenceValid = true;
			this.refreshPreferenceAsked = true;
			this.refreshPreference = refresh;
			this.showStateModal(profile, enable, refresh);
		}.bind(this)).catch(function() {
			this.preferenceError({ success: false, error: 'transport_error' });
			this.showStateModal(profile, enable, false);
		}.bind(this)).finally(function() {
			this.refreshPreferenceSaving = false;
		}.bind(this));
	},

	handleStateAction: function(profile, enable) {
		if (isReadonlyView || this.refreshPreferenceSaving)
			return;

		if (!this.refreshPreferenceValid) {
			if (this.refreshPreferencePrompted)
				this.showStateModal(profile, enable, false);
			else {
				this.refreshPreferencePrompted = true;
				this.showRefreshPreferencePrompt(profile, enable);
			}

			return;
		}

		if (this.refreshPreferenceAsked || this.refreshPreferencePrompted) {
			this.showStateModal(profile, enable,
				this.refreshPreferenceAsked ? this.refreshPreference : false);
			return;
		}

		this.refreshPreferencePrompted = true;
		this.showRefreshPreferencePrompt(profile, enable);
	},

	showStateModal: function(profile, enable, refreshDefault) {
		if (isReadonlyView)
			return;

		const label = profileLabel(profile);
		const identifiers = [];

		if (profile.iccid)
			identifiers.push({ value: profile.iccid, label: _('ICCID') });

		if (profile.isdpAid)
			identifiers.push({ value: profile.isdpAid, label: _('ISD-P AID') });

		const identifier = E('select', {
			'id': 'lpac-profile-identifier',
			'class': 'cbi-input-select'
		}, identifiers.map(function(item, index) {
			return E('option', {
				'value': item.value,
				'selected': index === 0 ? '' : null
			}, [ item.label ]);
		}));
		const refresh = E('input', {
			'id': 'lpac-profile-refresh',
			'type': 'checkbox',
			'checked': refreshDefault === true ? '' : null
		});

		ui.showModal(enable ? _('Enable profile') : _('Disable profile'), [
			E('p', {}, [
				enable
					? _('Enable profile “%s”?').format(label)
					: _('Disable profile “%s”?').format(label)
			]),
			E('div', { 'class': 'cbi-value' }, [
				E('label', {
					'class': 'cbi-value-title',
					'for': 'lpac-profile-identifier'
				}, [ _('Profile identifier') ]),
				E('div', { 'class': 'cbi-value-field' }, [
					identifier,
					E('div', { 'class': 'cbi-value-description' }, [
						_('Try the ISD-P AID if this eUICC rejects an operation by ICCID.')
					])
				])
			]),
			E('label', { 'class': 'cbi-value' }, [
				refresh,
				' ',
				_('Request an eUICC refresh')
			]),
			E('p', {
				'class': 'cbi-value-description',
				'role': 'note'
			}, [
				_('Changing the active profile can interrupt mobile connectivity. Some modems require a separate SIM power cycle or reconnect afterwards.')
			]),
			E('div', { 'class': 'right' }, [
				E('button', {
					'class': 'btn',
					'type': 'button',
					'click': ui.hideModal
				}, [ _('Cancel') ]),
				' ',
				E('button', {
					'class': 'btn cbi-button-action important',
					'type': 'button',
					'click': ui.createHandlerFn(this, function() {
						const id = identifier.value;
						const operation = enable
							? lpac.enableProfile(id, refresh.checked)
							: lpac.disableProfile(id, refresh.checked);

						return this.runOperation(
							enable ? _('Enabling profile') : _('Disabling profile'),
							operation
						);
					})
				}, [ enable ? _('Enable') : _('Disable') ])
			])
		]);
	},

	showNicknameModal: function(profile) {
		const iccid = profile.iccid;
		const input = E('input', {
			'id': 'lpac-profile-nickname',
			'class': 'cbi-input-text',
			'type': 'text',
			'maxlength': 64,
			'value': profile.profileNickname || '',
			'placeholder': _('Leave empty to clear the nickname')
		});

		ui.showModal(_('Set profile nickname'), [
			E('div', { 'class': 'cbi-value' }, [
				E('label', {
					'class': 'cbi-value-title',
					'for': 'lpac-profile-nickname'
				}, [ _('Nickname') ]),
				E('div', { 'class': 'cbi-value-field' }, [ input ])
			]),
			E('div', { 'class': 'right' }, [
				E('button', {
					'class': 'btn',
					'type': 'button',
					'click': ui.hideModal
				}, [ _('Cancel') ]),
				' ',
				E('button', {
					'class': 'btn cbi-button-positive important',
					'type': 'button',
					'click': ui.createHandlerFn(this, function() {
						return this.runOperation(
							_('Updating nickname'),
							lpac.nicknameProfile(iccid, input.value)
						);
					})
				}, [ _('Save') ])
			])
		]);

		input.focus();
	},

	showDeleteModal: function(profile) {
		const id = profile.iccid || profile.isdpAid;

		ui.showModal(_('Delete profile'), [
			E('p', {}, [
				_('Permanently delete profile “%s”? This action cannot be undone.').format(profileLabel(profile))
			]),
			E('p', { 'class': 'alert-message warning' }, [
				_('lpac creates a provider notification after deletion. Open Notifications afterwards and process that record before removing it locally.')
			]),
			E('div', { 'class': 'right' }, [
				E('button', {
					'class': 'btn',
					'type': 'button',
					'click': ui.hideModal
				}, [ _('Cancel') ]),
				' ',
				E('button', {
					'class': 'btn cbi-button-negative important',
					'type': 'button',
					'click': ui.createHandlerFn(this, function() {
						return this.runOperation(_('Deleting profile'), lpac.deleteProfile(id));
					})
				}, [ _('Delete') ])
			])
		]);
	},

	render: function(result) {
		const profiles = lpac.dataOr(result, []);
		const table = E('table', {
			'id': 'lpac-profile-table',
			'class': 'table lpac-profile-table'
		}, [
			E('tr', { 'class': 'tr table-titles' }, [
				E('th', { 'class': 'th left' }, [ _('Profile') ]),
				E('th', { 'class': 'th left' }, [ _('Provider') ]),
				E('th', { 'class': 'th left' }, [ _('ICCID') ]),
				E('th', { 'class': 'th left' }, [ _('State') ]),
				E('th', { 'class': 'th right cbi-section-actions' }, [ _('Actions') ])
			])
		]);
		const rows = [];

		if (result && result.success) {
			profiles.forEach(function(profile) {
				const name = profileLabel(profile);
				const provider = profile.serviceProviderName || '-';
				const iccid = profile.iccid || '-';
				const state = String(profile.profileState || '').toLowerCase();
				const enabled = state === 'enabled';
				const disabled = state === 'disabled';
				const id = profile.iccid || profile.isdpAid;
				const summary = E('span', { 'class': 'lpac-profile-summary' }, [
					profileIcon(profile),
					profileField(_('Profile'), name)
				]);
				const actions = E('div', { 'class': 'lpac-profile-actions' }, [
					E('button', {
						'class': 'btn cbi-button-action',
						'type': 'button',
						'disabled': isReadonlyView || !id ||
							(!enabled && !disabled) || null,
						'title': (!enabled && !disabled)
							? _('The profile state does not allow this action') : '',
						'click': ui.createHandlerFn(this, 'handleStateAction', profile, !enabled)
					}, [ enabled ? _('Disable') : disabled ? _('Enable') : _('Unavailable') ]),
					E('button', {
						'class': 'btn cbi-button-edit',
						'type': 'button',
						'disabled': isReadonlyView || !profile.iccid || null,
						'title': !profile.iccid
							? _('An ICCID is required to rename this profile') : '',
						'click': ui.createHandlerFn(this, 'showNicknameModal', profile)
					}, [ _('Rename') ]),
					E('button', {
						'class': 'btn cbi-button-negative',
						'type': 'button',
						'disabled': isReadonlyView || !disabled || !id || null,
						'title': !disabled
							? _('Only a disabled profile can be deleted') : '',
						'click': ui.createHandlerFn(this, 'showDeleteModal', profile)
					}, [ _('Delete') ])
				]);

				rows.push([
					[ name, summary ],
					[ provider, profileField(_('Provider'), provider) ],
					[ iccid, profileField(_('ICCID'), iccid) ],
					[ state, profileField(_('State'), profileStateIndicator(state)) ],
					actions
				]);
			}, this);
		}

		cbi_update_table(table, rows, E('em', {}, [
			result && result.success
				? _('No eSIM profiles found.')
				: _('Profile data is unavailable.')
		]));

		return E([
			E('link', {
				'rel': 'stylesheet',
				'href': L.resource('view/lpac/profiles.css')
			}),
			E('h2', {}, [ _('eSIM profiles') ]),
			E('div', { 'class': 'cbi-map-descr' }, [
				_('Profiles are read directly from the eUICC using the configured lpac APDU backend.')
			]),
			(!result || !result.success)
				? E('div', { 'class': 'alert-message warning' }, [ lpac.errorMessage(result) ])
				: E([]),
			table,
			E('div', { 'class': 'cbi-page-actions' }, [
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
