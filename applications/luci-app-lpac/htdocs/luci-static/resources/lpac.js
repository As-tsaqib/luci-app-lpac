// SPDX-License-Identifier: Apache-2.0

'use strict';
'require rpc';
'require baseclass';

const callGetVersion = rpc.declare({
	object: 'luci.lpac',
	method: 'get_version',
	expect: {}
});

const callGetDrivers = rpc.declare({
	object: 'luci.lpac',
	method: 'get_drivers',
	expect: {}
});

const callGetInfo = rpc.declare({
	object: 'luci.lpac',
	method: 'get_info',
	expect: {}
});

const callSetDefaultSmdp = rpc.declare({
	object: 'luci.lpac',
	method: 'set_default_smdp',
	params: [ 'address' ],
	expect: {}
});

const callListProfiles = rpc.declare({
	object: 'luci.lpac',
	method: 'list_profiles',
	expect: {}
});

const callListNotifications = rpc.declare({
	object: 'luci.lpac',
	method: 'list_notifications',
	expect: {}
});

const callDiscoverProfiles = rpc.declare({
	object: 'luci.lpac',
	method: 'discover_profiles',
	params: [ 'smds', 'imei' ],
	expect: {}
});

const callDownloadProfile = rpc.declare({
	object: 'luci.lpac',
	method: 'download_profile',
	params: [
		'mode', 'activation_code', 'smdp', 'matching_id', 'imei',
		'confirmation_code'
	],
	expect: {}
});

const callGetDownloadStatus = rpc.declare({
	object: 'luci.lpac',
	method: 'get_download_status',
	params: [ 'job_id', 'decision_token' ],
	expect: {}
});

const callDownloadDiscoveredProfile = rpc.declare({
	object: 'luci.lpac',
	method: 'download_discovered_profile',
	params: [ 'entry_id', 'confirmation_code' ],
	expect: {}
});

const callRespondDownloadPreview = rpc.declare({
	object: 'luci.lpac',
	method: 'respond_download_preview',
	params: [ 'job_id', 'decision_token', 'accept' ],
	expect: {}
});

const callEnableProfile = rpc.declare({
	object: 'luci.lpac',
	method: 'enable_profile',
	params: [ 'iccid', 'refresh' ],
	expect: {}
});

const callDisableProfile = rpc.declare({
	object: 'luci.lpac',
	method: 'disable_profile',
	params: [ 'iccid', 'refresh' ],
	expect: {}
});

const callNicknameProfile = rpc.declare({
	object: 'luci.lpac',
	method: 'nickname_profile',
	params: [ 'iccid', 'nickname' ],
	expect: {}
});

const callDeleteProfile = rpc.declare({
	object: 'luci.lpac',
	method: 'delete_profile',
	params: [ 'iccid' ],
	expect: {}
});

const callRemoveNotification = rpc.declare({
	object: 'luci.lpac',
	method: 'remove_notification',
	params: [ 'seq' ],
	expect: {}
});

const callProcessNotification = rpc.declare({
	object: 'luci.lpac',
	method: 'process_notification',
	params: [ 'seq', 'remove_after_success' ],
	expect: {}
});

const callGetConfig = rpc.declare({
	object: 'luci.lpac',
	method: 'get_config',
	expect: {}
});

const callSetConfig = rpc.declare({
	object: 'luci.lpac',
	method: 'set_config',
	params: [ 'config' ],
	expect: {}
});

const downloadVerificationStoragePrefix = 'luci.lpac.download-verification.v1';
const downloadVerificationStorageKey =
	`${downloadVerificationStoragePrefix}.marker`;
const downloadVerificationProfilesKey =
	`${downloadVerificationStoragePrefix}.profiles`;
const downloadVerificationNotificationsKey =
	`${downloadVerificationStoragePrefix}.notifications`;
const downloadVerificationStorageProbeKey =
	`${downloadVerificationStoragePrefix}.probe`;
let downloadVerificationStorage;
let downloadVerificationFallback = null;
let downloadVerificationSequence = 0;

