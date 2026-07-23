// SPDX-License-Identifier: Apache-2.0
/* global lpac */

'use strict';
'require view';
'require ui';
'require poll';
'require lpac';

const isReadonlyView = !L.hasViewPermission() || null;
const maxQRFileSize = 8 * 1024 * 1024;
const maxQRImagePixels = 40000000;
const qrDecodeSizes = [ 1600, 1200, 900, 700 ];
const jobOriginOwned = 'owned';
const jobOriginExternal = 'external';
const jobOriginUncertain = 'uncertain';
const activationEdgeMarks = [
	'\u00ad', '\u034f', '\u061c', '\u180e', '\u200b', '\u200c', '\u200d',
	'\u200e', '\u200f', '\u202a', '\u202b', '\u202c', '\u202d', '\u202e',
	'\u2060', '\u2061', '\u2062', '\u2063', '\u2064', '\u2066', '\u2067',
	'\u2068', '\u2069', '\ufeff'
];
let jsQRPromise = null;

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

function textInput(id, type, placeholder, maxlength, disabled, inputHandler) {
	const attributes = {
		'id': id,
		'class': 'cbi-input-text',
		'type': type || 'text',
		'placeholder': placeholder || '',
		'maxlength': maxlength,
		'autocomplete': 'off',
		'spellcheck': 'false',
		'disabled': disabled === undefined ? isReadonlyView : disabled
	};

	if (inputHandler)
		attributes.input = inputHandler;

	return E('input', attributes);
}

function normalizeActivationCode(value) {
	value = String(value || '').trim();

	while (value.length) {
		let changed = false;

		for (let i = 0; i < activationEdgeMarks.length; i++) {
			const mark = activationEdgeMarks[i];

			if (value.startsWith(mark)) {
				value = value.slice(mark.length).trim();
				changed = true;
				break;
			}

			if (value.endsWith(mark)) {
				value = value.slice(0, -mark.length).trim();
				changed = true;
				break;
			}
		}

		if (!changed)
			break;
	}

	value = /^lpa:/i.test(value) ? `LPA:${value.slice(4)}` : value;

	const hasScheme = value.startsWith('LPA:');
	const fields = (hasScheme ? value.slice(4) : value).split('$');

	/* Avoid lpac 2.3.0 treating an empty optional fifth field as required. */
	if (fields.length === 5 && fields[4] === '')
		fields.pop();

	return (hasScheme ? 'LPA:' : '') + fields.join('$');
}

function hasActivationFormatMark(value) {
	for (let i = 0; i < activationEdgeMarks.length; i++)
		if (value.includes(activationEdgeMarks[i]))
			return true;

	return false;
}

function validMatchingId(value) {
	return value.length <= 255 && /^[A-Za-z0-9-]+$/.test(value);
}

function activationCodeIssue(value, confirmationCode, allowMissingConfirmation) {
	let code = normalizeActivationCode(value);

	if (code.length < 5 || code.length > 4096 || /\s/.test(code) ||
	    hasActivationFormatMark(code))
		return 'format';

	if (code.startsWith('LPA:'))
		code = code.slice(4);

	const fields = code.split('$');

	if (fields.length < 3 || fields.length > 5 || fields[0] !== '1' ||
	    !fields[1] || !lpac.validSmdpAddress(fields[1]) ||
	    (fields[2] && !validMatchingId(fields[2])) ||
	    (fields.length >= 4 && fields[3].length > 255))
		return 'format';

	if (fields.length === 5 && fields[4] && fields[4] !== '0' && fields[4] !== '1')
		return 'format';

	if (!allowMissingConfirmation && fields.length === 5 && fields[4] === '1' &&
	    confirmationCode.length === 0)
		return 'confirmation_required';

	return null;
}

function validActivationCode(value, confirmationCode, allowMissingConfirmation) {
	return activationCodeIssue(value, confirmationCode, allowMissingConfirmation) === null;
}

function activationServer(value) {
	const code = normalizeActivationCode(value);
	const fields = (code.startsWith('LPA:') ? code.slice(4) : code).split('$');

	return fields[1] || '';
}

function validationError(message, fieldId) {
	const error = new Error(message);

	error.fieldId = fieldId;
	return error;
}

function isIdleDownloadStatus(result) {
	return result?.success === true && result.data?.status === 'idle';
}

function isTerminalDownloadStatus(result) {
	if (result?.success === true)
		return result.data?.status === 'success' || result.data?.status === 'cancelled';

	return result?.success === false && [
		'execution_failed', 'lpac_error', 'not_installed', 'timeout',
		'safety_state_failed'
	].includes(result.error);
}

function loadJsQR() {
	if (typeof window.jsQR === 'function')
		return Promise.resolve(window.jsQR);

	if (jsQRPromise)
		return jsQRPromise;

	jsQRPromise = new Promise(function(resolve, reject) {
		const script = document.createElement('script');

		script.src = L.resource('jsqr.min.js');
		script.async = true;
		script.onload = function() {
			if (typeof window.jsQR === 'function')
				resolve(window.jsQR);
			else {
				jsQRPromise = null;
				reject(new Error(_('The QR decoder did not initialize.')));
			}
		};
		script.onerror = function() {
			jsQRPromise = null;
			reject(new Error(_('The QR decoder could not be loaded.')));
		};
		document.head.appendChild(script);
	});

	return jsQRPromise;
}

function readImage(file) {
	return new Promise(function(resolve, reject) {
		const reader = new window.FileReader();

		reader.onerror = function() {
			reject(new Error(_('The selected image could not be read.')));
		};
		reader.onload = function() {
			const image = new window.Image();

			image.onerror = function() {
				reject(new Error(_('The selected file is not a readable image.')));
			};
			image.onload = function() {
				resolve({ image, dataUrl: reader.result });
			};
			image.src = reader.result;
		};
		reader.readAsDataURL(file);
	});
}

function decodeImage(decoder, image) {
	const sourceWidth = image.naturalWidth || image.width;
	const sourceHeight = image.naturalHeight || image.height;
	const tried = {};

	if (!sourceWidth || !sourceHeight || sourceWidth * sourceHeight > maxQRImagePixels)
		throw new Error(_('The QR image dimensions are invalid or too large.'));

	for (let i = 0; i < qrDecodeSizes.length; i++) {
		const scale = Math.min(1, qrDecodeSizes[i] / Math.max(sourceWidth, sourceHeight));
		const width = Math.max(1, Math.round(sourceWidth * scale));
		const height = Math.max(1, Math.round(sourceHeight * scale));
		const key = `${width}x${height}`;

		if (tried[key])
			continue;

		tried[key] = true;

		const canvas = document.createElement('canvas');
		const context = canvas.getContext('2d', { willReadFrequently: true });

		if (!context)
			throw new Error(_('The browser cannot prepare the QR image.'));

		canvas.width = width;
		canvas.height = height;
		context.drawImage(image, 0, 0, width, height);

		const imageData = context.getImageData(0, 0, width, height);
		const decoded = decoder(imageData.data, width, height, {
			inversionAttempts: 'attemptBoth'
		});

		if (decoded && typeof decoded.data === 'string')
			return normalizeActivationCode(decoded.data);
	}

	return null;
}

