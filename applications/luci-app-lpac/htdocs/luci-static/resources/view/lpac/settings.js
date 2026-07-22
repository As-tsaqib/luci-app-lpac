// SPDX-License-Identifier: Apache-2.0
/* global lpac */

'use strict';
'require view';
'require ui';
'require lpac';

const isReadonlyView = !L.hasViewPermission() || null;
const supportedBackends = [ 'uqmi', 'mbim', 'at', 'pcsc' ];

function formRow(label, input, description) {
	return E('div', { 'class': 'cbi-value' }, [
		E('label', {
			'class': 'cbi-value-title',
			'for': input.getAttribute('id') || null
		}, [ label ]),
		E('div', { 'class': 'cbi-value-field' }, [
			input,
			description ? E('div', { 'class': 'cbi-value-description' }, [ description ]) : E([])
		])
	]);
}

function textInput(id, value, placeholder, maxlength) {
	return E('input', {
		'id': id,
		'class': 'cbi-input-text',
		'type': 'text',
		'value': value || '',
		'placeholder': placeholder || '',
		'maxlength': maxlength || 128,
		'disabled': isReadonlyView
	});
}

function checkbox(id, checked) {
	return E('input', {
		'id': id,
		'type': 'checkbox',
		'checked': checked ? '' : null,
		'disabled': isReadonlyView
	});
}

function selectedBackends(drivers, current, discoveryAvailable) {
	const reported = drivers.apdu || drivers.LPAC_APDU || [];
	const values = (discoveryAvailable ? reported : supportedBackends).filter(function(name) {
		return supportedBackends.indexOf(name) !== -1;
	});

	if (current && values.indexOf(current) === -1 && supportedBackends.indexOf(current) !== -1)
		values.push(current);

	return values;
}

function validDevicePath(value) {
	if (typeof value !== 'string' || value.length < 6 || value.length > 128 ||
	    !/^\/dev\/[A-Za-z0-9._:+@,/-]+$/.test(value))
		return false;

	return !value.slice(5).split('/').some(function(part) {
		return !part || part === '.' || part === '..';
	});
}

function validPcscInterface(value) {
	return value === '' || (/^(0|[1-9][0-9]{0,3})$/.test(value) &&
		Number(value) <= 1024);
}