function newDownloadVerificationMarker(phase) {
	downloadVerificationSequence++;

	return {
		version: 1,
		phase,
		generation: [
			Date.now().toString(36),
			downloadVerificationSequence.toString(36),
			Math.random().toString(36).slice(2, 14)
		].join('-')
	};
}

function copyDownloadVerification(state) {
	return state ? {
		marker: {
			version: state.marker.version,
			phase: state.marker.phase,
			generation: state.marker.generation
		},
		profiles: state.profiles,
		notifications: state.notifications
	} : null;
}

function validDownloadVerificationMarker(marker) {
	if (!marker || Array.isArray(marker) || marker.version !== 1 ||
	    ![ 'pending', 'verify' ].includes(marker.phase) ||
	    typeof marker.generation !== 'string' ||
	    !/^[a-z0-9-]{3,80}$/.test(marker.generation))
		return false;

	const keys = Object.keys(marker).sort();

	return keys.join(',') === 'generation,phase,version';
}

function getDownloadVerificationStorage() {
	if (downloadVerificationStorage !== undefined)
		return downloadVerificationStorage;

	try {
		const storage = window.localStorage;
		const previous = storage.getItem(downloadVerificationStorageProbeKey);

		storage.setItem(downloadVerificationStorageProbeKey, '1');

		if (previous === null)
			storage.removeItem(downloadVerificationStorageProbeKey);
		else
			storage.setItem(downloadVerificationStorageProbeKey, previous);

		downloadVerificationStorage = storage;
	}
	catch (error) {
		downloadVerificationStorage = null;
	}

	return downloadVerificationStorage;
}

function storeDownloadVerificationMarker(marker) {
	const storage = getDownloadVerificationStorage();
	const state = {
		marker,
		profiles: false,
		notifications: false
	};

	downloadVerificationFallback = copyDownloadVerification(state);

	if (!storage)
		return copyDownloadVerification(downloadVerificationFallback);

	try {
		storage.setItem(downloadVerificationStorageKey,
			JSON.stringify(marker));
		storage.removeItem(downloadVerificationStoragePrefix);
		storage.removeItem(downloadVerificationProfilesKey);
		storage.removeItem(downloadVerificationNotificationsKey);
	}
	catch (error) {
		downloadVerificationStorage = null;
	}

	return copyDownloadVerification(downloadVerificationFallback);
}

function loadDownloadVerification() {
	const storage = getDownloadVerificationStorage();

	if (!storage) {
		if (!downloadVerificationFallback)
			downloadVerificationFallback = {
				marker: newDownloadVerificationMarker('verify'),
				profiles: false,
				notifications: false
			};

		return copyDownloadVerification(downloadVerificationFallback);
	}

	let marker;

	try {
		const serialized = storage.getItem(downloadVerificationStorageKey);

		if (serialized === null) {
			if (storage.getItem(downloadVerificationStoragePrefix) !== null ||
			    storage.getItem(downloadVerificationProfilesKey) !== null ||
			    storage.getItem(downloadVerificationNotificationsKey) !== null)
				return storeDownloadVerificationMarker(
					newDownloadVerificationMarker('verify'));

			downloadVerificationFallback = null;
			return null;
		}

		marker = JSON.parse(serialized);

		if (!validDownloadVerificationMarker(marker))
			throw new Error('invalid download verification marker');
	}
	catch (error) {
		/* Never trust or echo corrupt browser storage; replace it fail-closed. */
		return storeDownloadVerificationMarker(
			newDownloadVerificationMarker('verify'));
	}

	try {
		const profiles = storage.getItem(downloadVerificationProfilesKey);
		const notifications = storage.getItem(downloadVerificationNotificationsKey);
		const state = {
			marker,
			profiles: profiles === marker.generation,
			notifications: notifications === marker.generation
		};

		downloadVerificationFallback = copyDownloadVerification(state);
		return copyDownloadVerification(state);
	}
	catch (error) {
		downloadVerificationStorage = null;
		downloadVerificationFallback = {
			marker,
			profiles: false,
			notifications: false
		};

		return copyDownloadVerification(downloadVerificationFallback);
	}
}