return view.extend({
	activeJob: null,
	activeJobOrigin: null,
	activeDecisionToken: null,
	activePhase: null,
	activeSmdp: null,
	downloadStarting: false,
	checkingCurrentJob: false,
	discovering: false,
	activeDiscoveryJob: null,
	activeDiscoveryOrigin: null,
	activeDiscoveryToken: null,
	activeDiscoveryPhase: null,
	discoveryPendingStart: false,
	discoveryStatusFailures: 0,
	discoveryEntries: [],
	discoveryGeneration: 0,
	discoveryButtons: [],
	previewDecisionSent: false,
	previewModalJob: null,
	qrActivationCode: null,
	qrDecodeGeneration: 0,
	qrDecoding: false,
	pollRegistered: false,
	statusFailures: 0,
	pendingStartResult: null,
	retryBlocked: false,
	verificationIncident: null,
	verificationProfilesRefreshed: false,
	verificationNotificationsRefreshed: false,
	verificationAcknowledging: false,
	verificationButton: null,

	load: function() {
		this.activeJob = null;
		this.activeJobOrigin = null;
		this.activeDecisionToken = null;
		this.activePhase = null;
		this.activeSmdp = null;
		this.downloadStarting = false;
		this.checkingCurrentJob = false;
		this.discovering = false;
		this.activeDiscoveryJob = null;
		this.activeDiscoveryOrigin = null;
		this.activeDiscoveryToken = null;
		this.activeDiscoveryPhase = null;
		this.discoveryPendingStart = false;
		this.discoveryStatusFailures = 0;
		this.discoveryEntries = [];
		this.discoveryButtons = [];
		this.previewDecisionSent = false;
		this.previewModalJob = null;
		this.pendingStartResult = null;
		this.statusFailures = 0;
		this.retryBlocked = false;
		this.verificationIncident = null;
		this.verificationProfilesRefreshed = false;
		this.verificationNotificationsRefreshed = false;
		this.verificationAcknowledging = false;
		this.verificationButton = null;
		return L.resolveDefault(lpac.getDownloadStatus(0, ''), null);
	},

	isBusy: function() {
		return !!(this.activeJob || this.downloadStarting ||
			this.checkingCurrentJob || this.discovering);
	},

	updateControls: function() {
		const busy = this.isBusy();
		const disabled = !!isReadonlyView || busy;

		[
			'lpac-download-mode', 'lpac-activation-code', 'lpac-qr-file',
			'lpac-qr-camera', 'lpac-qr-file-button', 'lpac-qr-camera-button',
			'lpac-imei', 'lpac-smds', 'lpac-confirmation-code',
			'lpac-download-clear'
		].forEach(function(id) {
			const control = document.getElementById(id);

			if (control)
				control.disabled = disabled;
		});

		const download = document.getElementById('lpac-download-button');

		if (download)
			download.disabled = disabled || this.qrDecoding || this.retryBlocked;

		this.discoveryButtons.forEach(function(button) {
			button.disabled = disabled;
		});

		[ 'lpac-qr-file', 'lpac-qr-camera',
			'lpac-qr-file-button', 'lpac-qr-camera-button' ].forEach(function(id) {
			const control = document.getElementById(id);

			if (control)
				control.disabled = disabled || this.qrDecoding;
		}.bind(this));
	},

	setDownloadProgress: function(visible, message) {
		const status = document.getElementById('lpac-download-progress');
		const text = document.getElementById('lpac-download-progress-text');

		if (status)
			status.style.display = visible ? '' : 'none';

		if (text)
			text.textContent = message || '';
	},

	setVerificationRequired: function(visible) {
		const warning = document.getElementById('lpac-download-verification');

		if (warning)
			warning.style.display = visible ? '' : 'none';

		this.updateVerificationControl();
	},

	updateVerificationControl: function() {
		if (!this.verificationButton)
			return;

		this.verificationButton.disabled = !!(isReadonlyView ||
			this.verificationAcknowledging || !this.retryBlocked ||
			!this.verificationIncident || !this.verificationProfilesRefreshed ||
			!this.verificationNotificationsRefreshed);
	},

	reconcileActionControls: function() {
		this.updateControls();
		this.updateVerificationControl();
	},

	applyDownloadSafety: function(result, update) {
		const safety = typeof result?.data?.verification_required === 'boolean'
			? result.data : result?.data?.safety;

		if (!safety || typeof safety !== 'object' ||
		    typeof safety.verification_required !== 'boolean')
			return false;

		if (!safety.verification_required) {
			this.verificationIncident = null;
			this.verificationProfilesRefreshed = false;
			this.verificationNotificationsRefreshed = false;

			if (this.activeJobOrigin !== jobOriginUncertain)
				this.retryBlocked = false;
		}
		else {
			this.retryBlocked = true;
			this.verificationIncident = typeof safety.incident_id === 'string' &&
				/^[A-Za-z0-9_-]{32}$/.test(safety.incident_id)
				? safety.incident_id : null;
			this.verificationProfilesRefreshed = safety.profiles_refreshed === true;
			this.verificationNotificationsRefreshed =
				safety.notifications_refreshed === true;
		}

		if (update !== false) {
			this.setVerificationRequired(this.retryBlocked);
			this.updateControls();
		}

		return true;
	},

	acknowledgeDownloadVerification: function() {
		if (isReadonlyView || this.verificationAcknowledging ||
		    !this.retryBlocked || !this.verificationIncident ||
		    !this.verificationProfilesRefreshed ||
		    !this.verificationNotificationsRefreshed)
			return;

		const incident = this.verificationIncident;

		this.verificationAcknowledging = true;
		this.updateVerificationControl();

		return lpac.acknowledgeDownloadVerification(incident).then(function(result) {
			if (!result || !result.success) {
				this.applyDownloadSafety(result);
				throw new Error(lpac.errorMessage(result));
			}

			if (result.data?.verification_required !== false)
				throw new Error(lpac.errorMessage({ error: 'invalid_response' }));

			this.retryBlocked = false;
			this.verificationIncident = null;
			this.verificationProfilesRefreshed = false;
			this.verificationNotificationsRefreshed = false;
			this.setVerificationRequired(false);
			this.updateControls();
			ui.addNotification(null, E('p', {}, [
				_('The previous download verification was acknowledged.')
			]), 'info');
		}.bind(this)).catch(function(error) {
			ui.addNotification(null, E('p', {}, [ error.message ]), 'error');
		}).finally(function() {
			this.verificationAcknowledging = false;
			this.updateVerificationControl();
		}.bind(this));
	},

	runningJobMessage: function() {
		if (this.activePhase === 'awaiting_confirmation') {
			return this.activeJobOrigin === jobOriginOwned &&
				this.activeDecisionToken && !this.previewDecisionSent
				? _('The profile is ready for review. Confirm or cancel it in the preview dialog.')
				: _('A profile download is waiting for its original tab to confirm it; otherwise it will cancel automatically.');
		}

		if (this.activePhase === 'installing')
			return _('lpac is installing the approved profile…');

		if (this.activePhase === 'cancelling')
			return _('lpac is cancelling the profile download session…');

		if (this.activeJobOrigin === jobOriginOwned)
			return _('lpac is authenticating and retrieving the profile preview…');

		if (this.activeJobOrigin === jobOriginUncertain)
			return _('The start response was lost. Checking whether lpac is still running…');

		return _('Another profile download is running. Monitoring it before this form can be submitted.');
	},

	attachRunningJob: function(result, origin) {
		const id = result?.data?.job_id;

		if (!result?.success || result.data?.status !== 'running' ||
		    !Number.isInteger(id) || id < 1)
			return false;

		this.activeJob = id;
		let normalizedOrigin = origin === jobOriginOwned || origin === jobOriginUncertain
			? origin
			: jobOriginExternal;
		const token = result.data?.decision_token;

		if (normalizedOrigin === jobOriginOwned) {
			if (typeof token === 'string' && /^[A-Za-z0-9_-]{32}$/.test(token))
				this.activeDecisionToken = token;
			else {
				this.activeDecisionToken = null;
				normalizedOrigin = jobOriginUncertain;
				this.retryBlocked = true;
			}
		}
		else {
			this.activeDecisionToken = null;
			this.activeSmdp = null;

			if (this.previewModalJob !== null)
				ui.hideModal();

			this.previewModalJob = null;
			this.previewDecisionSent = false;
		}

		this.activeJobOrigin = normalizedOrigin;
		this.activePhase = typeof result.data?.phase === 'string'
			? result.data.phase
			: 'authenticating';
		this.downloadStarting = false;
		this.checkingCurrentJob = false;
		this.statusFailures = 0;
		this.pendingStartResult = null;
		this.handlePreviewState(result);
		this.setDownloadProgress(true, this.runningJobMessage());
		this.setVerificationRequired(this.retryBlocked);
		this.updateControls();
		return true;
	},

	previewField: function(label, value) {
		return E('div', { 'class': 'cbi-value' }, [
			E('span', { 'class': 'cbi-value-title' }, [ label ]),
			' ',
			E('span', { 'class': 'cbi-value-field' }, [ value || '-' ])
		]);
	},

	showProfilePreview: function(preview, smdp) {
		if (!this.activeJob || !this.activeDecisionToken ||
		    this.previewDecisionSent || this.previewModalJob === this.activeJob)
			return;

		this.previewModalJob = this.activeJob;
		const content = [];
		const iconUri = lpac.profileIconUri(preview?.iconType, preview?.icon);

		if (iconUri) {
			const fallback = E('span', {
				'aria-hidden': 'true',
				'style': 'display:none;width:64px;height:64px;border:1px solid currentColor;opacity:.35;border-radius:.4rem'
			});

			content.push(E('div', { 'class': 'center' }, [
				E('img', {
					'src': iconUri,
					'alt': '',
					'width': 64,
					'height': 64,
					'style': 'width:64px;height:64px;object-fit:contain;border-radius:.4rem',
					'error': function(event) {
						event.currentTarget.style.display = 'none';
						fallback.style.display = 'inline-block';
					}
				}),
				fallback
			]));
		}

		if (preview) {
			content.push(
				this.previewField(_('Profile name'), preview.profileName),
				this.previewField(_('Provider'), preview.serviceProviderName),
				this.previewField(_('ICCID'), preview.iccid),
				this.previewField(_('Profile class'), preview.profileClass)
			);
		}
		else {
			content.push(E('div', { 'class': 'alert-message warning', 'role': 'note' }, [
				_('The provider did not supply profile metadata. The profile identity and icon cannot be verified before installation.')
			]));
		}

		content.push(
			this.previewField(_('SM-DP+ server'), smdp),
			E('p', { 'class': 'cbi-value-description', 'role': 'note' }, [
				_('Install continues this same authenticated lpac session. Cancel rejects it before PrepareDownload; opening a second session is not used for preview.')
			]),
			E('div', { 'class': 'right' }, [
				E('button', {
					'class': 'btn cbi-button-negative',
					'type': 'button',
					'click': ui.createHandlerFn(this, 'respondToPreview', false)
				}, [ _('Cancel download') ]),
				' ',
				E('button', {
					'class': 'btn cbi-button-positive important',
					'type': 'button',
					'click': ui.createHandlerFn(this, 'respondToPreview', true)
				}, [ preview ? _('Install profile') : _('Install without metadata') ])
			])
		);

		ui.showModal(_('Review eSIM profile'), content);
	},

	handlePreviewState: function(result) {
		if (!result?.success || result.data?.status !== 'running' ||
		    result.data?.job_id !== this.activeJob)
			return;

		if (typeof result.data.phase === 'string')
			this.activePhase = result.data.phase;

		if (this.activePhase === 'awaiting_confirmation' &&
		    this.activeJobOrigin === jobOriginOwned && this.activeDecisionToken &&
		    !this.previewDecisionSent)
			this.showProfilePreview(result.data.preview ?? null,
				this.activeSmdp || _('Use the default address stored on the eUICC'));
	},

	respondToPreview: function(accept) {
		if (!this.activeJob || !this.activeDecisionToken ||
		    this.activePhase !== 'awaiting_confirmation' ||
		    this.previewDecisionSent)
			return;

		const jobId = this.activeJob;
		const token = this.activeDecisionToken;

		this.previewDecisionSent = true;
		this.previewModalJob = null;
		this.activePhase = accept ? 'installing' : 'cancelling';
		ui.hideModal();
		this.setDownloadProgress(true, accept
			? _('Authorizing profile installation…')
			: _('Cancelling the profile download session…'));
		this.updateControls();

		return lpac.respondDownloadPreview(jobId, token, !!accept).then(function(result) {
			if (!result || !result.success) {
				ui.addNotification(null, E('p', {}, [
					_('The preview response could not be confirmed. It will not be sent again automatically. Status polling will determine whether lpac continued or cancelled.'),
					' ', lpac.errorMessage(result)
				]), 'warning');
			}

			return this.pollDownload();
		}.bind(this));
	},

	openQRPicker: function(input) {
		if (input && !this.isBusy() && !this.qrDecoding && !isReadonlyView)
			input.click();
	},

	handleActivationInput: function() {
		const decoding = this.qrDecoding;
		const hadQRResult = this.qrActivationCode !== null;

		if (!decoding && !hadQRResult)
			return;

		if (decoding) {
			this.qrDecodeGeneration++;
			this.qrDecoding = false;
		}

		this.clearQRResult();
		this.setQRStatus('');
		this.updateControls();
	},

	updateMode: function() {
		const mode = document.getElementById('lpac-download-mode').value;
		const activation = document.getElementById('lpac-download-activation-fields');
		const discovery = document.getElementById('lpac-download-discovery-fields');
		const primary = document.getElementById('lpac-download-button');

		activation.style.display = mode === 'activation' ? '' : 'none';
		discovery.style.display = mode === 'discovery' ? '' : 'none';

		if (primary)
			primary.textContent = mode === 'discovery'
				? _('Discover profiles')
				: _('Retrieve profile preview');
	},

	handleModeChange: function() {
		if (this.qrDecoding)
			this.handleActivationInput();

		this.updateMode();
	},

	clearDiscoveryResults: function() {
		this.discoveryGeneration++;
		this.discoveryEntries = [];
		this.discoveryButtons = [];

		const results = document.getElementById('lpac-discovery-results');

		if (!results)
			return;

		if (typeof results.replaceChildren === 'function')
			results.replaceChildren();
		else if (Array.isArray(results.children))
			results.children.length = 0;
		else
			while (results.firstChild)
				results.removeChild(results.firstChild);

		results.style.display = 'none';
	},

	setQRStatus: function(message, state) {
		const status = document.getElementById('lpac-qr-status');

		if (!status)
			return;

		status.className = state === 'error'
			? 'alert-message error'
			: 'cbi-value-description';
		status.setAttribute('role', state === 'error' ? 'alert' : 'status');
		status.textContent = message || '';
	},

	clearQRResult: function() {
		const activation = document.getElementById('lpac-activation-code');
		const preview = document.getElementById('lpac-qr-preview');

		[ 'lpac-qr-file', 'lpac-qr-camera' ].forEach(function(id) {
			const input = document.getElementById(id);

			if (input)
				input.value = '';
		});

		if (activation && this.qrActivationCode &&
		    activation.value === this.qrActivationCode)
			activation.value = '';

		this.qrActivationCode = null;

		if (preview) {
			preview.removeAttribute('src');
			preview.style.display = 'none';
		}
	},

	handleQRFile: function(input) {
		const file = input.files && input.files[0];

		if (!file)
			return;

		const generation = ++this.qrDecodeGeneration;
		this.clearQRResult();
		this.qrDecoding = true;

		this.updateControls();

		if (file.type && ![ 'image/png', 'image/jpeg', 'image/webp' ].includes(file.type)) {
			input.value = '';
			this.qrDecoding = false;
			this.setQRStatus(_('Select a PNG, JPEG, or WebP image.'), 'error');
			this.updateControls();
			return;
		}

		if (file.size > maxQRFileSize) {
			input.value = '';
			this.qrDecoding = false;
			this.setQRStatus(_('The QR image must not exceed 8 MiB.'), 'error');
			this.updateControls();
			return;
		}

		this.setQRStatus(_('Decoding QR code…'));

		return Promise.all([ loadJsQR(), readImage(file) ]).then(function(values) {
			if (generation !== this.qrDecodeGeneration)
				return;

			const activationCode = decodeImage(values[0], values[1].image);

			if (!activationCode || !validActivationCode(activationCode, '', true))
				throw new Error(_('No valid eSIM activation code was found in the image.'));

			document.getElementById('lpac-activation-code').value = activationCode;
			this.qrActivationCode = activationCode;
			const preview = document.getElementById('lpac-qr-preview');

			preview.src = values[1].dataUrl;
			preview.style.display = 'block';
			this.setQRStatus(
				activationCodeIssue(activationCode, '', false) === 'confirmation_required'
					? _('QR code decoded. Enter the confirmation code required by this profile.')
					: _('QR code decoded. The activation-code field has been filled.'));
		}.bind(this)).catch(function(error) {
			if (generation === this.qrDecodeGeneration) {
				input.value = '';
				this.setQRStatus(error.message, 'error');
			}
		}.bind(this)).finally(function() {
			if (generation === this.qrDecodeGeneration) {
				this.qrDecoding = false;
				this.updateControls();
			}
		}.bind(this));
	},

	clearForm: function() {
		if (this.isBusy())
			return;

		this.qrDecodeGeneration++;
		this.qrDecoding = false;

		[
			'lpac-activation-code', 'lpac-smds', 'lpac-imei',
			'lpac-confirmation-code', 'lpac-qr-file', 'lpac-qr-camera'
		].forEach(function(id) {
			const input = document.getElementById(id);

			if (input)
				input.value = '';
		});

		this.clearQRResult();
		this.clearDiscoveryResults();
		this.setQRStatus('');
		this.updateControls();
	},

	collectRequest: function() {
		const mode = document.getElementById('lpac-download-mode').value;
		const activationInput = document.getElementById('lpac-activation-code');
		const activationCode = normalizeActivationCode(activationInput.value);
		const imei = document.getElementById('lpac-imei').value.trim();
		const confirmationCode = document.getElementById('lpac-confirmation-code').value;

		[
			'lpac-activation-code', 'lpac-confirmation-code', 'lpac-imei'
		].forEach(function(id) {
			document.getElementById(id).removeAttribute('aria-invalid');
		});

		if (mode !== 'activation')
			throw new Error(_('Select a valid download method.'));

		const issue = activationCodeIssue(activationCode, confirmationCode, false);

		if (issue === 'confirmation_required')
			throw validationError(
				_('This activation code requires a confirmation code.'),
				'lpac-confirmation-code');

		if (issue)
			throw validationError(_('Enter a valid LPA:1$… activation code.'),
				'lpac-activation-code');

		activationInput.value = activationCode;

		if (confirmationCode.length > 255 || /[\u0000-\u001F\u007F]/.test(confirmationCode))
			throw validationError(
				_('Confirmation code is too long or contains control characters.'),
				'lpac-confirmation-code');

		if (imei && !/^[0-9]{14,16}$/.test(imei))
			throw validationError(_('IMEI must contain 14 to 16 digits.'), 'lpac-imei');

		return {
			activationCode,
			imei,
			confirmationCode
		};
	},

	collectDiscoveryRequest: function() {
		const smdsInput = document.getElementById('lpac-smds');
		const imeiInput = document.getElementById('lpac-imei');
		const smds = smdsInput.value.trim();
		const imei = imeiInput.value.trim();

		smdsInput.removeAttribute('aria-invalid');
		imeiInput.removeAttribute('aria-invalid');

		if (smds && !lpac.validSmdpAddress(smds))
			throw validationError(_('The SM-DS address is invalid.'), 'lpac-smds');

		if (imei && !/^[0-9]{14,16}$/.test(imei))
			throw validationError(_('IMEI must contain 14 to 16 digits.'), 'lpac-imei');

		return { smds, imei };
	},

	renderDiscoveryResults: function() {
		const container = document.getElementById('lpac-discovery-results');

		if (!container)
			return;

		if (typeof container.replaceChildren === 'function')
			container.replaceChildren();
		else if (Array.isArray(container.children))
			container.children.length = 0;
		else
			while (container.firstChild)
				container.removeChild(container.firstChild);

		this.discoveryButtons = [];
		const content = [ E('h4', {}, [ _('Discovered download orders') ]) ];

		if (!this.discoveryEntries.length) {
			content.push(E('p', {}, [
				_('No pending download orders were returned by the SM-DS.')
			]));
		}
		else {
			content.push(E('p', { 'class': 'cbi-value-description' }, [
				_('SM-DS does not reveal profile names here. Retrieve an order to review its provider metadata before installation.')
			]));

			this.discoveryEntries.forEach(function(entry, index) {
				const button = E('button', {
					'class': 'btn cbi-button cbi-button-positive',
					'type': 'button',
					'disabled': isReadonlyView || this.isBusy(),
					'click': lpac.createStatefulHandler(this,
						'handleDiscoveredDownload', this.reconcileActionControls,
						entry)
				}, [ _('Retrieve preview') ]);

				this.discoveryButtons.push(button);
				content.push(E('div', { 'class': 'cbi-section' }, [
					E('p', {}, [
						E('strong', {}, [ _('Order %d').format(index + 1), ': ' ]),
						entry.smdp
					]),
					button
				]));
			}, this);
		}

		content.forEach(function(node) { container.appendChild(node); });
		container.style.display = '';
	},

	discoveryProgressMessage: function() {
		if (this.activeDiscoveryOrigin === jobOriginOwned)
			return _('Contacting the SM-DS and checking for pending download orders…');

		if (this.activeDiscoveryOrigin === jobOriginUncertain)
			return _('The discovery start response was lost. Monitoring the protected operation before retrying…');

		return _('Another SM-DS discovery is running. Monitoring it before this form can be submitted.');
	},

	attachDiscoveryJob: function(result, origin) {
		const id = result?.data?.job_id;

		if (!result?.success || result.data?.status !== 'running' ||
		    !Number.isInteger(id) || id < 1)
			return false;

		let normalizedOrigin = origin;
		const token = result.data?.owner_token;

		if (origin === jobOriginOwned) {
			if (typeof token !== 'string' || !/^[A-Za-z0-9_-]{32}$/.test(token))
				normalizedOrigin = jobOriginUncertain;
		}

		this.activeDiscoveryJob = id;
		this.activeDiscoveryOrigin = normalizedOrigin;
		this.activeDiscoveryToken = normalizedOrigin === jobOriginOwned ? token : null;
		this.activeDiscoveryPhase = typeof result.data?.phase === 'string'
			? result.data.phase : 'contacting_smds';
		this.discoveryPendingStart = false;
		this.discoveryStatusFailures = 0;
		this.discovering = true;
		this.setDownloadProgress(true, this.discoveryProgressMessage());
		this.updateControls();
		return true;
	},

	validDiscoveryResults: function(result) {
		const entries = result?.data?.results;

		return result?.success === true && result.data?.status === 'success' &&
			result.data?.phase === 'complete' && Array.isArray(entries) &&
			entries.length <= 64 && entries.every(function(entry) {
				return entry && typeof entry.entry_id === 'string' &&
					/^[A-Za-z0-9_-]{32}$/.test(entry.entry_id) &&
					lpac.validSmdpAddress(entry.smdp);
			}) && new Set(entries.map(function(entry) {
				return entry.entry_id;
			})).size === entries.length;
	},

	finishDiscovery: function(result, message, level) {
		const owned = this.activeDiscoveryOrigin === jobOriginOwned;

		this.activeDiscoveryJob = null;
		this.activeDiscoveryOrigin = null;
		this.activeDiscoveryToken = null;
		this.activeDiscoveryPhase = null;
		this.discoveryPendingStart = false;
		this.discoveryStatusFailures = 0;
		this.discovering = false;
		this.setDownloadProgress(false);

		if (owned && this.validDiscoveryResults(result)) {
			this.discoveryEntries = result.data.results.slice();
			this.renderDiscoveryResults();
		}
		else if (result && owned) {
			ui.addNotification(null, E('p', {}, [
				result.success
					? lpac.errorMessage({ error: 'invalid_response' })
					: lpac.errorMessage(result)
			]), result?.reason === 'provider_outcome_unknown' ? 'warning' : 'error');
		}
		else if (message) {
			ui.addNotification(null, E('p', {}, [ message ]), level || 'warning');
		}

		this.updateControls();
	},

	pollDiscovery: function() {
		if (!this.activeDiscoveryJob)
			return Promise.resolve();

		const id = this.activeDiscoveryJob;
		const owned = this.activeDiscoveryOrigin === jobOriginOwned;
		const query = owned
			? lpac.getDiscoveryStatus(id, this.activeDiscoveryToken || '')
			: lpac.getDiscoveryStatus(0, '');

		return query.then(function(result) {
			if (!this.activeDiscoveryJob || this.activeDiscoveryJob !== id)
				return;

			if (result?.error === 'transport_error') {
				this.recordDiscoveryStatusFailure();
				return;
			}

			if (result?.success && result.data?.status === 'running' &&
			    Number.isInteger(result.data?.job_id)) {
				if (result.data.job_id === id) {
					this.discoveryStatusFailures = 0;
					this.activeDiscoveryPhase = typeof result.data.phase === 'string'
						? result.data.phase : this.activeDiscoveryPhase;
					this.setDownloadProgress(true, this.discoveryProgressMessage());
				}
				else {
					this.attachDiscoveryJob(result, jobOriginExternal);
				}
				return;
			}

			if (!owned && result?.success && result.data?.status === 'idle') {
				this.finishDiscovery(null,
					_('The monitored SM-DS discovery ended. Run discovery again in this tab to retrieve protected results.'),
					'warning');
				return;
			}

			if (owned && (this.validDiscoveryResults(result) || result?.success === false)) {
				this.finishDiscovery(result);
				return;
			}

			this.recordDiscoveryStatusFailure();
		}.bind(this)).catch(function() {
			if (this.activeDiscoveryJob === id)
				this.recordDiscoveryStatusFailure();
		}.bind(this));
	},

	recordDiscoveryStatusFailure: function() {
		this.discoveryStatusFailures++;

		if (this.discoveryStatusFailures >= 3)
			this.setDownloadProgress(true,
				_('Connection to the lpac service was lost. Discovery may still be running; status checks will continue automatically.'));
	},

	startDiscovery: function() {
		if (this.isBusy() || this.retryBlocked)
			return;

		let request;

		try {
			request = this.collectDiscoveryRequest();
		}
		catch (error) {
			const input = error.fieldId && document.getElementById(error.fieldId);

			if (input) {
				input.setAttribute('aria-invalid', 'true');
				input.focus();
			}

			ui.addNotification(null, E('p', {}, [ error.message ]), 'error');
			return;
		}

		this.clearDiscoveryResults();
		const generation = this.discoveryGeneration;

		this.discovering = true;
		this.discoveryPendingStart = true;
		this.setDownloadProgress(true,
			_('Contacting the SM-DS and checking for pending download orders…'));
		this.updateControls();

		return lpac.discoverProfiles(request.smds, request.imei).then(function(result) {
			if (generation !== this.discoveryGeneration)
				return;

			if (this.attachDiscoveryJob(result, jobOriginOwned))
				return;

			if (result?.error === 'busy') {
				return lpac.getDiscoveryStatus(0, '').then(function(current) {
					if (!this.attachDiscoveryJob(current, jobOriginExternal))
						throw new Error(lpac.errorMessage(result));
				}.bind(this));
			}

			if (!result || result.error === 'transport_error' || result.success === true) {
				return lpac.getDiscoveryStatus(0, '').then(function(current) {
					if (this.attachDiscoveryJob(current, jobOriginUncertain))
						return;

					throw new Error(lpac.errorMessage(result?.success
						? { error: 'invalid_response' } : result));
				}.bind(this));
			}

			throw new Error(lpac.errorMessage(result));
		}.bind(this)).catch(function(error) {
			if (generation === this.discoveryGeneration) {
				this.activeDiscoveryJob = null;
				this.activeDiscoveryOrigin = null;
				this.activeDiscoveryToken = null;
				this.activeDiscoveryPhase = null;
				this.discoveryPendingStart = false;
				this.discovering = false;
				this.setDownloadProgress(false);
				this.updateControls();
				ui.addNotification(null, E('p', {}, [ error.message ]), 'error');
			}
		}.bind(this));
	},

	handleDiscoveredDownload: function(entry) {
		if (this.isBusy() || this.retryBlocked || !entry ||
		    !this.discoveryEntries.some(function(candidate) {
			return candidate.entry_id === entry.entry_id;
		}))
			return;

		const confirmationCode = document.getElementById(
			'lpac-confirmation-code').value;

		if (confirmationCode.length > 255 ||
		    /[\u0000-\u001F\u007F]/.test(confirmationCode)) {
			ui.addNotification(null, E('p', {}, [
				_('Confirmation code is too long or contains control characters.')
			]), 'error');
			return;
		}

		return this.startDiscoveredDownload(entry, confirmationCode);
	},

	handlePrimaryAction: function() {
		const mode = document.getElementById('lpac-download-mode').value;

		return mode === 'discovery'
			? this.startDiscovery()
			: this.startValidatedDownload();
	},

	startValidatedDownload: function() {
		if (this.isBusy())
			return;

		if (this.retryBlocked) {
			ui.addNotification(null, E('p', {}, [ lpac.errorMessage({
				error: 'execution_failed',
				reason: 'outcome_unknown'
			}) ]), 'error');
			return;
		}

		if (this.qrDecoding) {
			ui.addNotification(null, E('p', {}, [
				_('Wait for the selected QR image to finish decoding.')
			]), 'warning');
			return;
		}

		let request;

		try {
			request = this.collectRequest();
		}
		catch (error) {
			const input = error.fieldId && document.getElementById(error.fieldId);

			if (input) {
				input.setAttribute('aria-invalid', 'true');
				input.focus();
			}

			ui.addNotification(null, E('p', {}, [ error.message ]), 'error');
			return;
		}

		return this.startDownload(request);
	},

	startDownload: function(request) {
		return this.startDownloadOperation(function() {
			return lpac.downloadProfile(
				request.activationCode,
				request.imei,
				request.confirmationCode
			);
		}, null, activationServer(request.activationCode));
	},

	startDiscoveredDownload: function(entry, confirmationCode) {
		return this.startDownloadOperation(function() {
			return lpac.downloadDiscoveredProfile(entry.entry_id, confirmationCode);
		}, this.clearDiscoveryResults.bind(this), entry.smdp);
	},

	startDownloadOperation: function(operation, startedCallback, smdp) {
		if (this.activeJob || this.downloadStarting || this.checkingCurrentJob ||
		    this.qrDecoding || this.retryBlocked)
			return;

		this.downloadStarting = true;
		this.pendingStartResult = null;
		this.activeDecisionToken = null;
		this.activePhase = null;
		this.activeSmdp = smdp || null;
		this.previewDecisionSent = false;
		this.previewModalJob = null;
		ui.hideModal();
		this.setDownloadProgress(true, _('Starting the protected lpac preview session…'));
		this.updateControls();

		return operation().then(function(result) {
			if (this.attachRunningJob(result, jobOriginOwned)) {
				if (startedCallback)
					startedCallback();
				return;
			}

			if (result?.error === 'busy') {
				return lpac.getDownloadStatus(0, '').then(function(current) {
					this.applyDownloadSafety(current);

					if (!this.attachRunningJob(current, jobOriginExternal))
						throw new Error(lpac.errorMessage(result));
				}.bind(this), function() {
					throw new Error(lpac.errorMessage(result));
				});
			}

			if (result?.error === 'retry_blocked') {
				return lpac.getDownloadStatus(0, '').then(function(current) {
					this.applyDownloadSafety(current);
					throw new Error(lpac.errorMessage(result));
				}.bind(this));
			}

			const recoverable = !result || result.error === 'transport_error' ||
				result.success === true;

			if (!recoverable) {
				if (result?.error === 'entry_unavailable')
					this.clearDiscoveryResults();

				throw new Error(lpac.errorMessage(result));
			}

			this.pendingStartResult = result || {
				success: false,
				error: 'transport_error'
			};

			return lpac.getDownloadStatus(0, '').then(function(current) {
				this.applyDownloadSafety(current);

				if (this.attachRunningJob(current, jobOriginUncertain))
					return;

				if (isIdleDownloadStatus(current)) {
					this.finishDownload({
						success: false,
						error: 'execution_failed',
						reason: 'outcome_unknown'
					});
					return;
				}

				this.recordStatusFailure();
				this.setDownloadProgress(true,
					_('The start response was lost. Checking whether lpac is still running…'));
			}.bind(this));
		}.bind(this)).catch(function(error) {
			this.downloadStarting = false;
			this.activeJob = null;
			this.activeJobOrigin = null;
			this.activeDecisionToken = null;
			this.activePhase = null;
			this.activeSmdp = null;
			this.checkingCurrentJob = false;
			this.pendingStartResult = null;
			this.setDownloadProgress(false);
			this.updateControls();
			ui.addNotification(null, E('p', {}, [ error.message ]), 'error');
		}.bind(this));
	},

	recordStatusFailure: function() {
		this.statusFailures++;

		if (this.statusFailures >= 3)
			this.setDownloadProgress(true,
				_('Connection to the lpac service was lost. The download may still be running; status checks will continue automatically.'));
	},

	finishDownload: function(result) {
		this.applyDownloadSafety(result);

		const terminalStatus = result?.success ? result.data?.status : null;
		const origin = this.activeJobOrigin || (this.pendingStartResult !== null
			? jobOriginUncertain
			: jobOriginExternal);
		const ownedOutcomeUnknown = origin === jobOriginOwned &&
			(result?.reason === 'outcome_unknown' || result?.error === 'job_not_found');
		const verificationRequired = this.retryBlocked ||
			origin === jobOriginUncertain || ownedOutcomeUnknown;

		this.activeJob = null;
		this.activeJobOrigin = null;
		this.activeDecisionToken = null;
		this.activePhase = null;
		this.activeSmdp = null;
		this.downloadStarting = false;
		this.checkingCurrentJob = false;
		this.previewDecisionSent = false;

		if (this.previewModalJob !== null)
			ui.hideModal();

		this.previewModalJob = null;
		this.statusFailures = 0;
		this.pendingStartResult = null;
		this.retryBlocked = verificationRequired;
		this.setDownloadProgress(false);
		this.setVerificationRequired(this.retryBlocked);

		if (origin === jobOriginExternal) {
			this.updateControls();
			ui.addNotification(null, E('p', {}, [ this.retryBlocked
				? lpac.errorMessage({
					success: false,
					error: 'execution_failed',
					reason: 'outcome_unknown'
				})
				: _('The existing profile download ended. This form was not submitted; review Profiles and Notifications before continuing.')
			]), this.retryBlocked || !result?.success ? 'warning' : 'info');
		}
		else if (origin === jobOriginUncertain) {
			this.updateControls();
			ui.addNotification(null, E('p', {}, [ lpac.errorMessage({
				success: false,
				error: 'execution_failed',
				reason: 'outcome_unknown'
			}) ]), 'warning');
		}
		else if (terminalStatus === 'success') {
			this.clearForm();
			ui.addNotification(null, E('p', {}, [
				_('The eSIM profile was downloaded successfully. Open Profiles to verify and manage it.')
			]), 'info');
		}
		else if (terminalStatus === 'cancelled') {
			this.updateControls();
			ui.addNotification(null, E('p', {}, [
				_('The profile download was cancelled before installation.')
			]), 'info');
		}
		else {
			this.updateControls();
			ui.addNotification(null, E('p', {}, [
				result?.success
					? lpac.errorMessage({ error: 'invalid_response' })
					: lpac.errorMessage(result)
			]), 'error');
		}
	},

	pollDownload: function() {
		if (this.checkingCurrentJob) {
			return lpac.getDownloadStatus(0, '').then(function(current) {
				this.applyDownloadSafety(current);

				if (this.attachRunningJob(current, jobOriginExternal))
					return;

				if (!isIdleDownloadStatus(current)) {
					this.recordStatusFailure();
					return;
				}

				this.checkingCurrentJob = false;
				this.statusFailures = 0;
				this.setDownloadProgress(false);
				this.updateControls();
			}.bind(this)).catch(function() {
				this.recordStatusFailure();
			}.bind(this));
		}

		if (!this.activeJob && (!this.downloadStarting || !this.pendingStartResult))
			return Promise.resolve();

		if (!this.activeJob) {
			return lpac.getDownloadStatus(0, '').then(function(current) {
				this.applyDownloadSafety(current);

				if (this.attachRunningJob(current, jobOriginUncertain))
					return;

				if (!isIdleDownloadStatus(current)) {
					this.recordStatusFailure();
					return;
				}

				this.finishDownload({
					success: false,
					error: 'execution_failed',
					reason: 'outcome_unknown'
				});
			}.bind(this)).catch(function() {
				this.recordStatusFailure();
			}.bind(this));
		}

		const jobId = this.activeJob;

		return lpac.getDownloadStatus(jobId,
			this.activeDecisionToken || '').then(function(result) {
			if (this.activeJob !== jobId)
				return;

			this.applyDownloadSafety(result);

			if (result && result.success && result.data?.status === 'running' &&
			    result.data?.job_id === jobId) {
				this.statusFailures = 0;
				this.handlePreviewState(result);
				this.setDownloadProgress(true, this.runningJobMessage());
				return;
			}

			if (result?.error === 'transport_error') {
				this.recordStatusFailure();
				return;
			}

			if (result?.error === 'job_not_found') {
				const missingOrigin = this.activeJobOrigin;

				if (this.previewModalJob !== null)
					ui.hideModal();

				this.previewModalJob = null;
				this.previewDecisionSent = true;

				return lpac.getDownloadStatus(0, '').then(function(current) {
					if (this.activeJob !== jobId)
						return;

					this.applyDownloadSafety(current);

					if (this.attachRunningJob(current, jobOriginExternal)) {
						if (missingOrigin !== jobOriginExternal) {
							this.retryBlocked = true;
							this.setVerificationRequired(true);
							this.updateControls();
						}

						return;
					}

					if (!isIdleDownloadStatus(current)) {
						this.recordStatusFailure();
						return;
					}

					this.finishDownload(result);
				}.bind(this));
			}

			if (!isTerminalDownloadStatus(result)) {
				this.recordStatusFailure();
				return;
			}

			this.finishDownload(result);
		}.bind(this)).catch(function() {
			/* Keep polling: the supervised lpac process may still be running. */
			if (this.activeJob === jobId)
				this.recordStatusFailure();
		}.bind(this));
	},

	pollOperations: function() {
		return Promise.all([ this.pollDownload(), this.pollDiscovery() ]);
	},

	render: function(initialStatus) {
		this.applyDownloadSafety(initialStatus, false);

		if (!this.attachRunningJob(initialStatus, jobOriginExternal) &&
		    !isIdleDownloadStatus(initialStatus)) {
			this.checkingCurrentJob = true;
			this.statusFailures = 1;
		}

		if (!this.pollRegistered) {
			poll.add(this.pollOperations.bind(this), 2);
			this.pollRegistered = true;
		}

		const controlsDisabled = isReadonlyView || this.isBusy() || null;
		const mode = E('select', {
			'id': 'lpac-download-mode',
			'class': 'cbi-input-select',
			'disabled': controlsDisabled,
			'change': this.handleModeChange.bind(this)
		}, [
			E('option', { 'value': 'activation', 'selected': '' }, [
				_('Activation code or QR')
			]),
			E('option', { 'value': 'discovery' }, [ _('SM-DS discovery') ])
		]);
		const makeQRInput = function(id, capture) {
			return E('input', {
				'id': id,
				'type': 'file',
				'accept': 'image/png,image/jpeg,image/webp',
				'capture': capture || null,
				'disabled': controlsDisabled,
				'style': 'display:none',
				'change': function(event) {
					return this.handleQRFile(event.currentTarget);
				}.bind(this)
			});
		}.bind(this);
		const qrFile = makeQRInput('lpac-qr-file');
		const qrCamera = makeQRInput('lpac-qr-camera', 'environment');
		const activationInput = textInput('lpac-activation-code', 'password',
			'LPA:1$smdp.example.com$MATCHING-ID', 4096, controlsDisabled,
			this.handleActivationInput.bind(this));

		activationInput.setAttribute('aria-describedby', 'lpac-qr-status');

		const pickerButton = function(id, label, input) {
			return E('button', {
				'id': id,
				'class': 'btn cbi-button cbi-button-neutral',
				'type': 'button',
				'disabled': controlsDisabled,
				'click': function(event) {
					if (event)
						event.preventDefault();

					this.openQRPicker(input);
				}.bind(this)
			}, [ label ]);
		}.bind(this);
		const hasActiveDownload = !!this.activeJob;
		const hasProgress = hasActiveDownload || this.checkingCurrentJob ||
			this.discovering;
		const verificationButton = E('button', {
			'id': 'lpac-download-acknowledge',
			'class': 'btn cbi-button cbi-button-neutral',
			'type': 'button',
			'disabled': isReadonlyView || this.verificationAcknowledging ||
				!this.retryBlocked || !this.verificationIncident ||
				!this.verificationProfilesRefreshed ||
				!this.verificationNotificationsRefreshed || null,
			'click': lpac.createStatefulHandler(this,
				'acknowledgeDownloadVerification', this.reconcileActionControls)
		}, [ _('Acknowledge verification') ]);

		this.verificationButton = verificationButton;

		return E([
			E('h2', {}, [ _('Download eSIM profile') ]),
			E('div', { 'class': 'cbi-map-descr' }, [
				_('Find and install profiles through SM-DS discovery, a complete LPA activation code, or a locally decoded QR image. Every download pauses for provider-metadata review before installation.')
			]),
			E('div', {
				'id': 'lpac-download-progress',
				'class': 'alert-message notice',
				'role': 'status',
				'aria-live': 'polite',
				'style': hasProgress ? '' : 'display:none'
			}, [
				E('span', { 'class': 'spinning' }),
				' ',
				E('span', { 'id': 'lpac-download-progress-text' }, [
					this.discovering
						? _('Contacting the SM-DS and checking for pending download orders…')
						: this.checkingCurrentJob
						? _('Unable to confirm whether a profile download is already running. Retrying automatically…')
						: (hasActiveDownload
							? _('Another profile download is running. Monitoring it before this form can be submitted.')
							: '')
				])
			]),
			E('div', {
				'id': 'lpac-download-verification',
				'class': 'alert-message warning',
				'role': 'alert',
				'style': this.retryBlocked ? '' : 'display:none'
			}, [
				_('The previous download outcome is unknown. Open Profiles and Notifications before returning here to retry.'),
				' ',
				_('After both pages have refreshed successfully, acknowledge the verification to enable another download.'),
				' ',
				verificationButton
			]),
			E('div', { 'class': 'cbi-section' }, [
				E('h3', {}, [ _('Download method') ]),
				formRow(_('Method'), mode)
			]),
			E('div', { 'id': 'lpac-download-activation-fields' }, [
				E('div', { 'class': 'cbi-section' }, [
					E('h3', {}, [ _('Activation code') ]),
					formRow(_('LPA string'), activationInput,
						_('Paste the complete LPA string supplied by the provider.')),
					formRow(_('QR image'), E('div', {}, [
						qrFile,
						qrCamera,
						pickerButton('lpac-qr-file-button', _('Choose QR image'), qrFile),
						' ',
						pickerButton('lpac-qr-camera-button', _('Take QR photo'), qrCamera)
					]),
					_('Choose an existing QR image or take a new photo. Decoding happens locally in this browser.')),
					E('div', { 'class': 'cbi-value' }, [
						E('div', { 'class': 'cbi-value-title' }),
						E('div', { 'class': 'cbi-value-field' }, [
							E('img', {
								'id': 'lpac-qr-preview',
								'alt': _('Selected QR image preview'),
								'style': 'display:none;max-width:100%;max-height:12rem'
							}),
							E('div', {
								'id': 'lpac-qr-status',
								'class': 'cbi-value-description',
								'role': 'status',
								'aria-live': 'polite'
							})
						])
					])
				])
			]),
			E('div', { 'id': 'lpac-download-discovery-fields', 'style': 'display:none' }, [
				E('div', { 'class': 'cbi-section' }, [
					E('h3', {}, [ _('SM-DS discovery') ]),
					formRow(_('SM-DS address'),
						textInput('lpac-smds', 'text', 'lpa.ds.gsma.com', 255,
							controlsDisabled, this.clearDiscoveryResults.bind(this)),
						_('Optional. When empty, lpac uses the GSMA discovery service lpa.ds.gsma.com.')),
					E('p', { 'class': 'cbi-value-description', 'role': 'note' }, [
						_('Discovered EventIDs remain only in expiring backend memory. LuCI receives opaque entry identifiers and never stores those matching credentials in the browser.')
					])
				]),
				E('div', {
					'id': 'lpac-discovery-results',
					'role': 'region',
					'aria-live': 'polite',
					'style': 'display:none'
				})
			]),
			E('div', { 'class': 'cbi-section' }, [
				E('h3', {}, [ _('Additional parameters') ]),
				formRow(_('Confirmation code'),
					textInput('lpac-confirmation-code', 'password', _('Optional'), 255,
						controlsDisabled),
					_('Provide this when the activation code or download order requires confirmation.')),
				formRow(_('IMEI'),
					textInput('lpac-imei', 'text', _('Optional'), 16,
						controlsDisabled, this.clearDiscoveryResults.bind(this)),
					_('Optional 14- to 16-digit device identifier passed to lpac with -i.'))
			]),
			E('div', { 'class': 'cbi-page-actions' }, [
				E('button', {
					'id': 'lpac-download-clear',
					'class': 'btn cbi-button cbi-button-reset',
					'type': 'button',
					'disabled': controlsDisabled,
					'click': ui.createHandlerFn(this, 'clearForm')
				}, [ _('Clear') ]),
				' ',
				E('button', {
					'id': 'lpac-download-button',
					'class': 'btn cbi-button cbi-button-positive important',
					'type': 'button',
					'disabled': controlsDisabled || this.qrDecoding ||
						this.retryBlocked || null,
					'click': lpac.createStatefulHandler(this,
						'handlePrimaryAction', this.reconcileActionControls)
				}, [ _('Retrieve profile preview') ])
			])
		]);
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