return view.extend({
	load: function() {
		return Promise.all([
			L.resolveDefault(lpac.getConfig(), null),
			L.resolveDefault(lpac.getDrivers(), null)
		]);
	},

	renderDetectedDevices: function(backend, devices) {
		const container = document.getElementById('lpac-' + backend + '-devices');

		if (!container)
			return;

		if (typeof container.replaceChildren === 'function')
			container.replaceChildren();
		else if (Array.isArray(container.children))
			container.children.length = 0;
		else
			while (container.firstChild)
				container.removeChild(container.firstChild);

		if (!devices.length) {
			container.appendChild(E('p', { 'class': 'cbi-value-description' }, [
				backend === 'at'
					? _('No AT serial ports were reported by lpac or found at supported OpenWrt device paths.')
					: _('No PC/SC readers were reported by pcscd.')
			]));
			return;
		}

		const select = E('select', {
			'class': 'cbi-input-select',
			'disabled': isReadonlyView
		}, devices.map(function(device, index) {
			return E('option', {
				'value': device.value,
				'selected': index === 0 ? '' : null
			}, [
				device.name + ' (' + device.value + ')'
			]);
		}));
		const target = backend === 'at'
			? 'lpac-at-device'
			: 'lpac-pcsc-interface';

		container.appendChild(E('div', {}, [
			select,
			' ',
			E('button', {
				'class': 'btn cbi-button cbi-button-action',
				'type': 'button',
				'disabled': isReadonlyView,
				'click': function(event) {
					if (event)
						event.preventDefault();

					document.getElementById(target).value = select.value;
				}
			}, [ _('Use selected') ])
		]));
	},

	detectApduDevices: function(backend) {
		const button = document.getElementById('lpac-detect-' + backend);
		const container = document.getElementById('lpac-' + backend + '-devices');

		if (!button || !container || isReadonlyView)
			return;

		button.disabled = true;
		container.textContent = '';
		container.appendChild(E('p', { 'class': 'spinning' }, [
			backend === 'at'
				? _('Detecting AT serial ports…')
				: _('Detecting PC/SC readers…')
		]));

		return lpac.listApduDevices(backend).then(function(result) {
			if (!result || !result.success || result.data?.backend !== backend ||
			    !Array.isArray(result.data.devices) ||
			    !result.data.devices.every(function(device) {
				return device && typeof device.name === 'string' &&
					typeof device.value === 'string' &&
					(backend === 'at'
						? validDevicePath(device.value)
						: validPcscInterface(device.value));
			}))
				throw new Error(lpac.errorMessage(result?.success
					? { error: 'invalid_response' }
					: result));

			this.renderDetectedDevices(backend, result.data.devices);
		}.bind(this)).catch(function(error) {
			container.textContent = '';
			container.appendChild(E('p', { 'class': 'alert-message warning' }, [
				error.message
			]));
		}).finally(function() {
			button.disabled = !!isReadonlyView;
		});
	},

	handleSaveConfig: function() {
		const atDevice = document.getElementById('lpac-at-device').value.trim();
		const pcscInterface = document.getElementById('lpac-pcsc-interface').value.trim();
		const uqmiDevice = document.getElementById('lpac-uqmi-device').value.trim();
		const mbimDevice = document.getElementById('lpac-mbim-device').value.trim();
		const aid = document.getElementById('lpac-custom-aid').value.trim();
		const backend = document.getElementById('lpac-apdu-backend').value;

		if (!validDevicePath(atDevice) || !validDevicePath(uqmiDevice) ||
		    !validDevicePath(mbimDevice)) {
			ui.addNotification(null, E('p', {}, [ _('Device paths must be safe absolute paths below /dev without empty, . or .. components.') ]), 'error');
			return;
		}

		if (!validPcscInterface(pcscInterface)) {
			ui.addNotification(null, E('p', {}, [ _('The PC/SC reader interface must be empty or a canonical index from 0 to 1024.') ]), 'error');
			return;
		}

		if (backend === 'uqmi' && !/^\/dev\/cdc-wdm[0-9]+$/.test(uqmiDevice)) {
			ui.addNotification(null, E('p', {}, [ _('The active uqmi backend currently requires a /dev/cdc-wdmN control device.') ]), 'error');
			return;
		}

		if (!/^[0-9A-Fa-f]{32}$/.test(aid)) {
			ui.addNotification(null, E('p', {}, [ _('The custom ISD-R AID must contain exactly 32 hexadecimal characters.') ]), 'error');
			return;
		}

		const config = {
			global: {
				apdu_backend: backend,
				http_backend: 'curl',
				apdu_debug: document.getElementById('lpac-apdu-debug').checked ? '1' : '0',
				http_debug: document.getElementById('lpac-http-debug').checked ? '1' : '0',
				custom_isd_r_aid: aid.toUpperCase()
			},
			at: {
				device: atDevice,
				debug: document.getElementById('lpac-at-debug').checked ? '1' : '0'
			},
			pcsc: {
				interface: pcscInterface
			},
			uqmi: {
				device: uqmiDevice,
				debug: document.getElementById('lpac-uqmi-debug').checked ? '1' : '0'
			},
			mbim: {
				device: mbimDevice,
				proxy: document.getElementById('lpac-mbim-proxy').checked ? '1' : '0',
				skip_slot_mapping: document.getElementById('lpac-mbim-skip-slot-mapping').checked ? '1' : '0'
			}
		};

		ui.showModal(_('Saving lpac settings'), [
			E('p', { 'class': 'spinning' }, [ _('Applying validated configuration…') ])
		]);

		return lpac.setConfig(config).then(function(result) {
			if (!result || !result.success)
				throw new Error(lpac.errorMessage(result));

			document.getElementById('lpac-custom-aid').value =
				result.data?.global?.custom_isd_r_aid || aid.toUpperCase();
			ui.hideModal();
			ui.addNotification(null, E('p', {}, [ _('The lpac settings were saved.') ]), 'info');
		}).catch(function(error) {
			ui.hideModal();
			ui.addNotification(null, E('p', {}, [ error.message ]), 'error');
		});
	},

	render: function(results) {
		const configResult = results[0];
		const driversResult = results[1];

		if (!configResult || !configResult.success) {
			return E([
				E('h2', {}, [ _('lpac settings') ]),
				E('div', { 'class': 'alert-message warning' }, [ lpac.errorMessage(configResult) ])
			]);
		}

		const config = configResult.data || {};
		const global = config.global || {};
		const at = config.at || {};
		const pcsc = config.pcsc || {};
		const uqmi = config.uqmi || {};
		const mbim = config.mbim || {};
		const drivers = lpac.dataOr(driversResult, {});
		const driverListAvailable = !!(driversResult && driversResult.success &&
			(drivers.apdu || drivers.LPAC_APDU || []).length);
		const backends = selectedBackends(drivers, global.apdu_backend,
			driverListAvailable);
		const backendSelect = E('select', {
			'id': 'lpac-apdu-backend',
			'class': 'cbi-input-select',
			'disabled': isReadonlyView
		}, backends.map(function(name) {
			return E('option', {
				'value': name,
				'selected': name === global.apdu_backend ? '' : null
			}, [ name ]);
		}));

		return E([
			E('h2', {}, [ _('lpac settings') ]),
			E('div', { 'class': 'cbi-map-descr' }, [
				_('These values are stored in the official /etc/config/lpac file. Changes apply to the next lpac operation and do not restart any modem or network interface.'),
				' ',
				_('Options not managed by this page are preserved when settings are saved.')
			]),
			E('div', { 'class': 'cbi-section' }, [
				E('h3', {}, [ _('General') ]),
				formRow(_('APDU backend'), backendSelect,
					driverListAvailable
						? _('Reported drivers are offered; an unreported current value is retained.')
						: _('Driver availability could not be confirmed, so supported backend names are offered without verification.')),
				formRow(_('Custom ISD-R AID'),
					textInput('lpac-custom-aid', global.custom_isd_r_aid || 'A0000005591010FFFFFFFF8900000100', '', 32),
					_('32-character hexadecimal application identifier used to select the eUICC ISD-R applet.')),
				formRow(_('APDU debug'), checkbox('lpac-apdu-debug', global.apdu_debug === '1'),
					_('Debug output can contain raw APDU data. Enable only for controlled troubleshooting.')),
				formRow(_('HTTP debug'), checkbox('lpac-http-debug', global.http_debug === '1'),
					_('Debug output can contain sensitive HTTP payloads. Enable only for controlled troubleshooting.'))
			]),
			!driverListAvailable
				? E('div', { 'class': 'alert-message warning' }, [
					driversResult && driversResult.success
						? _('No supported APDU drivers were reported by lpac.')
						: lpac.errorMessage(driversResult)
				])
				: E([]),
			E('div', { 'class': 'cbi-section' }, [
				E('h3', {}, [ _('uqmi backend') ]),
				formRow(_('Control device'),
					textInput('lpac-uqmi-device', uqmi.device || '/dev/cdc-wdm0', '/dev/cdc-wdm0'),
					_('Use the /dev/cdc-wdmN control device associated with the eUICC.')),
				formRow(_('uqmi debug'), checkbox('lpac-uqmi-debug', uqmi.debug === '1'))
			]),
			E('div', { 'class': 'cbi-section' }, [
				E('h3', {}, [ _('MBIM backend') ]),
				formRow(_('Control device'), textInput('lpac-mbim-device', mbim.device || '/dev/cdc-wdm0', '/dev/cdc-wdm0')),
				formRow(_('Use mbim-proxy'), checkbox('lpac-mbim-proxy', mbim.proxy !== '0')),
				formRow(_('Skip MBIM slot mapping'),
					checkbox('lpac-mbim-skip-slot-mapping', mbim.skip_slot_mapping === '1'),
					_('Use the modem\'s currently selected slot instead of querying or changing MBIM Device Slot Mapping. Enabled by default for compatibility; disable it on multi-slot devices that require normal slot selection.'))
			]),
			E('div', { 'class': 'cbi-section' }, [
				E('h3', {}, [ _('AT backend') ]),
				formRow(_('Serial device'),
					textInput('lpac-at-device', at.device || '/dev/ttyUSB2', '/dev/ttyUSB2'),
					_('The AT backend is timing-sensitive and may not support every profile operation on all modems.')),
				formRow(_('Device detection'), E('div', {}, [
					E('button', {
						'id': 'lpac-detect-at',
						'class': 'btn cbi-button cbi-button-action',
						'type': 'button',
						'disabled': isReadonlyView,
						'click': ui.createHandlerFn(this, 'detectApduDevices', 'at')
					}, [ _('Detect AT ports') ]),
					E('div', { 'id': 'lpac-at-devices' })
				]), _('Detection combines stable links reported by lpac with strict ttyUSB, ttyACM, and wwan AT device patterns. It does not send AT commands.')),
				formRow(_('AT debug'), checkbox('lpac-at-debug', at.debug === '1'))
			]),
			E('div', { 'class': 'cbi-section' }, [
				E('h3', {}, [ _('PC/SC backend') ]),
				formRow(_('Reader interface'),
					textInput('lpac-pcsc-interface', pcsc.interface || '', _('First available reader'), 4),
					_('Leave empty to let lpac use the first available reader, or select a detected numeric interface.')),
				formRow(_('Reader detection'), E('div', {}, [
					E('button', {
						'id': 'lpac-detect-pcsc',
						'class': 'btn cbi-button cbi-button-action',
						'type': 'button',
						'disabled': isReadonlyView,
						'click': ui.createHandlerFn(this, 'detectApduDevices', 'pcsc')
					}, [ _('Detect PC/SC readers') ]),
					E('div', { 'id': 'lpac-pcsc-devices' })
				]), _('Detection asks the native lpac PC/SC driver to enumerate pcscd readers without opening an eUICC channel.'))
			]),
			E('div', { 'class': 'cbi-page-actions' }, [
				E('button', {
					'class': 'btn cbi-button cbi-button-positive important',
					'disabled': isReadonlyView,
					'click': ui.createHandlerFn(this, 'handleSaveConfig')
				}, [ _('Save') ])
			])
		]);
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