function storeDownloadVerificationView(state, viewName) {
	const storage = getDownloadVerificationStorage();
	const key = viewName === 'profiles'
		? downloadVerificationProfilesKey
		: downloadVerificationNotificationsKey;

	state[viewName] = true;
	downloadVerificationFallback = copyDownloadVerification(state);

	if (!storage)
		return copyDownloadVerification(state);

	try {
		/* A stale view can write only its old generation, never a newer marker. */
		storage.setItem(key, state.marker.generation);
		return loadDownloadVerification();
	}
	catch (error) {
		downloadVerificationStorage = null;
		return copyDownloadVerification(downloadVerificationFallback);
	}
}

function publicDownloadVerification(state) {
	const storageAvailable = getDownloadVerificationStorage() !== null;
	const verified = state?.marker.phase === 'verify' &&
		state.profiles && state.notifications;

	return {
		required: state !== null && (!storageAvailable || !verified),
		pending: state?.marker.phase === 'pending',
		profiles: state?.profiles === true,
		notifications: state?.notifications === true,
		storageAvailable
	};
}

function safeCall(call) {
	return function() {
		return call.apply(null, arguments).catch(function() {
			return {
				success: false,
				error: 'transport_error'
			};
		});
	};
}

function validIpv4Host(value) {
	const octets = value.split('.');

	return octets.length === 4 && octets.every(function(octet) {
		return /^(0|[1-9][0-9]{0,2})$/.test(octet) && Number(octet) <= 255;
	});
}

function validIpv6Host(value) {
	if (!value.includes(':') || value.indexOf('::') !== value.lastIndexOf('::'))
		return false;

	const compressed = value.includes('::');
	const halves = compressed ? value.split('::') : [ value ];
	let groups = [];

	halves.forEach(function(half) {
		if (half.length)
			groups = groups.concat(half.split(':'));
	});

	let groupCount = groups.length;
	const ipv4 = groups.length && groups[groups.length - 1].includes('.');

	if (ipv4) {
		if (!validIpv4Host(groups.pop()))
			return false;

		groupCount++;
	}

	if (!groups.every(function(group) {
		return /^[0-9A-Fa-f]{1,4}$/.test(group);
	}))
		return false;

	return compressed ? groupCount < 8 : groupCount === 8;
}

function validSmdpAddress(value) {
	if (typeof value !== 'string' || !value.length || value.length > 255 ||
	    /[\s\u0000-\u001F\u007F]/.test(value))
		return false;

	const ipv6 = value.match(/^\[([0-9A-Fa-f:.]+)\](?::([0-9]{1,5}))?$/);

	if (ipv6) {
		if (!validIpv6Host(ipv6[1]))
			return false;

		if (ipv6[2]) {
			const port = Number(ipv6[2]);

			if (port < 1 || port > 65535)
				return false;
		}

		return true;
	}

	const parsed = value.match(/^([A-Za-z0-9.-]+)(?::([0-9]{1,5}))?$/);

	if (!parsed || parsed[1].length > 253 || parsed[1].startsWith('.') ||
	    parsed[1].endsWith('.'))
		return false;

	if (parsed[2]) {
		const port = Number(parsed[2]);

		if (port < 1 || port > 65535)
			return false;
	}

	const host = parsed[1];

	if (/^[0-9.]+$/.test(host))
		return validIpv4Host(host);

	return host.split('.').every(function(label) {
		return label.length >= 1 && label.length <= 63 &&
			/^[A-Za-z0-9-]+$/.test(label) &&
			!label.startsWith('-') && !label.endsWith('-');
	});
}

function iconByteAt(value, offset) {
	return value.charCodeAt(offset) & 0xff;
}

