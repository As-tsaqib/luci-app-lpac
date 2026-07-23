// SPDX-License-Identifier: Apache-2.0
/* global lpac */

'use strict';
'require view';
'require ui';
'require lpac';

const isReadonlyView = !L.hasViewPermission() || null;

function resultError(title, result) {
	return E('div', { 'class': 'alert-message warning' }, [
		E('strong', {}, [ title ]),
		E('br'),
		lpac.errorMessage(result)
	]);
}

function valueOrUnknown(value) {
	return value != null && value !== '' ? value : _('Unknown');
}

function formatBytes(value) {
	return value != null && value !== '' && Number.isFinite(+value)
		? '%1024.2mB'.format(+value)
		: _('Unknown');
}

function formatList(values) {
	return Array.isArray(values) && values.length
		? values.join(', ')
		: null;
}

function formatCount(value) {
	return value != null && value !== '' && Number.isFinite(+value)
		? String(value)
		: null;
}

function detailsTable(fields) {
	const table = E('table', { 'class': 'table' });

	for (let i = 0; i < fields.length; i += 2) {
		table.appendChild(E('tr', { 'class': 'tr' }, [
			E('td', { 'class': 'td left', 'width': '35%' }, [ fields[i] ]),
			E('td', { 'class': 'td left' }, [ valueOrUnknown(fields[i + 1]) ])
		]));
	}

	return table;
}

function advancedEuiccInformation(info2, resources) {
	const certification = info2.certificationDataObject || {};
	const sasAccreditation = info2.sasAccreditationNumber ||
		info2.sasAcreditationNumber;

	return E('details', {
		'id': 'lpac-advanced-euicc-information',
		'class': 'cbi-section',
		'style': 'margin-bottom:1em'
	}, [
		E('summary', { 'style': 'cursor:pointer' }, [
			E('strong', {}, [ _('Advanced eUICC information') ])
		]),
		E('p', { 'class': 'cbi-section-descr' }, [
			_('Technical capability and certification metadata used mainly for compatibility diagnostics, certification, and development.')
		]),
		detailsTable([
			_('Installed application count'), formatCount(resources.installedApplication),
			_('ETSI TS 102 241 version'), info2.ts102241Version,
			_('GlobalPlatform version'), info2.globalplatformVersion,
			_('UICC capabilities'), formatList(info2.uiccCapability),
			_('RSP capabilities'), formatList(info2.rspCapability),
			_('CI public key IDs for verification'),
				formatList(info2.euiccCiPKIdListForVerification),
			_('CI public key IDs for signing'),
				formatList(info2.euiccCiPKIdListForSigning),
			_('eUICC category'), info2.euiccCategory,
			_('Forbidden Profile Policy Rules'),
				formatList(info2.forbiddenProfilePolicyRules),
			_('Protection Profile version'), info2.ppVersion,
			_('SAS accreditation number'), sasAccreditation,
			_('Platform label'), certification.platformLabel,
			_('Discovery Base URL'), certification.discoveryBaseURL
		])
	]);
}