function pngIconDimensions(value) {
	if (value.length < 24 ||
	    iconByteAt(value, 0) !== 0x89 || value.slice(1, 4) !== 'PNG' ||
	    iconByteAt(value, 4) !== 0x0d || iconByteAt(value, 5) !== 0x0a ||
	    iconByteAt(value, 6) !== 0x1a || iconByteAt(value, 7) !== 0x0a ||
	    value.slice(12, 16) !== 'IHDR')
		return null;

	return {
		width: iconByteAt(value, 16) * 0x1000000 +
			iconByteAt(value, 17) * 0x10000 +
			iconByteAt(value, 18) * 0x100 + iconByteAt(value, 19),
		height: iconByteAt(value, 20) * 0x1000000 +
			iconByteAt(value, 21) * 0x10000 +
			iconByteAt(value, 22) * 0x100 + iconByteAt(value, 23)
	};
}

function jpegIconDimensions(value) {
	if (value.length < 4 || iconByteAt(value, 0) !== 0xff ||
	    iconByteAt(value, 1) !== 0xd8 || iconByteAt(value, 2) !== 0xff)
		return null;

	const startOfFrame = [
		0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7,
		0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf
	];
	let offset = 2;

	while (offset + 4 <= value.length) {
		while (offset < value.length && iconByteAt(value, offset) === 0xff)
			offset++;

		if (offset >= value.length)
			return null;

		const marker = iconByteAt(value, offset++);

		if (marker === 0xd9 || marker === 0xda)
			return null;

		if (marker === 0x01 || (marker >= 0xd0 && marker <= 0xd7))
			continue;

		if (offset + 2 > value.length)
			return null;

		const segmentLength = iconByteAt(value, offset) * 0x100 +
			iconByteAt(value, offset + 1);

		if (segmentLength < 2 || offset + segmentLength > value.length)
			return null;

		if (startOfFrame.includes(marker)) {
			if (segmentLength < 7)
				return null;

			return {
				height: iconByteAt(value, offset + 3) * 0x100 +
					iconByteAt(value, offset + 4),
				width: iconByteAt(value, offset + 5) * 0x100 +
					iconByteAt(value, offset + 6)
			};
		}

		offset += segmentLength;
	}

	return null;
}

function profileIconUri(icon) {
	if (!icon || ![ 'image/png', 'image/jpeg' ].includes(icon.mime) ||
	    typeof icon.data !== 'string' || !icon.data.length ||
	    icon.data.length > 1368 || icon.data.length % 4 !== 0 ||
	    !/^[A-Za-z0-9+/]+={0,2}$/.test(icon.data))
		return null;

	let decoded;

	try {
		decoded = window.atob(icon.data);
	}
	catch (error) {
		return null;
	}

	if (!decoded.length || decoded.length > 1024)
		return null;

	const dimensions = icon.mime === 'image/png'
		? pngIconDimensions(decoded)
		: jpegIconDimensions(decoded);

	if (!dimensions || dimensions.width < 1 || dimensions.height < 1 ||
	    dimensions.width > 64 || dimensions.height > 64)
		return null;

	return `data:${icon.mime};base64,${icon.data}`;
}

return baseclass.extend({
	getVersion: safeCall(callGetVersion),
	getDrivers: safeCall(callGetDrivers),
	getInfo: safeCall(callGetInfo),
	setDefaultSmdp: safeCall(callSetDefaultSmdp),
	listProfiles: safeCall(callListProfiles),
	listNotifications: safeCall(callListNotifications),
	discoverProfiles: safeCall(callDiscoverProfiles),
	downloadProfile: safeCall(callDownloadProfile),
	downloadDiscoveredProfile: safeCall(callDownloadDiscoveredProfile),
	getDownloadStatus: safeCall(callGetDownloadStatus),
	respondDownloadPreview: safeCall(callRespondDownloadPreview),
	enableProfile: safeCall(callEnableProfile),
	disableProfile: safeCall(callDisableProfile),
	nicknameProfile: safeCall(callNicknameProfile),
	deleteProfile: safeCall(callDeleteProfile),
	processNotification: safeCall(callProcessNotification),
	removeNotification: safeCall(callRemoveNotification),
	getConfig: safeCall(callGetConfig),
	setConfig: safeCall(callSetConfig),
	validSmdpAddress,
	profileIconUri,

	downloadVerificationStorageKey,
	downloadVerificationStoragePrefix,

	getDownloadVerification: function() {
		return publicDownloadVerification(loadDownloadVerification());
	},

	requireDownloadVerification: function() {
		return publicDownloadVerification(
			storeDownloadVerificationMarker(
				newDownloadVerificationMarker('pending')));
	},

	settleDownloadVerification: function() {
		const state = loadDownloadVerification();
		const marker = state ? {
			version: 1,
			phase: 'verify',
			generation: state.marker.generation
		} : newDownloadVerificationMarker('verify');

		return publicDownloadVerification(
			storeDownloadVerificationMarker(marker));
	},

	markDownloadVerification: function(viewName) {
		const state = loadDownloadVerification();

		if (!state || state.marker.phase !== 'verify' ||
		    ![ 'profiles', 'notifications' ].includes(viewName))
			return publicDownloadVerification(state);

		return publicDownloadVerification(
			storeDownloadVerificationView(state, viewName));
	},

	errorMessage: function(result) {
		if (!result)
			return _('No response from the lpac service.');

		if (result.reason === 'outcome_unknown')
			return _('The profile download outcome is unknown. Refresh Profiles and Notifications before retrying so that the same activation code is not submitted twice.');

		if (result.reason === 'preview_timeout')
			return _('The profile preview expired without a decision and was cancelled before installation.');

		if (result.reason === 'preview_protocol_error')
			return _('lpac could not complete the protected profile-preview exchange. The profile was not approved for installation.');

		switch (result.error) {
		case 'busy':
			return _('Another lpac operation is already running.');
		case 'invalid_argument':
			return _('The request contains an invalid argument.');
		case 'invalid_config':
			return _('The lpac configuration is invalid.');
		case 'job_not_found':
			return _('The profile download job is no longer available. Refresh Profiles and Notifications before retrying.');
		case 'entry_unavailable':
			return _('The discovered order expired or was already used. Run SM-DS discovery again.');
		case 'not_installed':
			return _('The lpac executable is not installed.');
		case 'preview_timeout':
			return _('The profile preview expired without a decision and was cancelled before installation.');
		case 'timeout':
			return _('The lpac operation timed out.');
		case 'output_too_large':
			return _('The lpac output exceeded the RPC response limit.');
		case 'execution_failed':
			return _('The lpac process could not be executed.');
		case 'lock_failed':
			return _('The lpac operation lock could not be created.');
		case 'config_write_failed':
			return _('The lpac configuration could not be saved.');
		case 'transport_error':
			return _('The lpac RPC request failed or timed out.');
		case 'lpac_error':
			switch (result.reason) {
			case 'download_failed':
				return _('lpac could not download the profile. Verify the activation details, network connection, and provider service.');
			case 'notification_retrieve_failed':
				return _('lpac could not retrieve this notification from the eUICC. Refresh the notification list before retrying.');
			case 'provider_outcome_unknown':
				return _('The provider notification outcome is unknown. Do not send it again automatically; refresh the list and review it first.');
			case 'provider_processed_remove_failed':
				return _('The provider accepted the notification, but lpac could not remove its local eUICC record. Use Remove instead of processing it again.');
			case 'profile_not_found':
				return _('lpac could not find that profile identifier. Try the other identifier if available.');
			case 'profile_not_disabled':
				return _('The profile is not in the disabled state required for enabling.');
			case 'profile_not_enabled':
				return _('The profile is not in the enabled state required for disabling.');
			case 'policy_denied':
				return _('The eUICC profile policy rejected this operation.');
			case 'wrong_reenable':
				return _('The eUICC rejected re-enabling this profile.');
			case 'profile_internal_error':
				return _('lpac reported an internal profile error. Try the other identifier and refresh setting.');
			}

			return Number.isInteger(result.code) && result.code >= 0
				? _('lpac rejected the operation (code %d).').format(result.code)
				: _('lpac rejected the operation.');
		case 'invalid_response':
			return _('lpac returned an invalid or unexpected response.');
		case 'rpc_error':
			return result.message || _('The lpac RPC request failed.');
		default:
			return result.message || result.error || _('The lpac operation failed.');
		}
	},

	dataOr: function(result, fallback) {
		return result && result.success ? result.data : fallback;
	}
});