return view.extend({
	currentDefaultSmdp: null,
	defaultSmdpUpdating: false,

	load: function() {
		return Promise.all([
			L.resolveDefault(lpac.getVersion(), null),
			L.resolveDefault(lpac.getDrivers(), null),
			L.resolveDefault(lpac.getInfo(), null),
			L.resolveDefault(lpac.getConfig(), null)
		]);
	},

	defaultSmdpField: function(address) {
		const children = [ E('span', {
			'id': 'lpac-default-smdp-value',
			'style': 'min-width:0;max-width:100%;overflow-wrap:anywhere'
		}, [ valueOrUnknown(address) ]) ];

		if (!isReadonlyView) {
			children.push(' ', E('button', {
				'id': 'lpac-default-smdp-edit',
				'class': 'btn cbi-button cbi-button-edit',
				'type': 'button',
				'click': ui.createHandlerFn(this, 'showDefaultSmdpModal')
			}, [ _('Change') ]));
		}

		return E('span', {
			'style': 'display:inline-flex;align-items:center;gap:.4em;flex-wrap:wrap;min-width:0;max-width:100%'
		}, children);
	},

	setDefaultSmdpBusy: function(busy) {
		this.defaultSmdpUpdating = busy;
		const edit = document.getElementById('lpac-default-smdp-edit');

		if (edit)
			edit.disabled = busy;
	},

	updateDefaultSmdpDisplay: function(address) {
		this.currentDefaultSmdp = address;
		const value = document.getElementById('lpac-default-smdp-value');

		if (value)
			value.textContent = valueOrUnknown(address);
	},

	showDefaultSmdpModal: function(prefill) {
		if (isReadonlyView || this.defaultSmdpUpdating)
			return;

		const oldAddress = this.currentDefaultSmdp;
		const input = E('input', {
			'id': 'lpac-default-smdp-input',
			'class': 'cbi-input-text',
			'type': 'text',
			'maxlength': 255,
			'autocomplete': 'off',
			'spellcheck': 'false',
			'value': typeof prefill === 'string' ? prefill : oldAddress || '',
			'placeholder': 'smdp.example.com:443'
		});

		ui.showModal(_('Change default SM-DP+ address'), [
			E('div', { 'class': 'cbi-value' }, [
				E('span', { 'class': 'cbi-value-title' }, [ _('Current address') ]),
				E('span', { 'class': 'cbi-value-field' }, [
					valueOrUnknown(oldAddress)
				])
			]),
			E('div', { 'class': 'cbi-value' }, [
				E('label', {
					'class': 'cbi-value-title',
					'for': 'lpac-default-smdp-input'
				}, [ _('New address') ]),
				E('div', { 'class': 'cbi-value-field' }, [ input ])
			]),
			E('p', { 'class': 'alert-message warning', 'role': 'note' }, [
				_('This changes persistent state on the eUICC, not a LuCI setting. The address remains configured after a router reboot.')
			]),
			E('p', { 'class': 'cbi-value-description', 'role': 'note' }, [
				_('Compatible lpac operations that omit an explicit SM-DP+ address use this default. Clearing the eUICC default is not supported by this form.')
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
					'click': ui.createHandlerFn(this,
						'reviewDefaultSmdpChange', oldAddress, input)
				}, [ _('Review change') ])
			])
		]);

		input.focus();
	},

	reviewDefaultSmdpChange: function(oldAddress, input) {
		if (isReadonlyView || this.defaultSmdpUpdating)
			return;

		const address = String(input.value || '');
		let message = null;

		input.removeAttribute('aria-invalid');

		if (!address.trim())
			message = _('The default SM-DP+ address cannot be empty.');
		else if (!lpac.validSmdpAddress(address))
			message = _('Enter a valid SM-DP+ host or bracketed IPv6 address with an optional port.');
		else if (address === oldAddress)
			message = _('Enter a different address before continuing.');

		if (message) {
			input.setAttribute('aria-invalid', 'true');
			input.focus();
			ui.addNotification(null, E('p', {}, [ message ]), 'error');
			return;
		}

		ui.showModal(_('Confirm persistent SM-DP+ change'), [
			E('p', {}, [
				_('Set the eUICC default SM-DP+ address to the new value below?')
			]),
			detailsTable([
				_('Current address'), oldAddress,
				_('New address'), address
			]),
			E('p', { 'class': 'alert-message warning', 'role': 'alert' }, [
				_('Confirming writes persistent eUICC state and changes the default server used by compatible lpac operations that omit an explicit SM-DP+ address.')
			]),
			E('div', { 'class': 'right' }, [
				E('button', {
					'class': 'btn',
					'type': 'button',
					'click': ui.createHandlerFn(this,
						'showDefaultSmdpModal', address)
				}, [ _('Back') ]),
				' ',
				E('button', {
					'class': 'btn cbi-button-positive important',
					'type': 'button',
					'click': ui.createHandlerFn(this,
						'applyDefaultSmdpChange', address)
				}, [ _('Set persistent address') ])
			])
		]);
	},

	applyDefaultSmdpChange: function(address) {
		if (isReadonlyView || this.defaultSmdpUpdating ||
		    !lpac.validSmdpAddress(address) || !address.length)
			return;

		this.setDefaultSmdpBusy(true);
		ui.showModal(_('Updating default SM-DP+ address'), [
			E('p', { 'class': 'spinning' }, [ _('Waiting for lpac…') ])
		]);

		return lpac.setDefaultSmdp(address).then(function(result) {
			if (!result || !result.success) {
				const ambiguous = [ 'transport_error', 'timeout', 'execution_failed' ]
					.includes(result?.error);

				ui.hideModal();
				ui.addNotification(null, E('p', {}, [
					ambiguous
						? _('The update outcome could not be confirmed. Refresh eUICC information before retrying.')
						: _('The default SM-DP+ address was not confirmed as changed.'),
					' ',
					lpac.errorMessage(result)
				]), ambiguous ? 'warning' : 'error');
				return;
			}

			return lpac.getInfo().then(function(infoResult) {
				ui.hideModal();

				if (!infoResult || !infoResult.success) {
					ui.addNotification(null, E('p', {}, [
						_('lpac accepted the update, but the eUICC readback failed. Do not assume the displayed address is current; refresh before retrying.'),
						' ',
						lpac.errorMessage(infoResult)
					]), 'warning');
					return;
				}

				const readback = infoResult.data?.EuiccConfiguredAddresses?.defaultDpAddress;
				const hasReadback = typeof readback === 'string' &&
					readback.length <= 255 && !/[\u0000-\u001F\u007F]/.test(readback);

				if (hasReadback)
					this.updateDefaultSmdpDisplay(readback);

				if (hasReadback && readback === address) {
					ui.addNotification(null, E('p', {}, [
						_('The default SM-DP+ address was updated and verified by eUICC readback.')
					]), 'info');
				}
				else {
					ui.addNotification(null, E('p', {}, [
						_('lpac accepted the update, but eUICC readback did not match the requested address.'),
						' ', _('Requested:'), ' ', address, '. ',
						_('Read back:'), ' ', hasReadback
							? valueOrUnknown(readback)
							: _('Unavailable'), '. ',
						_('No successful change is being claimed; refresh and review the current value before retrying.')
					]), 'warning');
				}
			}.bind(this));
		}.bind(this)).catch(function() {
			ui.hideModal();
			ui.addNotification(null, E('p', {}, [
				_('The update or its readback could not be completed. Its outcome is not being claimed; refresh eUICC information before retrying.')
			]), 'warning');
		}).finally(function() {
			this.setDefaultSmdpBusy(false);
		}.bind(this));
	},

	render: function(results) {
		const versionResult = results[0];
		const driversResult = results[1];
		const infoResult = results[2];
		const configResult = results[3];
		const version = lpac.dataOr(versionResult, _('Unavailable'));
		const drivers = lpac.dataOr(driversResult, {});
		const config = lpac.dataOr(configResult, {});
		const apduDrivers = drivers.apdu || drivers.LPAC_APDU || [];
		const httpDrivers = drivers.http || drivers.LPAC_HTTP || [];
		const backend = config.global && config.global.apdu_backend;
		const nodes = [
			E('h2', {}, [ _('eSIM Manager') ]),
			E('div', { 'class': 'cbi-map-descr' }, [
				_('Manage the eUICC through the official OpenWrt lpac package. Modem and network lifecycle operations remain outside this application.')
			]),
			E('div', { 'class': 'cbi-section' }, [
				E('h3', {}, [ _('Backend status') ]),
				detailsTable([
					_('lpac version'), version,
					_('Selected APDU backend'), backend,
					_('Available APDU backends'), apduDrivers.length ? apduDrivers.join(', ') : null,
					_('Available HTTP backends'), httpDrivers.length ? httpDrivers.join(', ') : null
				])
			])
		];

		if (!versionResult || !versionResult.success)
			nodes.push(resultError(_('Unable to read lpac version'), versionResult));

		if (!driversResult || !driversResult.success)
			nodes.push(resultError(_('Unable to read lpac drivers'), driversResult));

		if (!configResult || !configResult.success)
			nodes.push(resultError(_('Unable to read lpac settings'), configResult));

		if (!infoResult || !infoResult.success) {
			nodes.push(resultError(_('Unable to read eUICC information'), infoResult));
		}
		else {
			const info = infoResult.data || {};
			const addresses = info.EuiccConfiguredAddresses || {};
			const info2 = info.EUICCInfo2 || {};
			const resources = info2.extCardResource || {};

			this.currentDefaultSmdp = typeof addresses.defaultDpAddress === 'string'
				? addresses.defaultDpAddress
				: null;

			nodes.push(E('div', { 'class': 'cbi-section' }, [
				E('h3', {}, [ _('eUICC information') ]),
				detailsTable([
					_('EID'), info.eidValue,
					_('Firmware version'), info2.euiccFirmwareVer,
					_('Profile specification'), info2.profileVersion,
					_('SVN version'), info2.svn,
					_('Default SM-DP+ address'),
						this.defaultSmdpField(this.currentDefaultSmdp),
					_('Root SM-DS address'), addresses.rootDsAddress,
					_('Free non-volatile memory'), formatBytes(resources.freeNonVolatileMemory),
					_('Free volatile memory'), formatBytes(resources.freeVolatileMemory)
				])
			]), advancedEuiccInformation(info2, resources));
		}

		nodes.push(E('div', { 'class': 'cbi-page-actions' }, [
			E('button', {
				'class': 'btn cbi-button cbi-button-action',
				'type': 'button',
				'click': ui.createHandlerFn(this, function() {
					window.location.reload();
				})
			}, [ _('Refresh') ])
		]));

		return E(nodes);
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
