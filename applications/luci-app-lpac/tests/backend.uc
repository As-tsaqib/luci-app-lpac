// SPDX-License-Identifier: Apache-2.0

'use strict';

const DOWNLOAD_EXIT_SUCCESS = 64;
const DOWNLOAD_EXIT_NOT_FOUND = 65;
const DOWNLOAD_EXIT_NOT_EXECUTABLE = 66;
const DOWNLOAD_EXIT_FAILED = 67;
const DOWNLOAD_EXIT_SIGNALED = 68;
const DOWNLOAD_EXIT_PIPE_FAILED = 69;

function default_config() {
	return {
		global: {
			apdu_backend: 'uqmi',
			http_backend: 'curl',
			apdu_debug: '0',
			http_debug: '0',
			custom_isd_r_aid: 'A0000005591010FFFFFFFF8900000100'
		},
		at: {
			device: '/dev/ttyUSB2',
			debug: '0'
		},
		uqmi: {
			device: '/dev/cdc-wdm0',
			debug: '0'
		},
		mbim: {
			device: '/dev/cdc-wdm0',
			proxy: '1',
			skip_slot_mapping: '0'
		}
	};
}

function default_safety_config() {
	return {
		state: {
			schema: '1',
			profiles_refreshed: '0',
			notifications_refreshed: '0',
			notifications: '{}'
		}
	};
}

function default_luci_lpac_config() {
	return {
		profiles: {
			'.type': 'preferences',
			refresh_prompted: '0',
			refresh_default: '0'
		}
	};
}

function reset() {
	global.TEST_UCI = default_config();
	global.TEST_SAFETY_UCI = default_safety_config();
	global.TEST_LUCI_LPAC_UCI = default_luci_lpac_config();
	global.TEST_UCI_LOAD_FAIL = false;
	global.TEST_COMMIT_OK = true;
	global.TEST_LUCI_LPAC_FILE_EXISTS = true;
	global.TEST_LUCI_LPAC_LOAD_FAIL = false;
	global.TEST_LUCI_LPAC_LOAD_FAIL_AT = 0;
	global.TEST_LUCI_LPAC_LOAD_COUNT = 0;
	global.TEST_LUCI_LPAC_SET_FAIL = false;
	global.TEST_LUCI_LPAC_COMMIT_OK = true;
	global.TEST_LUCI_LPAC_UNLOAD_COUNT = 0;
	global.TEST_LUCI_LPAC_UNLOAD_FAIL_AT = 0;
	global.TEST_UCI_CURSOR_COUNT = 0;
	global.TEST_UCI_LOAD_CALLS = [];
	global.TEST_UCI_SET_CALLS = [];
	global.TEST_UCI_COMMIT_CALLS = [];
	global.TEST_UCI_UNLOAD_CALLS = [];
	global.TEST_SAFETY_FILE_EXISTS = false;
	global.TEST_SAFETY_FILE_TYPE = 'file';
	global.TEST_SAFETY_FILE_UID = 0;
	global.TEST_SAFETY_FILE_NLINK = 1;
	global.TEST_SAFETY_FILE_MODE = 0o600;
	global.TEST_SAFETY_FILE_CONTENT = '';
	global.TEST_SAFETY_OPEN_FAIL = false;
	global.TEST_SAFETY_WRITE_FAIL = false;
	global.TEST_SAFETY_FLUSH_THROW = false;
	global.TEST_SAFETY_CLOSE_FAIL = false;
	global.TEST_SAFETY_CHMOD_FAIL = false;
	global.TEST_SAFETY_UCI_LOAD_FAIL = false;
	global.TEST_SAFETY_UCI_LOAD_COUNT = 0;
	global.TEST_SAFETY_UCI_LOAD_FAIL_AT = 0;
	global.TEST_SAFETY_UCI_LOAD_FAIL_UNTIL = 0;
	global.TEST_SAFETY_UCI_UNLOAD_COUNT = 0;
	global.TEST_SAFETY_UCI_UNLOAD_FAIL_AT = 0;
	global.TEST_SAFETY_COMMIT_OK = true;
	global.TEST_TEMP_FILES = {};
	global.TEST_LOCK_EXISTS = false;
	global.TEST_LOCK_TYPE = 'file';
	global.TEST_LOCK_UID = 0;
	global.TEST_LOCK_NLINK = 1;
	global.TEST_LOCK_MODE = 0o600;
	global.TEST_LOCK_OPEN_FAIL = false;
	global.TEST_LOCK_CHMOD_FAIL = false;
	global.TEST_LOCK_BUSY = false;
	global.TEST_LOCK_CLOSED = false;
	global.TEST_LOCK_CLOSE_COUNT = 0;
	global.TEST_LOCK_OPEN = null;
	global.TEST_RANDOM_OPEN_FAIL = false;
	global.TEST_RANDOM_READ_FAIL = false;
	global.TEST_RANDOM_OPEN_COUNT = 0;
	global.TEST_RANDOM_READ_COUNT = 0;
	global.TEST_RANDOM_CLOSE_COUNT = 0;
	global.TEST_FD_COUNTER = 8;
	global.TEST_FD_STATES = {};
	global.TEST_PIPE_HANDLES = [];
	global.TEST_PIPES = [];
	global.TEST_OUTPUT_PIPE = null;
	global.TEST_PIPE_CALL_COUNT = 0;
	global.TEST_PIPE_THROW = false;
	global.TEST_PIPE_NULL = false;
	global.TEST_PIPE_CLONE_FAIL = false;
	global.TEST_PIPE_FILENO_THROW = false;
	global.TEST_PIPE_READ_THROW = false;
	global.TEST_PIPE_WRITE_THROW = false;
	global.TEST_PIPE_WRITE_PARTIAL = false;
	global.TEST_PIPE_FLUSH_THROW = false;
	global.TEST_PIPE_FLUSH_RESULT = true;
	global.TEST_PIPE_FLUSH_COUNT = 0;
	global.TEST_PIPE_CLOSE_COUNT = 0;
	global.TEST_DECISION_WRITES = [];
	global.TEST_PROC_OPEN_CALLS = [];
	global.TEST_DEFER_THROW = false;
	global.TEST_DEFER_NULL = false;
	global.TEST_DEFER_QUEUE = false;
	global.TEST_DEFERRED_CALLS = [];
	global.TEST_EXEC_STATUS = 0;
	global.TEST_EXEC_REPLY = null;
	global.TEST_LAST_CALL = null;
	global.TEST_LPAC_ACCESS = true;
	global.TEST_ACCESS_FAIL_PATH = null;
	global.TEST_ACCESS_CALLS = [];
	global.TEST_GLOB_RESULTS = {};
	global.TEST_READLINK_RESULTS = {};
	global.TEST_READLINK_CALLS = [];
	global.TEST_READLINK_THROW = false;
	global.TEST_READLINK_THROW_PATH = null;
	global.TEST_PROCESS_THROW = false;
	global.TEST_PROCESS_NULL = false;
	global.TEST_PROCESS_PID_THROW = false;
	global.TEST_PROCESS_PID = 4321;
	global.TEST_INNER_PROCESS_PID = 5432;
	global.TEST_PROCESSES = [];
	global.TEST_LAST_PROCESS = null;
	global.TEST_TIMER_THROW = false;
	global.TEST_TIMER_NULL = false;
	global.TEST_TIMER_NULL_AT = 0;
	global.TEST_TIMER_CALL_COUNT = 0;
	global.TEST_TIMER_SET_THROW = false;
	global.TEST_TIMER_SET_FAIL = false;
	global.TEST_TIMER_SET_COUNT = 0;
	global.TEST_TIMERS = [];
	global.TEST_LAST_TIMER = null;
	global.TEST_TIMER_CANCEL_COUNT = 0;
	global.TEST_HANDLE_THROW = false;
	global.TEST_HANDLE_NULL = false;
	global.TEST_HANDLE_NULL_AT = 0;
	global.TEST_HANDLE_CALL_COUNT = 0;
	global.TEST_HANDLE_DELETE_COUNT = 0;
	global.TEST_HANDLES = [];
	global.TEST_LAST_HANDLE = null;
	global.TEST_SYSTEM_EXIT = 0;
	global.TEST_SYSTEM_EXITS = [];
	global.TEST_SYSTEM_THROW = false;
	global.TEST_SYSTEM_CALLS = [];
	global.system = function(argv, timeout) {
		push(global.TEST_SYSTEM_CALLS, { argv, timeout });

		if (global.TEST_SYSTEM_THROW)
			die('system failed');

		return length(global.TEST_SYSTEM_EXITS)
			? shift(global.TEST_SYSTEM_EXITS)
			: global.TEST_SYSTEM_EXIT;
	};
}

let checks = 0;

function check(condition, message) {
	checks++;

	if (!condition)
		die(`not ok ${checks} - ${message}\n`);

	printf(`ok ${checks} - ${message}\n`);
}

function same(actual, expected, message) {
	check(sprintf('%J', actual) == sprintf('%J', expected), message);
}

reset();

const plugin = loadfile('./root/usr/share/rpcd/ucode/luci.lpac', {
	module_search_path: [ '../../../../../tests/lib/*.uc' ]
})();
const methods = plugin['luci.lpac'];

function invoke_with(method_set, name, args) {
	let replied = false;
	let response = null;
	const request = {
		args: args || {},
		reply: function(result) {
			replied = true;
			response = result;
		}
	};
	const returned = method_set[name].call(request);

	return replied ? response : returned;
}

function invoke(name, args) {
	return invoke_with(methods, name, args);
}

function fresh_backend_methods() {
	return loadfile('./root/usr/share/rpcd/ucode/luci.lpac', {
		module_search_path: [ '../../../../../tests/lib/*.uc' ]
	})()['luci.lpac'];
}

function oneshot_child_argv() {
	const request = global.TEST_LAST_CALL?.request;

	return request?.command == '/usr/bin/setsid' &&
		type(request.params) == 'array' && length(request.params) >= 4 &&
		request.params[0] == '/usr/libexec/luci-lpac-supervisor' &&
		request.params[1] == 'oneshot'
		? slice(request.params, 3) : [];
}

function activation_download(code, confirmation, imei) {
	return invoke('download_profile', {
		activation_code: code,
		imei: imei || '',
		confirmation_code: confirmation || ''
	});
}

function test_download(confirmation, imei) {
	return activation_download('LPA:1$smdp.example.com$MATCH',
		confirmation || '', imei || '');
}

function ensure_supervisor_identity() {
	if (!global.TEST_OUTPUT_PIPE.identity_emitted) {
		global.TEST_OUTPUT_PIPE.buffer += sprintf(
			'@luci-lpac-pgid:%d\n', global.TEST_INNER_PROCESS_PID);
		global.TEST_OUTPUT_PIPE.identity_emitted = true;
	}
}

function emit_download_output(fragment) {
	ensure_supervisor_identity();
	global.TEST_OUTPUT_PIPE.buffer += fragment;
	global.TEST_LAST_HANDLE.callback(1, false, false);
}

function end_download_output() {
	ensure_supervisor_identity();
	global.TEST_OUTPUT_PIPE.eof = true;
	global.TEST_LAST_HANDLE.callback(1, true, false);
}

function complete_download(exit_code, output) {
	if (type(output) == 'string' && length(output))
		emit_download_output(output);

	global.TEST_LAST_PROCESS.output(exit_code);
	end_download_output();
}

function emit_async_output(fragment) {
	ensure_supervisor_identity();
	global.TEST_OUTPUT_PIPE.buffer += fragment;
	global.TEST_LAST_HANDLE.callback(1, false, false);
}

function end_async_output() {
	ensure_supervisor_identity();
	global.TEST_OUTPUT_PIPE.eof = true;
	global.TEST_LAST_HANDLE.callback(1, true, false);
}

function complete_async_job(exit_code, output) {
	if (type(output) == 'string' && length(output))
		emit_async_output(output);

	global.TEST_LAST_PROCESS.output(exit_code);
	end_async_output();
}

function exhaust_async_cleanup() {
	for (let i = 0; i < 5; i++)
		global.TEST_TIMERS[2].callback();
}

function exhaust_download_cleanup() {
	for (let i = 0; i < 5; i++)
		global.TEST_TIMERS[3].callback();
}

function progress(message, data) {
	return sprintf('%J\n', {
		type: 'progress',
		payload: { code: 0, message, data }
	});
}

function terminal(data, code, message) {
	if (type(code) != 'int')
		code = 0;
	if (type(message) != 'string')
		message = code == 0 ? 'success' : 'failure';

	return sprintf('%J\n', {
		type: 'lpa',
		payload: {
			code,
			message,
			data
		}
	});
}

function discovery_protocol(data) {
	return progress('es10b_get_euicc_challenge_and_info', 'redacted') +
		progress('es9p_initiate_authentication', 'redacted') +
		progress('es10b_authenticate_server', 'redacted') +
		progress('es11_authenticate_client', 'redacted') +
		terminal(data);
}

function notification_protocol(seq, remove_after_success, terminal_record) {
	let output = progress('es10b_retrieve_notifications_list', seq) +
		progress('es9p_handle_notification', seq);

	if (remove_after_success)
		output += progress('es10b_remove_notification_from_list', seq);

	return output + terminal_record;
}

function download_progress(message, data) {
	return sprintf('%J\n', {
		type: 'progress',
		payload: { code: 0, message, data }
	});
}

function owner_status(job_id, decision_token) {
	return invoke('get_download_status', { job_id, decision_token });
}

function make_text(character, count) {
	let value = '';

	for (let i = 0; i < count; i++)
		value += character;

	return value;
}

function valid_secret_for_test(value) {
	return type(value) == 'string' &&
		match(value, /^[A-Za-z0-9_-]{32}$/) !== null;
}

function safety_notifications_empty() {
	let notifications;

	try { notifications = json(global.TEST_SAFETY_UCI.state.notifications); }
	catch (e) { return false; }

	if (type(notifications) != 'object')
		return false;

	for (let ignored in notifications)
		return false;

	return true;
}

function safety_state_invalid() {
	const status = invoke('get_download_status', {
		job_id: 0, decision_token: ''
	});

	return status.success && status.data?.safety?.verification_required &&
		status.data.safety.state_invalid === true;
}

global.TEST_EXEC_REPLY = { code: 0, stdout: terminal('v2.3.0') };
let result = invoke('get_version');
check(result.success && result.data == 'v2.3.0', 'version response is normalized');
check(global.TEST_LAST_CALL.request.command == '/usr/bin/setsid' &&
	global.TEST_LAST_CALL.request.params[0] ==
		'/usr/libexec/luci-lpac-supervisor' &&
	global.TEST_LAST_CALL.request.params[1] == 'oneshot' &&
	global.TEST_LAST_CALL.request.params[2] == '25',
	'one-shot commands use an isolated process group with an internal watchdog');
same(oneshot_child_argv(), [ '/usr/bin/lpac', 'version' ],
	'version child argv is fixed');

reset();
result = invoke('get_config');
same(result.data, default_config(),
	'configuration reads expose the normalized MBIM slot-mapping preference');

reset();
delete global.TEST_UCI.global.apdu_backend;
delete global.TEST_UCI.mbim.skip_slot_mapping;
result = invoke('get_config');
	check(result.success && result.data.global.apdu_backend == 'uqmi' &&
	result.data.mbim.skip_slot_mapping == '0',
		'missing release options fall back to UQMI with standard MBIM slot mapping');

reset();
result = invoke('get_profile_refresh_preference');
check(result.success && sprintf('%J', result.data) ==
	sprintf('%J', { asked: false, refresh: false }) &&
	!length(global.TEST_UCI_SET_CALLS) && !length(global.TEST_UCI_COMMIT_CALLS),
	'a fresh app-owned profile refresh preference is safely disabled');

reset();
global.TEST_LUCI_LPAC_FILE_EXISTS = false;
result = invoke('get_profile_refresh_preference');
same(result.data, { asked: false, refresh: false },
	'a missing app-owned preference file fails closed');

reset();
global.TEST_LUCI_LPAC_LOAD_FAIL = true;
result = invoke('get_profile_refresh_preference');
same(result.data, { asked: false, refresh: false },
	'a preference load failure fails closed');

for (let malformed in [
	{
		profiles: {
			'.type': 'other', refresh_prompted: '1', refresh_default: '1'
		}
	},
	{
		profiles: {
			'.type': 'preferences', refresh_prompted: 'yes', refresh_default: '1'
		}
	},
	{
		profiles: {
			'.type': 'preferences', refresh_prompted: '1'
		}
	},
	{
		profiles: {
			'.type': 'preferences', refresh_prompted: '1', refresh_default: 'yes'
		}
	}
]) {
	reset();
	global.TEST_LUCI_LPAC_UCI = malformed;
	result = invoke('get_profile_refresh_preference');
	check(result.success && sprintf('%J', result.data) ==
		sprintf('%J', { asked: false, refresh: false }),
		'a malformed app-owned preference schema fails closed');
}

reset();
global.TEST_LUCI_LPAC_UCI = {
	profiles: {
		'.type': 'preferences',
		refresh_prompted: '1',
		refresh_default: '1',
		future_option: 'keep'
	},
	future_section: { '.type': 'future', value: 'keep' }
};
result = invoke('get_profile_refresh_preference');
same(result.data, { asked: true, refresh: true },
	'unrelated app-owned sections and options do not invalidate the preference');
result = invoke('set_profile_refresh_preference', { refresh: false });
check(result.success && result.data.asked && !result.data.refresh &&
	global.TEST_LUCI_LPAC_UCI.profiles.future_option == 'keep' &&
	global.TEST_LUCI_LPAC_UCI.future_section.value == 'keep',
	'the preference setter preserves unrelated forward-compatible UCI data');

reset();
global.TEST_LUCI_LPAC_UCI.profiles.refresh_default = '1';
result = invoke('get_profile_refresh_preference');
same(result.data, { asked: false, refresh: false },
	'an unprompted stored default can never enable profile refresh');

reset();
for (let args in [ {}, { refresh: null }, { refresh: 0 }, { refresh: '1' } ]) {
	result = invoke('set_profile_refresh_preference', args);
	check(!result.success && result.error == 'invalid_argument',
		'the profile refresh preference setter requires an explicit boolean');
}
check(!length(global.TEST_UCI_SET_CALLS) && !length(global.TEST_UCI_COMMIT_CALLS),
	'invalid preference values perform no UCI writes');

reset();
const original_lpac_config = sprintf('%J', global.TEST_UCI);
const original_safety_config = sprintf('%J', global.TEST_SAFETY_UCI);
result = invoke('set_profile_refresh_preference', { refresh: true });
let preference_writes_isolated = result.success &&
	sprintf('%J', result.data) == sprintf('%J', { asked: true, refresh: true }) &&
	global.TEST_LUCI_LPAC_UCI.profiles.refresh_prompted == '1' &&
	global.TEST_LUCI_LPAC_UCI.profiles.refresh_default == '1' &&
	global.TEST_UCI_CURSOR_COUNT == 2 &&
	length(global.TEST_UCI_COMMIT_CALLS) == 1 &&
	global.TEST_UCI_COMMIT_CALLS[0].config == 'luci_lpac' &&
	sprintf('%J', global.TEST_UCI) == original_lpac_config &&
	sprintf('%J', global.TEST_SAFETY_UCI) == original_safety_config;
for (let call in global.TEST_UCI_SET_CALLS)
	preference_writes_isolated = preference_writes_isolated &&
		call.config == 'luci_lpac';
check(preference_writes_isolated,
	'the preference setter commits only luci_lpac and verifies it with a new cursor');
result = invoke('get_profile_refresh_preference');
same(result.data, { asked: true, refresh: true },
	'the prompted refresh default persists across RPC reads');
result = invoke('set_profile_refresh_preference', { refresh: false });
same(result.data, { asked: true, refresh: false },
	'a persisted negative preference remains prompted but disables refresh');

reset();
global.TEST_LUCI_LPAC_LOAD_FAIL = true;
result = invoke('set_profile_refresh_preference', { refresh: true });
check(!result.success && result.error == 'config_write_failed' &&
	!length(global.TEST_UCI_SET_CALLS) && !length(global.TEST_UCI_COMMIT_CALLS),
	'a preference write load failure performs no mutation');

reset();
global.TEST_LUCI_LPAC_SET_FAIL = true;
result = invoke('set_profile_refresh_preference', { refresh: true });
check(!result.success && result.error == 'config_write_failed' &&
	length(global.TEST_UCI_SET_CALLS) == 1 &&
	!length(global.TEST_UCI_COMMIT_CALLS),
	'a failed preference set is not committed');
result = invoke('get_profile_refresh_preference');
same(result.data, { asked: false, refresh: false },
	'a failed preference set remains disabled when read through a new cursor');

reset();
global.TEST_LUCI_LPAC_COMMIT_OK = false;
result = invoke('set_profile_refresh_preference', { refresh: true });
check(!result.success && result.error == 'config_write_failed' &&
	length(global.TEST_UCI_COMMIT_CALLS) == 1 &&
	global.TEST_UCI_COMMIT_CALLS[0].config == 'luci_lpac',
	'a failed preference commit is reported without touching another config');
result = invoke('get_profile_refresh_preference');
same(result.data, { asked: false, refresh: false },
	'a failed preference commit publishes no uncommitted opt-in state');

reset();
global.TEST_LUCI_LPAC_UNLOAD_FAIL_AT = 1;
result = invoke('set_profile_refresh_preference', { refresh: true });
check(result.success && result.data.asked && result.data.refresh &&
	global.TEST_UCI_CURSOR_COUNT == 2,
	'a fresh authoritative readback accepts a commit despite writer unload failure');

reset();
global.TEST_LUCI_LPAC_LOAD_FAIL_AT = 2;
result = invoke('set_profile_refresh_preference', { refresh: true });
check(!result.success && result.error == 'config_write_failed' &&
	global.TEST_UCI_CURSOR_COUNT == 3 &&
	length(global.TEST_UCI_COMMIT_CALLS) == 2 &&
	global.TEST_LUCI_LPAC_UCI.profiles.refresh_prompted == '1' &&
	global.TEST_LUCI_LPAC_UCI.profiles.refresh_default == '0',
	'a failed fresh-cursor readback rolls a completed opt-in back to fail-off');
result = invoke('get_profile_refresh_preference');
same(result.data, { asked: true, refresh: false },
	'a transient readback failure leaves the persisted preference safely disabled');

reset();
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: sprintf('%J\n', {
		type: 'driver',
		payload: {
			LPAC_APDU: [ 'uqmi', 'stdio', 'mbim', 'uqmi' ],
			LPAC_HTTP: [ 'curl', 'stdio' ]
		}
	})
};
result = invoke('get_drivers');
same(result.data, { apdu: [ 'uqmi', 'mbim' ], http: [ 'curl' ] },
	'driver response is allowlisted and deduplicated');

reset();
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: sprintf('%J\n', { type: 'driver', payload: { LPAC_APDU: [] } })
};
result = invoke('get_drivers');
check(!result.success && result.error == 'invalid_response',
	'incomplete driver schemas are rejected');

reset();
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: sprintf('%J\n', {
		type: 'driver',
		payload: {
			env: 'LPAC_APDU_AT_DEVICE',
			data: [
				{ env: '/dev/serial/by-id/usb-Test_Modem-if00', name: 'Test modem' },
				{ env: '/dev/serial/../ttyUSB0', name: 'Traversal' }
			]
		}
	})
};
global.TEST_GLOB_RESULTS = {
	'/dev/ttyUSB*': [ '/dev/ttyUSB0', '/dev/ttyUSB0;invalid' ],
	'/dev/ttyACM*': [ '/dev/ttyACM1' ],
	'/dev/wwan*at*': [ '/dev/wwan0at0', '/dev/wwan-at' ]
};
result = invoke('list_apdu_devices', { backend: 'at' });
same(result.data, {
	backend: 'at',
	devices: [
		{
			value: '/dev/serial/by-id/usb-Test_Modem-if00',
			name: 'Test modem'
		},
		{ value: '/dev/ttyUSB0', name: 'ttyUSB0' },
		{ value: '/dev/ttyACM1', name: 'ttyACM1' },
		{ value: '/dev/wwan0at0', name: 'wwan0at0' }
	]
}, 'AT detection combines safe native links with strict OpenWrt device fallbacks');
same(oneshot_child_argv(), [
	'/usr/bin/env', 'LPAC_APDU=at', 'LPAC_HTTP=curl', '/usr/lib/lpac',
	'driver', 'apdu', 'list'
], 'AT detection uses fixed native lpac argv and a validated backend assignment');

reset();
const maximum_native_at_devices = [];
for (let i = 0; i < 64; i++)
	push(maximum_native_at_devices, {
		env: `/dev/serial/by-id/usb-Test_Modem-${i}`,
		name: `Test modem ${i}`
	});
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: sprintf('%J\n', {
		type: 'driver',
		payload: {
			env: 'LPAC_APDU_AT_DEVICE',
			data: maximum_native_at_devices
		}
	})
};
global.TEST_GLOB_RESULTS = {
	'/dev/ttyUSB*': [ '/dev/ttyUSB0', '/dev/ttyUSB1' ]
};
result = invoke('list_apdu_devices', { backend: 'at' });
check(result.success && length(result.data.devices) == 64 &&
	index(map(result.data.devices, function(device) { return device.value; }),
		'/dev/ttyUSB0') < 0,
	'AT fallback detection cannot exceed the 64-device native result cap');

reset();
global.TEST_GLOB_RESULTS = {
	'/dev/wwan*qmi*': [
		'/dev/wwan0qmi0', '/dev/wwan0qmi0', '/dev/wwan-qmi',
		'/dev/wwan0qmi0;reboot'
	],
	'/dev/cdc-wdm*': [
		'/dev/cdc-wdm0', '/dev/cdc-wdm1', '/dev/cdc-wdm2',
		'/dev/cdc-wdm2;reboot'
	]
};
global.TEST_READLINK_RESULTS = {
	'/sys/class/usbmisc/cdc-wdm0/device/driver':
		'../../../../../../bus/usb/drivers/qmi_wwan',
	'/sys/class/usbmisc/cdc-wdm1/device/driver':
		'../../../../../../bus/usb/drivers/cdc_mbim'
};
result = invoke('list_apdu_devices', { backend: 'uqmi' });
same(result.data, {
	backend: 'uqmi',
	devices: [
		{ value: '/dev/wwan0qmi0', name: 'wwan0qmi0 (QMI)' },
		{ value: '/dev/cdc-wdm0', name: 'cdc-wdm0 (qmi_wwan)' }
	]
}, 'QMI detection accepts only canonical direct ports and qmi_wwan-bound cdc-wdm devices');
check(global.TEST_LAST_CALL === null && length(global.TEST_ACCESS_CALLS) == 0,
	'QMI detection reads names and sysfs only without executing or opening lpac');
same(global.TEST_READLINK_CALLS, [
	'/sys/class/usbmisc/cdc-wdm0/device/driver',
	'/sys/class/usbmisc/cdc-wdm1/device/driver',
	'/sys/class/usbmisc/cdc-wdm2/device/driver'
], 'QMI detection classifies each canonical cdc-wdm path by its kernel driver');

reset();
global.TEST_GLOB_RESULTS = {
	'/dev/wwan*mbim*': [ '/dev/wwan1mbim0', '/dev/wwan1mbim0', '/dev/wwan-mbim' ],
	'/dev/cdc-wdm*': [ '/dev/cdc-wdm0', '/dev/cdc-wdm1' ]
};
global.TEST_READLINK_RESULTS = {
	'/sys/class/usbmisc/cdc-wdm0/device/driver':
		'../../../../../../bus/usb/drivers/qmi_wwan',
	'/sys/class/usbmisc/cdc-wdm1/device/driver':
		'../../../../../../bus/usb/drivers/cdc_mbim'
};
result = invoke('list_apdu_devices', { backend: 'mbim' });
same(result.data, {
	backend: 'mbim',
	devices: [
		{ value: '/dev/wwan1mbim0', name: 'wwan1mbim0 (MBIM)' },
		{ value: '/dev/cdc-wdm1', name: 'cdc-wdm1 (cdc_mbim)' }
	]
}, 'MBIM detection accepts only canonical direct ports and cdc_mbim-bound cdc-wdm devices');
check(global.TEST_LAST_CALL === null && length(global.TEST_ACCESS_CALLS) == 0,
	'MBIM detection reads names and sysfs only without executing or opening lpac');

reset();
global.TEST_GLOB_RESULTS = {
	'/dev/wwan*qmi*': [],
	'/dev/cdc-wdm*': [ '/dev/cdc-wdm0', '/dev/cdc-wdm1' ]
};
global.TEST_READLINK_THROW_PATH =
	'/sys/class/usbmisc/cdc-wdm0/device/driver';
global.TEST_READLINK_RESULTS = {
	'/sys/class/usbmisc/cdc-wdm1/device/driver':
		'../../../../../../bus/usb/drivers/qmi_wwan'
};
result = invoke('list_apdu_devices', { backend: 'uqmi' });
same(result.data.devices, [
	{ value: '/dev/cdc-wdm1', name: 'cdc-wdm1 (qmi_wwan)' }
], 'one unreadable sysfs binding does not hide other safely classified QMI ports');

reset();
const maximum_direct_qmi_devices = [];
for (let i = 0; i < 64; i++)
	push(maximum_direct_qmi_devices, `/dev/wwan${i}qmi0`);
global.TEST_GLOB_RESULTS = {
	'/dev/wwan*qmi*': maximum_direct_qmi_devices,
	'/dev/cdc-wdm*': [ '/dev/cdc-wdm0' ]
};
global.TEST_READLINK_RESULTS = {
	'/sys/class/usbmisc/cdc-wdm0/device/driver':
		'../../../../../../bus/usb/drivers/qmi_wwan'
};
result = invoke('list_apdu_devices', { backend: 'uqmi' });
check(result.success && length(result.data.devices) == 64 &&
	index(map(result.data.devices, function(device) { return device.value; }),
		'/dev/cdc-wdm0') < 0 && length(global.TEST_READLINK_CALLS) == 0,
	'QMI detection enforces its 64-port cap before scanning cdc-wdm fallbacks');

reset();
result = invoke('list_apdu_devices', { backend: 'pcsc' });
check(!result.success && result.error == 'invalid_argument' &&
	global.TEST_LAST_CALL === null,
	'removed PC/SC detection is rejected without process execution');

reset();
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal({
		eidValue: '89012345678901234567890123456789',
		EuiccConfiguredAddresses: {},
		EUICCInfo2: {}
	})
};
result = invoke('get_info');
check(result.success && result.data.eidValue == '89012345678901234567890123456789',
	'chip information requires and preserves a valid EID');

reset();
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal({ EUICCInfo2: {} }) };
result = invoke('get_info');
check(!result.success && result.error == 'invalid_response',
	'chip information without a valid EID is rejected');

reset();
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal({
		eidValue: '89012345678901234567890123456789\n',
		EUICCInfo2: {}
	})
};
result = invoke('get_info');
check(!result.success && result.error == 'invalid_response',
	'an EID with a newline suffix cannot exploit end-anchor behavior');

reset();
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal({
		eidValue: '89012345678901234567890123456789',
		EUICCInfo2: {
			euiccCiPKIdListForVerification: [ 'A1B2', 'C3D4\n', 'E5F6\r\n' ]
		}
	})
};
result = invoke('get_info');
same(result.data.EUICCInfo2.euiccCiPKIdListForVerification, [ 'A1B2' ],
	'hex-list normalization discards control-suffixed values');

reset();
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal([]) };
result = invoke('list_profiles');
check(result.success && global.TEST_LOCK_EXISTS &&
	global.TEST_LOCK_MODE == 0o600 && global.TEST_CHMOD?.mode == 0o600,
	'eUICC operations create and enforce a mode-0600 lock file');

reset();
global.TEST_LOCK_EXISTS = true;
global.TEST_LOCK_MODE = 0o644;
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal([]) };
result = invoke('list_profiles');
check(result.success && global.TEST_LOCK_MODE == 0o600,
	'a pre-existing permissive lock file is repaired before execution');

reset();
global.TEST_LOCK_EXISTS = true;
global.TEST_LOCK_TYPE = 'symlink';
result = invoke('list_profiles');
check(!result.success && result.error == 'lock_failed' &&
	global.TEST_LAST_CALL === null,
	'non-regular lock paths are rejected before process execution');

reset();
const png_icon_data = b64enc(chr(137, 80, 78, 71, 13, 10, 26, 10));
const jpeg_icon_data = b64enc(chr(255, 216, 255, 224));
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal([
		{
			iccid: '8912345678901234567',
			isdpAid: 'A0000005591010FFFFFFFF8900001000',
			profileState: 'disabled',
			profileNickname: 'Test',
			serviceProviderName: 'Carrier',
			profileName: 'Plan',
			iconType: 'png',
			icon: png_icon_data,
			profileClass: 'operational'
		},
		{
			iccid: '8912345678901234568',
			iconType: 'jpeg',
			icon: jpeg_icon_data
		},
		{ iccid: '../../invalid', isdpAid: null }
	])
};
result = invoke('list_profiles');
check(!result.success && result.error == 'invalid_response',
	'a mixed valid and invalid profile list is rejected atomically');

reset();
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal([
		{
			iccid: '8912345678901234567',
			isdpAid: 'A0000005591010FFFFFFFF8900001000',
			profileState: 'disabled',
			profileNickname: 'Test',
			serviceProviderName: 'Carrier',
			profileName: 'Plan',
			iconType: 'png',
			icon: png_icon_data,
			profileClass: 'operational'
		},
		{
			iccid: '8912345678901234568',
			iconType: 'jpeg',
			icon: jpeg_icon_data
		}
	])
};
result = invoke('list_profiles');
check(result.success && length(result.data) == 2 &&
	result.data[0].iconType == 'png' && result.data[0].icon == png_icon_data &&
	result.data[1].iconType == 'jpeg' && result.data[1].icon == jpeg_icon_data,
	'bounded PNG and JPEG profile icons are normalized for LuCI');

let oversized_icon = chr(137, 80, 78, 71, 13, 10, 26, 10);
for (let i = 8; i < 1025; i++)
	oversized_icon += chr(0);

reset();
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal([
		{
			iccid: '8912345678901234569',
			iconType: 'svg',
			icon: b64enc('<svg/>')
		},
		{
			iccid: '8912345678901234570',
			iconType: 'png',
			icon: jpeg_icon_data
		},
		{
			iccid: '8912345678901234571',
			iconType: 'png',
			icon: png_icon_data + '\n'
		},
		{
			iccid: '8912345678901234572',
			iconType: 'png',
			icon: b64enc(oversized_icon)
		}
	])
};
result = invoke('list_profiles');
let invalid_icons_removed = result.success && length(result.data) == 4;
for (let profile in result.data)
	invalid_icons_removed = invalid_icons_removed &&
		profile.iconType === null && profile.icon === null;
check(invalid_icons_removed,
	'invalid, mismatched, control-suffixed, and oversized profile icons are removed');

reset();
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal([
		{ iccid: '8912345678901234567\n', isdpAid: null },
		{ iccid: null, isdpAid: 'A0000005591010FFFFFFFF8900001000\n' },
		{ iccid: '8912345678901234567', isdpAid: null }
	])
};
result = invoke('list_profiles');
check(!result.success && result.error == 'invalid_response',
	'control-suffixed ICCID and AID make the profile list non-authoritative');

reset();
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal([
		{ seqNumber: 0, profileManagementOperation: 'install' },
		{ seqNumber: 4294967295, profileManagementOperation: 'delete' }
	])
};
result = invoke('list_notifications');
check(result.success && length(result.data) == 2 &&
	result.data[0].seqNumber == 0 && result.data[1].seqNumber == 4294967295,
	'notification list preserves the full uint32 sequence range');

reset();
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal([
		{ iccid: '8912345678901234567' },
		{ iccid: '8912345678901234567' }
	])
};
result = invoke('list_profiles');
check(!result.success && result.error == 'invalid_response',
	'duplicate profile identifiers reject the complete non-authoritative list');

reset();
const too_many_profiles = [];
for (let i = 0; i < 129; i++)
	push(too_many_profiles, { iccid: sprintf('89%016d', i) });
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal(too_many_profiles) };
result = invoke('list_profiles');
check(!result.success && result.error == 'invalid_response',
	'a profile list beyond the 128-record contract is rejected rather than pruned');

reset();
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal([
		{ seqNumber: 1 },
		{ seqNumber: 1 }
	])
};
result = invoke('list_notifications');
check(!result.success && result.error == 'invalid_response',
	'duplicate notification sequences reject the complete non-authoritative list');

reset();
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal([ { seqNumber: 1 }, { seqNumber: '2' } ])
};
result = invoke('list_notifications');
check(!result.success && result.error == 'invalid_response',
	'a malformed notification record rejects the complete list atomically');

reset();
const too_many_notifications = [];
for (let i = 0; i < 257; i++)
	push(too_many_notifications, { seqNumber: i });
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal(too_many_notifications) };
result = invoke('list_notifications');
check(!result.success && result.error == 'invalid_response',
	'a notification list beyond the 256-record contract is rejected rather than pruned');

reset();
const discovery_secret = 'secret-event-id-never-returned';
if (false) {
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal([
		{ eventId: discovery_secret, rspServerAddress: 'rsp.example.com' },
		{ eventId: discovery_secret, rspServerAddress: 'rsp.example.com' },
		{ eventId: 'second-secret', rspServerAddress: 'rsp2.example.com:443' }
	])
};
result = invoke('discover_profiles', { smds: '', imei: '' });
check(result.success && length(result.data) == 2 &&
	result.data[0].smdp == 'rsp.example.com' &&
	result.data[1].smdp == 'rsp2.example.com:443',
	'discovery returns deduplicated validated SM-DP+ display addresses');
check(match(result.data[0].entry_id, /^[A-Za-z0-9_-]{32}$/) !== null &&
	match(result.data[1].entry_id, /^[A-Za-z0-9_-]{32}$/) !== null &&
	result.data[0].entry_id != result.data[1].entry_id &&
	index(sprintf('%J', result), discovery_secret) < 0 &&
	index(sprintf('%J', result), 'second-secret') < 0,
	'discovery replaces EventIDs with distinct opaque in-memory tokens');
same(global.TEST_LAST_CALL.request.params, [
	'-n', '/var/run/luci-lpac.lock', '/usr/bin/lpac',
	'profile', 'discovery', '-j'
], 'default discovery uses detailed JSON without injecting a default SM-DS flag');
check(global.TEST_RANDOM_OPEN_COUNT == 2 &&
	global.TEST_RANDOM_CLOSE_COUNT == 2,
	'each unique discovery result receives fresh randomness from a closed handle');
const first_discovery_timer = global.TEST_TIMERS[0];
check(length(global.TEST_TIMERS) == 1 &&
	first_discovery_timer.timeout == 300000,
	'discovery secrets receive a five-minute expiry watchdog');

result = invoke('discover_profiles', { smds: '', imei: '' });
const expiring_entry_id = result.data[0].entry_id;
const replacement_discovery_timer = global.TEST_TIMERS[1];
check(result.success && first_discovery_timer.cancelled &&
	replacement_discovery_timer.timeout == 300000,
	'a replacement discovery cancels the previous secret-expiry watchdog');
result = invoke('download_discovered_profile', {
	entry_id: expiring_entry_id + '\n', confirmation_code: ''
});
check(!result.success && result.error == 'invalid_argument',
	'a control-suffixed discovery token is rejected at the RPC boundary');
replacement_discovery_timer.callback();
result = invoke('download_discovered_profile', {
	entry_id: expiring_entry_id, confirmation_code: ''
});
check(!result.success && result.error == 'entry_unavailable' &&
	global.TEST_LAST_PROCESS === null,
	'the expiry watchdog hard-deletes EventIDs and retained IMEI values');

reset();
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal([ {
		eventId: 'ipv6-event',
		rspServerAddress: '[2001:db8::2]:8443'
	} ])
};
result = invoke('discover_profiles', {
	smds: '[2001:db8::1]:443', imei: '1234567890123456'
});
check(result.success && index(sprintf('%J', result), '1234567890123456') < 0,
	'discovery retains but never returns the validated IMEI');
same(global.TEST_LAST_CALL.request.params, [
	'-n', '/var/run/luci-lpac.lock', '/usr/bin/lpac',
	'profile', 'discovery', '-j', '-s', '[2001:db8::1]:443',
	'-i', '1234567890123456'
], 'SM-DS and IMEI remain separate fixed discovery argv elements');

reset();
for (let args in [
	{ smds: '-a', imei: '' },
	{ smds: 'smds.example.com/path', imei: '' },
	{ smds: 'smds_example.com', imei: '' },
	{ smds: 'smds.example.com:0', imei: '' },
	{ smds: '999.999.999.999', imei: '' },
	{ smds: 'smds.example.com', imei: '1234567890123' },
	{ smds: 'smds.example.com', imei: '12345678901234\n' }
]) {
	result = invoke('discover_profiles', args);
	check(!result.success && result.error == 'invalid_argument' &&
		global.TEST_LAST_CALL === null,
		'malformed discovery host, port, IMEI, or argv injection is rejected');
}

for (let payload in [
	{}, [ 'rsp.example.com' ], [ {} ],
	[ { eventId: '', rspServerAddress: 'rsp.example.com' } ],
	[ { eventId: 'bad\nevent', rspServerAddress: 'rsp.example.com' } ],
	[ { eventId: make_text('E', 4097), rspServerAddress: 'rsp.example.com' } ],
	[ { eventId: 'event', rspServerAddress: 'https://rsp.example.com/path' } ]
]) {
	reset();
	global.TEST_EXEC_REPLY = { code: 0, stdout: terminal(payload) };
	result = invoke('discover_profiles', { smds: '', imei: '' });
	check(!result.success && result.error == 'invalid_response' &&
		index(sprintf('%J', result), 'bad\nevent') < 0,
		'malformed or legacy detailed discovery payload is rejected');
}

reset();
const excessive_discovery_results = [];
for (let i = 0; i < 65; i++)
	push(excessive_discovery_results, {
		eventId: `event-${i}`,
		rspServerAddress: `rsp${i}.example.com`
	});
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal(excessive_discovery_results)
};
result = invoke('discover_profiles', { smds: '', imei: '' });
check(!result.success && result.error == 'invalid_response' &&
	global.TEST_RANDOM_OPEN_COUNT == 0,
	'a compromised lpac response cannot retain more than 64 discovery entries');

reset();
global.TEST_RANDOM_OPEN_FAIL = true;
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal([ {
		eventId: discovery_secret, rspServerAddress: 'rsp.example.com'
	} ])
};
result = invoke('discover_profiles', { smds: '', imei: '' });
check(!result.success && result.error == 'execution_failed' &&
	index(sprintf('%J', result), discovery_secret) < 0 &&
	global.TEST_RANDOM_OPEN_COUNT == 8,
	'discovery fails closed without exposing secrets when entropy is unavailable');

reset();
global.TEST_TIMER_NULL_AT = 1;
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal([ {
		eventId: discovery_secret, rspServerAddress: 'rsp.example.com'
	} ])
};
result = invoke('discover_profiles', { smds: '', imei: '' });
check(!result.success && result.error == 'execution_failed' &&
	!('data' in result) && index(sprintf('%J', result), discovery_secret) < 0,
	'discovery returns no token when expiry-timer creation fails');

reset();
global.TEST_TIMER_SET_FAIL = true;
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal([ {
		eventId: discovery_secret, rspServerAddress: 'rsp.example.com'
	} ])
};
result = invoke('discover_profiles', { smds: '', imei: '' });
check(!result.success && result.error == 'execution_failed' &&
	!('data' in result) && length(global.TEST_TIMERS) == 1 &&
	global.TEST_TIMERS[0].cancelled &&
	index(sprintf('%J', result), discovery_secret) < 0,
	'discovery erases secrets when the expiry watchdog cannot be armed');
}

reset();
const async_discovery_secret = 'secret-event-id-never-returned';
result = invoke('discover_profiles', { smds: '', imei: '' });
const discovery_job_id = result.data?.job_id;
const discovery_owner_token = result.data?.owner_token;
check(result.success && result.data.status == 'running' &&
	result.data.phase == 'contacting_smds' &&
	match(discovery_owner_token, /^[A-Za-z0-9_-]{32}$/) !== null,
	'discovery starts an owner-scoped asynchronous job');
const discovery_lpac_index = index(global.TEST_LAST_PROCESS.arguments, '/usr/bin/lpac');
same(slice(global.TEST_LAST_PROCESS.arguments, discovery_lpac_index), [
	'/usr/bin/lpac', 'profile', 'discovery', '-j'
], 'default discovery keeps the fixed detailed lpac argv');
check(global.TEST_TIMERS[0].timeout == 180000 && global.TEST_LAST_CALL === null,
	'discovery can run beyond rpcd file.exec timeout under a 180-second watchdog');
result = invoke('get_discovery_status', {
	job_id: discovery_job_id,
	owner_token: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
});
check(!result.success && result.error == 'not_authorized',
	'a wrong discovery owner token cannot read eventual capabilities');
check(invoke('get_discovery_status', { job_id: 0, owner_token: '' }).data.job_id ==
	discovery_job_id,
	'job zero exposes only public discovery recovery state');

const discovery_output = discovery_protocol([
	{ eventId: async_discovery_secret, rspServerAddress: 'rsp.example.com' },
	{ eventId: async_discovery_secret, rspServerAddress: 'rsp.example.com' },
	{ eventId: 'second-secret', rspServerAddress: 'rsp2.example.com:443' }
]);
emit_async_output(substr(discovery_output, 0, 37));
emit_async_output(substr(discovery_output, 37));
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_SUCCESS);
result = invoke('get_discovery_status', {
	job_id: discovery_job_id, owner_token: discovery_owner_token
});
check(result.success && result.data.status == 'running',
	'discovery process exit alone does not fabricate output EOF');
end_async_output();
result = invoke('get_discovery_status', {
	job_id: discovery_job_id, owner_token: discovery_owner_token
});
check(result.success && result.data.status == 'success' &&
	length(result.data.results) == 2 &&
	result.data.results[0].smdp == 'rsp.example.com' &&
	result.data.results[1].smdp == 'rsp2.example.com:443' &&
	index(sprintf('%J', result), async_discovery_secret) < 0 &&
	index(sprintf('%J', result), 'second-secret') < 0,
	'completed discovery returns only deduplicated opaque entries after real EOF');
check(match(result.data.results[0].entry_id, /^[A-Za-z0-9_-]{32}$/) !== null &&
	result.data.results[0].entry_id != result.data.results[1].entry_id,
	'discovery EventIDs become distinct backend-only capabilities');
check(invoke('get_discovery_status', { job_id: 0, owner_token: '' }).data.status ==
	'idle', 'public discovery recovery state returns idle after cleanup');

reset();
result = invoke('discover_profiles', {
	smds: '[2001:db8::1]:443', imei: '1234567890123456'
});
const ipv6_discovery_id = result.data.job_id;
const ipv6_discovery_token = result.data.owner_token;
const ipv6_lpac_index = index(global.TEST_LAST_PROCESS.arguments, '/usr/bin/lpac');
same(slice(global.TEST_LAST_PROCESS.arguments, ipv6_lpac_index), [
	'/usr/bin/lpac', 'profile', 'discovery', '-j', '-s',
	'[2001:db8::1]:443', '-i', '1234567890123456'
], 'SM-DS and IMEI remain distinct async supervisor argv elements');
complete_async_job(DOWNLOAD_EXIT_SUCCESS, discovery_protocol([ {
	eventId: 'ipv6-event', rspServerAddress: '[2001:db8::2]:8443'
} ]));
result = invoke('get_discovery_status', {
	job_id: ipv6_discovery_id, owner_token: ipv6_discovery_token
});
check(result.success && index(sprintf('%J', result), '1234567890123456') < 0 &&
	index(sprintf('%J', result), 'ipv6-event') < 0,
	'discovery status never exposes retained IMEI or EventID');

reset();
result = invoke('discover_profiles', { smds: '', imei: '' });
const failed_exit_discovery_id = result.data.job_id;
const failed_exit_discovery_token = result.data.owner_token;
complete_async_job(DOWNLOAD_EXIT_FAILED, discovery_protocol([ {
	eventId: 'must-not-be-retained-after-failed-exit',
	rspServerAddress: 'rsp.example.com'
} ]));
result = invoke('get_discovery_status', {
	job_id: failed_exit_discovery_id,
	owner_token: failed_exit_discovery_token
});
check(!result.success && result.error == 'execution_failed' &&
	global.TEST_RANDOM_OPEN_COUNT == 1 && length(global.TEST_TIMERS) == 3,
	'a successful discovery envelope cannot retain EventIDs after a non-success exit');

reset();
result = invoke('discover_profiles', { smds: '', imei: '' });
const missing_stage_discovery_id = result.data.job_id;
const missing_stage_discovery_token = result.data.owner_token;
complete_async_job(DOWNLOAD_EXIT_SUCCESS, terminal([ {
	eventId: 'must-not-be-retained-before-all-stages',
	rspServerAddress: 'rsp.example.com'
} ]));
result = invoke('get_discovery_status', {
	job_id: missing_stage_discovery_id,
	owner_token: missing_stage_discovery_token
});
check(!result.success && result.error == 'execution_failed' &&
	global.TEST_RANDOM_OPEN_COUNT == 1 && length(global.TEST_TIMERS) == 3,
	'discovery EventIDs are not normalized before every required stage is proven');

for (let args in [
	{ smds: '-a', imei: '' },
	{ smds: 'smds.example.com/path', imei: '' },
	{ smds: 'smds_example.com', imei: '' },
	{ smds: 'smds.example.com:0', imei: '' },
	{ smds: '999.999.999.999', imei: '' },
	{ smds: 'smds.example.com', imei: '1234567890123' },
	{ smds: 'smds.example.com', imei: '12345678901234\n' }
]) {
	reset();
	result = invoke('discover_profiles', args);
	check(!result.success && result.error == 'invalid_argument' &&
		global.TEST_LAST_PROCESS === null,
		'malformed asynchronous discovery arguments are rejected before spawn');
}

reset();
result = invoke('discover_profiles', { smds: '', imei: '' });
const malformed_discovery_id = result.data.job_id;
const malformed_discovery_token = result.data.owner_token;
complete_async_job(DOWNLOAD_EXIT_FAILED, '{"type":"progress",bad}\n');
result = invoke('get_discovery_status', {
	job_id: malformed_discovery_id, owner_token: malformed_discovery_token
});
check(!result.success && result.error == 'invalid_response',
	'malformed discovery NDJSON fails closed');

reset();
result = invoke('discover_profiles', { smds: '', imei: '' });
const truncated_discovery_id = result.data.job_id;
const truncated_discovery_token = result.data.owner_token;
emit_async_output(substr(discovery_protocol([]), 0, 20));
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_FAILED);
end_async_output();
result = invoke('get_discovery_status', {
	job_id: truncated_discovery_id, owner_token: truncated_discovery_token
});
check(!result.success && result.error == 'invalid_response',
	'truncated discovery NDJSON is not accepted as a terminal result');

reset();
result = invoke('discover_profiles', { smds: '', imei: '' });
const excessive_lines_id = result.data.job_id;
const excessive_lines_token = result.data.owner_token;
emit_async_output(make_text('{}\n', 129));
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_FAILED);
end_async_output();
result = invoke('get_discovery_status', {
	job_id: excessive_lines_id, owner_token: excessive_lines_token
});
check(!result.success && result.error == 'output_too_large',
	'discovery line-count overflow is killed and normalized safely');

reset();
result = invoke('discover_profiles', { smds: '', imei: '' });
const discovery_timeout_id = result.data.job_id;
const discovery_timeout_token = result.data.owner_token;
global.TEST_TIMERS[0].callback();
check(global.TEST_TIMERS[2].timeout == 1000,
	'discovery timeout first closes liveness and grants its guardian time to kill');
global.TEST_LAST_PROCESS.output(0);
end_async_output();
result = invoke('get_discovery_status', {
	job_id: discovery_timeout_id, owner_token: discovery_timeout_token
});
check(!result.success && result.error == 'timeout',
	'discovery watchdog produces a terminal timeout only after process and EOF');

reset();
result = invoke('discover_profiles', { smds: '', imei: '' });
const fragmented_identity_job = result.data.job_id;
const fragmented_identity_token = result.data.owner_token;
global.TEST_OUTPUT_PIPE.identity_emitted = true;
emit_async_output('@luci-lpac-pgid:54');
emit_async_output('32\n' + discovery_protocol([]));
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_SUCCESS);
end_async_output();
result = invoke('get_discovery_status', {
	job_id: fragmented_identity_job, owner_token: fragmented_identity_token
});
check(result.success && result.data.status == 'success',
	'a fragmented supervisor identity frame is reconstructed before lpac NDJSON');

for (let identity_case in [
	'',
	'@luci-lpac-pgid:not-a-pid\n',
	'@luci-lpac-pgid:4321\n'
]) {
	reset();
	result = invoke('discover_profiles', { smds: '', imei: '' });
	const identity_job = result.data.job_id;
	const identity_token = result.data.owner_token;
	global.TEST_OUTPUT_PIPE.identity_emitted = true;
	complete_async_job(DOWNLOAD_EXIT_SUCCESS,
		identity_case + discovery_protocol([]));
	result = invoke('get_discovery_status', {
		job_id: identity_job, owner_token: identity_token
	});
	check(!result.success && result.error == 'invalid_response',
		'a missing, malformed, or outer-equal supervisor identity fails closed');
}

reset();
result = invoke('discover_profiles', { smds: '', imei: '' });
const duplicate_identity_job = result.data.job_id;
const duplicate_identity_token = result.data.owner_token;
emit_async_output('@luci-lpac-pgid:5432\n' + discovery_protocol([]));
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_SUCCESS);
end_async_output();
result = invoke('get_discovery_status', {
	job_id: duplicate_identity_job, owner_token: duplicate_identity_token
});
check(!result.success && result.error == 'invalid_response',
	'a duplicate supervisor identity frame cannot be interpreted as lpac output');

reset();
result = invoke('discover_profiles', { smds: '', imei: '' });
const read_failure_job = result.data.job_id;
const read_failure_token = result.data.owner_token;
global.TEST_PIPE_READ_THROW = true;
global.TEST_LAST_HANDLE.callback(1, false, false);
exhaust_async_cleanup();
result = invoke('get_discovery_status', {
	job_id: read_failure_job, owner_token: read_failure_token
});
check(!result.success && result.error == 'invalid_response' &&
	invoke('get_discovery_status', { job_id: 0, owner_token: '' }).data.status == 'idle',
	'a permanent async read failure reaches a bounded fail-closed terminal state');

reset();
result = invoke('discover_profiles', { smds: '', imei: '' });
const rearm_failure_discovery = result.data.job_id;
const rearm_failure_discovery_token = result.data.owner_token;
global.TEST_HANDLE_NULL_AT = 2;
global.TEST_LAST_HANDLE.callback(1, false, false);
exhaust_async_cleanup();
result = invoke('get_discovery_status', {
	job_id: rearm_failure_discovery,
	owner_token: rearm_failure_discovery_token
});
check(!result.success && result.error == 'invalid_response',
	'a permanent async watcher-rearm failure cannot remain running');

reset();
result = invoke('discover_profiles', { smds: '', imei: '' });
const missing_eof_job = result.data.job_id;
const missing_eof_token = result.data.owner_token;
emit_async_output('');
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_FAILED);
exhaust_async_cleanup();
result = invoke('get_discovery_status', {
	job_id: missing_eof_job, owner_token: missing_eof_token
});
check(!result.success && result.error == 'invalid_response',
	'an async process callback without pipe EOF reaches bounded terminal cleanup');

reset();
result = invoke('discover_profiles', { smds: '', imei: '' });
const failed_cleanup_timer_job = result.data.job_id;
const failed_cleanup_timer_token = result.data.owner_token;
global.TEST_TIMER_SET_FAIL = true;
global.TEST_PIPE_READ_THROW = true;
global.TEST_LAST_HANDLE.callback(1, false, false);
result = invoke('get_discovery_status', {
	job_id: failed_cleanup_timer_job,
	owner_token: failed_cleanup_timer_token
});
check(!result.success && result.error == 'invalid_response',
	'a cleanup-timer arm failure forces an immediate terminal error');

reset();
result = invoke('process_notification', {
	seq: '77', remove_after_success: false
});
const bounded_notification_job = result.data.job_id;
const bounded_notification_token = result.data.owner_token;
emit_async_output('');
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_FAILED);
exhaust_async_cleanup();
result = invoke('get_notification_status', {
	job_id: bounded_notification_job,
	owner_token: bounded_notification_token
});
check(!result.success && result.error == 'invalid_response' &&
	result.reason == 'provider_outcome_unknown' &&
	json(global.TEST_SAFETY_UCI.state.notifications)['77'].state ==
		'provider_outcome_unknown',
	'a notification missing EOF terminates bounded with a durable replay guard');

reset();
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal(null) };
result = invoke('set_default_smdp', { address: 'rsp.default.example.com:443' });
check(result.success && result.data === null,
	'a validated default SM-DP+ address can be updated');
same(oneshot_child_argv(),
	[ '/usr/bin/flock', '-n', '/var/run/luci-lpac.lock', '/usr/bin/lpac',
		'chip', 'defaultsmdp', 'rsp.default.example.com:443' ],
	'default SM-DP+ update uses fixed argv under the shared eUICC lock');
for (let address in [
	'', '-a', 'https://rsp.example.com', 'rsp.example.com/path',
	'rsp_example.com', 'rsp.example.com\nsecond', 'rsp.example.com:0'
]) {
	result = invoke('set_default_smdp', { address });
	check(!result.success && result.error == 'invalid_argument',
		sprintf('invalid default SM-DP+ %J is rejected (success=%J error=%J)',
			address, result.success, result.error));
}

reset();
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal(null) };
result = invoke('remove_all_notifications');
check(result.success && result.data === null,
	'standalone Remove all normalizes a successful local-only operation');
same(oneshot_child_argv(),
	[ '/usr/bin/flock', '-n', '/var/run/luci-lpac.lock', '/usr/bin/lpac',
		'notification', 'remove', '-a' ],
	'Remove all maps only to the fixed native lpac -a flag');

if (false) {
reset();
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal(null) };
result = invoke('process_notification', {
	seq: '0',
	remove_after_success: false
});
check(result.success && result.data === null,
	'notification sequence zero can be processed without removal');
same(global.TEST_LAST_CALL.request.params,
	[ '-n', '/var/run/luci-lpac.lock', '/usr/bin/lpac',
		'notification', 'process', '0' ],
	'processing without removal uses one canonical sequence argument');

reset();
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal('provider-private-data') };
result = invoke('process_notification', {
	seq: '4294967295',
	remove_after_success: true
});
check(result.success && result.data === null &&
	index(sprintf('%J', result), 'provider-private-data') < 0,
	'notification processing normalizes success without forwarding provider data');
same(global.TEST_LAST_CALL.request.params,
	[ '-n', '/var/run/luci-lpac.lock', '/usr/bin/lpac',
		'notification', 'process', '-r', '4294967295' ],
	'removal is requested only through the fixed process -r flag');
check(!invoke('process_notification', {
	seq: '01', remove_after_success: false
}).success && !invoke('process_notification', {
	seq: '1', remove_after_success: 'true'
}).success && !invoke('process_notification', {
	seq: '4294967296', remove_after_success: true
}).success,
	'notification processing rejects non-canonical sequences and non-boolean flags');

const notification_stage_failures = [
	{
		stage: 'es10b_retrieve_notifications_list',
		reason: 'notification_retrieve_failed'
	},
	{
		stage: 'es9p_handle_notification',
		reason: 'provider_outcome_unknown'
	},
	{
		stage: 'es10b_remove_notification_from_list',
		reason: 'provider_accepted_remove_failed'
	}
];

for (let failure_case in notification_stage_failures) {
	reset();
	global.TEST_EXEC_REPLY = {
		code: 255,
		stdout: terminal('provider-private-detail', -1, failure_case.stage)
	};
	result = invoke('process_notification', {
		seq: '7', remove_after_success: true
	});
	check(!result.success && result.error == 'lpac_error' &&
		result.reason == failure_case.reason && !('code' in result) &&
		index(sprintf('%J', result), failure_case.stage) < 0 &&
		index(sprintf('%J', result), 'provider-private-detail') < 0,
		'exact notification failure stages map to safe retry-state reasons');
}

for (let stage in [
	'es9p_handle_notification_extra',
	'ES9P_HANDLE_NOTIFICATION',
	'unknown-provider-stage'
]) {
	reset();
	global.TEST_EXEC_REPLY = {
		code: 255,
		stdout: terminal('do-not-forward', -1, stage)
	};
	result = invoke('process_notification', {
		seq: '7', remove_after_success: false
	});
	check(!result.success && result.error == 'lpac_error' &&
		result.reason == 'provider_outcome_unknown' && !('code' in result) &&
		index(sprintf('%J', result), stage) < 0 &&
		index(sprintf('%J', result), 'do-not-forward') < 0,
		'unknown or spoofed notification stages remain redacted and uncertain');
}

reset();
global.TEST_EXEC_STATUS = 7;
result = invoke('process_notification', {
	seq: '7', remove_after_success: false
});
check(!result.success && result.error == 'timeout' &&
	result.reason == 'provider_outcome_unknown',
	'notification execution timeout never encourages a blind provider retry');
}

reset();
result = invoke('process_notification', {
	seq: '0', remove_after_success: false
});
const notification_job_id = result.data?.job_id;
const notification_owner_token = result.data?.owner_token;
check(result.success && result.data.status == 'running' &&
	result.data.phase == 'retrieving' &&
	match(notification_owner_token, /^[A-Za-z0-9_-]{32}$/) !== null,
	'notification processing starts an owner-scoped asynchronous job');
const notification_lpac_index = index(global.TEST_LAST_PROCESS.arguments,
	'/usr/bin/lpac');
same(slice(global.TEST_LAST_PROCESS.arguments, notification_lpac_index), [
	'/usr/bin/lpac', 'notification', 'process', '0'
], 'notification sequence zero remains a canonical fixed argv element');
const pending_notification_safety = json(global.TEST_SAFETY_UCI.state.notifications);
check(pending_notification_safety['0'].state == 'provider_delivery_possible',
	'notification replay guard is durable before the provider child starts');
result = invoke('get_notification_status', {
	job_id: notification_job_id,
	owner_token: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
});
check(!result.success && result.error == 'not_authorized',
	'a wrong notification owner token cannot inspect terminal state');
complete_async_job(DOWNLOAD_EXIT_SUCCESS,
	notification_protocol('0', false, terminal('provider-private-data')));
result = invoke('get_notification_status', {
	job_id: notification_job_id, owner_token: notification_owner_token
});
check(result.success && result.data.status == 'success' &&
	result.data.safety_state == 'provider_accepted_local_record_retained' &&
	result.data.replay_blocked &&
	index(sprintf('%J', result), 'provider-private-data') < 0,
	'accepted notification without removal is redacted and durably replay-blocked');
check(json(global.TEST_SAFETY_UCI.state.notifications)['0'].state ==
	'provider_accepted_local_record_retained',
	'accepted-without-remove state survives page and rpcd lifetime boundaries');
const restarted_notification_methods = fresh_backend_methods();
const processes_before_notification_restart = length(global.TEST_PROCESSES);
result = invoke_with(restarted_notification_methods, 'process_notification', {
	seq: '0', remove_after_success: false
});
check(!result.success && result.error == 'retry_blocked' &&
	result.reason == 'provider_accepted_local_record_retained' &&
	length(global.TEST_PROCESSES) == processes_before_notification_restart,
	'a fresh rpcd plugin instance reloads and enforces the persisted replay guard');
const notification_process_count = length(global.TEST_PROCESSES);
result = invoke('process_notification', {
	seq: '0', remove_after_success: false
});
check(!result.success && result.error == 'retry_blocked' &&
	result.reason == 'provider_accepted_local_record_retained' &&
	length(global.TEST_PROCESSES) == notification_process_count,
	'a retained accepted record cannot be sent to its provider twice');

global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal([ {
		seqNumber: 0,
		profileManagementOperation: 'install',
		notificationAddress: 'rsp.example.com',
		iccid: '8912345678901234567'
	} ])
};
result = invoke('list_notifications');
check(result.success && result.data[0].replay_blocked &&
	result.data[0].safety_state == 'provider_accepted_local_record_retained',
	'authoritative notification refresh annotates a retained replay block');
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal(null) };
result = invoke('remove_all_notifications');
check(result.success && safety_notifications_empty(),
	'successful local Remove all clears notification replay guards');

reset();
result = invoke('process_notification', {
	seq: '4294967295', remove_after_success: true
});
const remove_notification_job = result.data.job_id;
const remove_notification_token = result.data.owner_token;
const remove_lpac_index = index(global.TEST_LAST_PROCESS.arguments, '/usr/bin/lpac');
same(slice(global.TEST_LAST_PROCESS.arguments, remove_lpac_index), [
	'/usr/bin/lpac', 'notification', 'process', '-r', '4294967295'
], 'notification removal is requested only through the fixed -r argv flag');
complete_async_job(DOWNLOAD_EXIT_SUCCESS,
	notification_protocol('4294967295', true, terminal(null)));
result = invoke('get_notification_status', {
	job_id: remove_notification_job, owner_token: remove_notification_token
});
check(result.success && result.data.safety_state == 'clear' &&
	!result.data.replay_blocked && safety_notifications_empty(),
	'verified provider success plus local removal clears its exact guard');

reset();
result = invoke('process_notification', {
	seq: '7', remove_after_success: true
});
const remove_failed_job = result.data.job_id;
const remove_failed_token = result.data.owner_token;
complete_async_job(DOWNLOAD_EXIT_FAILED,
	progress('es10b_retrieve_notifications_list', '7') +
	progress('es9p_handle_notification', '7') +
	progress('es10b_remove_notification_from_list', '7') +
	terminal(null, -1, 'es10b_remove_notification_from_list'));
result = invoke('get_notification_status', {
	job_id: remove_failed_job, owner_token: remove_failed_token
});
check(!result.success && result.reason == 'provider_accepted_remove_failed' &&
	json(global.TEST_SAFETY_UCI.state.notifications)['7'].state ==
		'provider_accepted_remove_failed',
	'provider acceptance followed by local remove failure uses the approved durable state');

reset();
result = invoke('process_notification', {
	seq: '8', remove_after_success: false
});
const provider_unknown_job = result.data.job_id;
const provider_unknown_token = result.data.owner_token;
complete_async_job(DOWNLOAD_EXIT_FAILED,
	progress('es10b_retrieve_notifications_list', '8') +
	progress('es9p_handle_notification', '8') +
	terminal(null, -1, 'es9p_handle_notification'));
result = invoke('get_notification_status', {
	job_id: provider_unknown_job, owner_token: provider_unknown_token
});
check(!result.success && result.reason == 'provider_outcome_unknown' &&
	json(global.TEST_SAFETY_UCI.state.notifications)['8'].state ==
		'provider_outcome_unknown',
	'provider-stage failure remains replay-blocked across reload and reboot');

reset();
result = invoke('process_notification', {
	seq: '9', remove_after_success: false
});
const retrieve_failed_job = result.data.job_id;
const retrieve_failed_token = result.data.owner_token;
complete_async_job(DOWNLOAD_EXIT_FAILED,
	progress('es10b_retrieve_notifications_list', '9') +
	terminal(null, -1, 'es10b_retrieve_notifications_list'));
result = invoke('get_notification_status', {
	job_id: retrieve_failed_job, owner_token: retrieve_failed_token
});
check(!result.success && result.reason == 'notification_retrieve_failed' &&
	safety_notifications_empty(),
	'a proven pre-provider retrieve failure clears its conservative start guard');

reset();
global.TEST_PROCESS_NULL = true;
result = invoke('process_notification', {
	seq: '10', remove_after_success: false
});
check(!result.success && result.error == 'execution_failed' &&
	safety_notifications_empty(),
	'a pre-launch process failure rolls back its exact notification guard');

reset();
result = invoke('process_notification', {
	seq: '11', remove_after_success: false
});
const missing_notification_job = result.data.job_id;
const missing_notification_token = result.data.owner_token;
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_NOT_FOUND);
end_async_output();
result = invoke('get_notification_status', {
	job_id: missing_notification_job, owner_token: missing_notification_token
});
check(!result.success && result.error == 'not_installed' &&
	safety_notifications_empty(),
	'a proven pre-provider missing executable clears its replay guard');

reset();
result = invoke('process_notification', {
	seq: '12', remove_after_success: false
});
const malformed_notification_job = result.data.job_id;
const malformed_notification_token = result.data.owner_token;
complete_async_job(DOWNLOAD_EXIT_FAILED,
	progress('es9p_handle_notification', '12') + terminal(null, -1,
		'es9p_handle_notification'));
result = invoke('get_notification_status', {
	job_id: malformed_notification_job, owner_token: malformed_notification_token
});
check(!result.success && result.error == 'invalid_response' &&
	result.reason == 'provider_outcome_unknown',
	'out-of-order notification protocol fails closed and retains its guard');

reset();
result = invoke('process_notification', {
	seq: '13', remove_after_success: false
});
const notification_timeout_job = result.data.job_id;
const notification_timeout_token = result.data.owner_token;
global.TEST_TIMERS[0].callback();
global.TEST_LAST_PROCESS.output(0);
end_async_output();
result = invoke('get_notification_status', {
	job_id: notification_timeout_job, owner_token: notification_timeout_token
});
check(!result.success && result.error == 'timeout' &&
	result.reason == 'provider_outcome_unknown',
	'notification timeout never permits an automatic provider retry');

reset();
check(!invoke('process_notification', {
	seq: '01', remove_after_success: false
}).success && !invoke('process_notification', {
	seq: '1', remove_after_success: 'true'
}).success && !invoke('process_notification', {
	seq: '4294967296', remove_after_success: true
}).success,
	'async notification start rejects non-canonical sequences and non-boolean flags');

reset();
result = invoke('enable_profile', {
	iccid: 'A0000005591010FFFFFFFF8900001000',
	refresh: true
});
check(!result.success && result.error == 'execution_failed',
	'missing lpac output is handled without exposing process data');
same(oneshot_child_argv(), [
	'/usr/bin/flock', '-n', '/var/run/luci-lpac.lock', '/usr/bin/lpac',
	'profile', 'enable',
	'A0000005591010FFFFFFFF8900001000', '1'
], 'flock, profile AID, and refresh flag remain separate argv elements');
check(!invoke('enable_profile', {
	iccid: '891234567890123456789',
	refresh: false
}).success, 'ICCID longer than the lpac 20-digit buffer is rejected');
reset();
check(!invoke('enable_profile', {
	iccid: '8912345678901234567\n',
	refresh: false
}).success && global.TEST_LAST_CALL === null,
	'a newline-suffixed ICCID never reaches a profile-operation argv');
check(!invoke('disable_profile', {
	iccid: 'A0000005591010FFFFFFFF8900001000\n',
	refresh: false
}).success && global.TEST_LAST_CALL === null,
	'a newline-suffixed AID never reaches a profile-operation argv');
check(!invoke('nickname_profile', {
	iccid: 'A0000005591010FFFFFFFF8900001000',
	nickname: 'Alias'
}).success, 'nickname operation requires an ICCID');

reset();
global.TEST_EXEC_REPLY = { code: 1, stdout: '' };
result = invoke('list_profiles');
check(!result.success && result.error == 'busy', 'concurrent eUICC access is rejected');
check(oneshot_child_argv()[0] == '/usr/bin/flock',
	'eUICC one-shot operations are serialized inside the supervised child group');

reset();
global.TEST_LOCK_BUSY = true;
result = invoke('set_config', { config: default_config() });
check(!result.success && result.error == 'busy',
	'configuration writes share the eUICC operation lock');
check(global.TEST_LOCK_CLOSED, 'busy configuration lock handle is closed');

reset();
global.TEST_EXEC_STATUS = 7;
result = invoke('list_profiles');
check(!result.success && result.error == 'timeout', 'file.exec timeout is normalized');

reset();
global.TEST_EXEC_REPLY = { code: 70, stdout: '' };
result = invoke('list_profiles');
check(!result.success && result.error == 'timeout',
	'the internal one-shot watchdog has a deterministic timeout result');

reset();
global.TEST_EXEC_STATUS = 8;
result = invoke('list_profiles');
check(!result.success && result.error == 'output_too_large',
	'rpcd file.exec 256-KiB saturation is normalized as bounded-output failure');

reset();
global.TEST_EXEC_REPLY = { code: 0, stdout: make_text('X', 65537) };
result = invoke('list_profiles');
check(!result.success && result.error == 'output_too_large',
	'one-shot stdout is rejected at the stricter 64-KiB backend boundary');

reset();
global.TEST_EXEC_REPLY = { code: 0, stdout: '{"type":"lpa",bad}\n' };
result = invoke('list_profiles');
check(!result.success && result.error == 'invalid_response',
	'one-shot malformed JSON is rejected atomically');

reset();
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: '{"type":"lpa","payload":{"code":0,"message":"success","data":[]}}'
};
result = invoke('list_profiles');
check(!result.success && result.error == 'invalid_response',
	'a one-shot terminal record without its final newline is rejected as truncated');

reset();
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal([]) + terminal([]) };
result = invoke('list_profiles');
check(!result.success && result.error == 'invalid_response',
	'multiple one-shot terminal records are rejected');

reset();
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal([]) + progress('late-progress', null)
};
result = invoke('list_profiles');
check(!result.success && result.error == 'invalid_response',
	'one-shot data after a terminal record invalidates the complete response');

reset();
global.TEST_EXEC_REPLY = { code: 1, stdout: terminal('private detail', -1) };
result = invoke('delete_profile', { iccid: '8912345678901234567' });
check(!result.success && result.error == 'lpac_error' &&
	!('data' in result) && !('reason' in result) && !('code' in result),
	'unknown lpac error payload and generic -1 code are not returned');

reset();
global.TEST_EXEC_REPLY = {
	code: 255,
	stdout: terminal('profile not in disabled state', -1)
};
result = invoke('enable_profile', {
	iccid: '8912345678901234567',
	refresh: false
});
check(!result.success && result.error == 'lpac_error' &&
	result.reason == 'profile_not_disabled' && !('data' in result),
	'known profile errors are mapped to safe reason codes');

reset();
global.TEST_EXEC_REPLY = {
	code: 255,
	stdout: terminal('iccid or aid not found', -1)
};
result = invoke('delete_profile', { iccid: '8912345678901234567' });
check(!result.success && result.error == 'lpac_error' &&
	!('reason' in result) && !('data' in result),
	'identifier hints are limited to operations that offer both identifiers');

reset();
let config = default_config();
config.at.device = '/dev/ttyUSB2;reboot';
result = invoke('set_config', { config });
check(!result.success && result.error == 'invalid_config',
	'shell-like device paths are rejected');

for (let device_case in [
	{ section: 'at', value: '/dev/ttyUSB2\n' },
	{ section: 'uqmi', value: '/dev/cdc-wdm0\n' },
	{ section: 'mbim', value: '/dev/cdc-wdm0\n' }
]) {
	reset();
	config = default_config();
	config[device_case.section].device = device_case.value;
	result = invoke('set_config', { config });
	check(!result.success && result.error == 'invalid_config',
		'control-suffixed AT, UQMI, and MBIM device paths are rejected');
}

reset();
config = default_config();
config.global.custom_isd_r_aid = 'A000000559';
result = invoke('set_config', { config });
check(!result.success && result.error == 'invalid_config',
	'short custom ISD-R AIDs are rejected');

reset();
config = default_config();
config.global.apdu_backend = 'mbim';
config.global.custom_isd_r_aid = 'a0000005591010ffffffff8900000100';
result = invoke('set_config', { config });
check(result.success && global.TEST_UCI.global.apdu_backend == 'mbim' &&
	global.TEST_UCI.global.custom_isd_r_aid == 'A0000005591010FFFFFFFF8900000100',
	'validated settings are committed and canonicalized');

reset();
config = default_config();
config.global.apdu_backend = 'at';
config.at.device = '/dev/serial/by-id/usb-Test_Modem-if00';
config.uqmi.device = '/dev/wwan0qmi0';
result = invoke('set_config', { config });
check(result.success && global.TEST_UCI.at.device == config.at.device,
	'safe serial symlinks and inactive backend device paths are accepted');

reset();
config = default_config();
config.global.apdu_backend = 'at';
config.uqmi.device = '/dev/ttyUSB0';
result = invoke('set_config', { config });
check(!result.success && result.error == 'invalid_config',
	'strict Settings writes require a canonical device for every backend');

reset();
config = default_config();
config.global.apdu_backend = 'pcsc';
result = invoke('set_config', { config });

check(!result.success && result.error == 'invalid_config',
	'the removed PC/SC backend cannot be selected');

reset();
config = default_config();
config.pcsc = { interface: '0' };
result = invoke('set_config', { config });
check(!result.success && result.error == 'invalid_config',
	'legacy PC/SC sections are not accepted through the typed Settings RPC');

reset();
config = default_config();
config.global.apdu_backend = 'uqmi';
config.uqmi.device = '/dev/wwan0qmi0';
result = invoke('set_config', { config });
check(result.success && global.TEST_UCI.uqmi.device == '/dev/wwan0qmi0',
	'an active uqmi backend accepts a canonical detected wwan QMI port');

reset();
config = default_config();
config.global.apdu_backend = 'at';
config.at.device = '/dev/serial/../ttyUSB0';
result = invoke('set_config', { config });
check(!result.success && result.error == 'invalid_config',
	'device paths containing traversal components are rejected');

reset();
config = default_config();
config.mbim.skip_slot_mapping = '0';
result = invoke('set_config', { config });
check(result.success && global.TEST_UCI.mbim.skip_slot_mapping == '0',
	'MBIM slot-mapping preference is validated and committed');

reset();
global.TEST_UCI.mbim.vendor_mode = 'keep';
result = invoke('set_config', { config: default_config() });
check(result.success && global.TEST_UCI.mbim.vendor_mode == 'keep',
	'unmanaged vendor options are preserved by settings writes');

reset();
config = default_config();
config.mbim.skip_slot_mapping = 'yes';
result = invoke('set_config', { config });
check(!result.success && result.error == 'invalid_config',
	'invalid MBIM slot-mapping flags are rejected');

reset();
global.TEST_UCI_LOAD_FAIL = true;
result = invoke('list_profiles');
check(!result.success && result.error == 'invalid_config' &&
	global.TEST_LAST_CALL === null,
	'invalid UCI prevents eUICC process execution');

result = invoke('get_config');
check(!result.success && result.error == 'invalid_config' &&
	sprintf('%J', result.data) == sprintf('%J', default_config()),
	'invalid UCI returns a bounded sanitized recovery configuration');

reset();
global.TEST_UCI_LOAD_FAIL = true;
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal('v2.3.0') };
result = invoke('get_version');
check(result.success && result.data == 'v2.3.0',
	'backend does not pre-block version queries when UCI cannot load');

reset();
global.TEST_UCI.uqmi.device = [ '/dev/cdc-wdm0', '/dev/cdc-wdm0;reboot' ];
result = invoke('list_profiles');
check(!result.success && result.error == 'invalid_config' &&
	global.TEST_LAST_CALL === null,
	'UCI list values cannot bypass scalar path validation');

result = invoke('get_config');
check(!result.success && result.error == 'invalid_config' &&
	result.data.uqmi.device == '/dev/cdc-wdm0',
	'an invalid active backend is accompanied by sanitized recovery data');

reset();
global.TEST_UCI.global.apdu_backend = 'at';
global.TEST_UCI.uqmi.device = [ '/dev/cdc-wdm0', '/dev/cdc-wdm0;reboot' ];
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal([]) };
result = invoke('list_profiles');
check(result.success,
	'an invalid inactive backend does not block operations on the valid active backend');

reset();
const activation_code =
	'lpa:1$smdp.example.com$MATCHING-ID$1.2.840.113549$1';
const confirmation_code = 'confirm-secret';
result = activation_download(
	'LPA:1$smdp.example.com$MATCHING-ID\n$OID', '', '');
check(!result.success && result.error == 'invalid_argument' &&
	global.TEST_LAST_PROCESS === null,
	'a control-suffixed matching ID is rejected before process creation');
result = activation_download(activation_code, '', '12345678901234\n');
check(!result.success && result.error == 'invalid_argument' &&
	global.TEST_LAST_PROCESS === null,
	'a control-suffixed download IMEI is rejected before process creation');

reset();
result = activation_download(activation_code, confirmation_code,
	'1234567890123456');
check(result.success && result.data.status == 'running' &&
	result.data.phase == 'authenticating' &&
	match(result.data.decision_token, /^[A-Za-z0-9_-]{32}$/) !== null,
	'interactive activation download returns one opaque owner token');
const activation_job_id = result.data.job_id;
const activation_token = result.data.decision_token;
same(global.TEST_ACCESS_CALLS, [
	{ path: '/usr/bin/lpac', mode: 'x' },
	{ path: '/usr/bin/setsid', mode: 'x' },
	{ path: '/usr/libexec/luci-lpac-supervisor', mode: 'x' },
	{ path: '/bin/kill', mode: 'x' },
	{ path: '/bin/sh', mode: 'x' }
], 'download startup verifies only fixed packaged supervisor executables');
check(global.TEST_LOCK_FLAGS == 'xn' && global.TEST_LOCK_CLOSED &&
	global.TEST_LOCK_OPEN.mode == 'a' && global.TEST_PIPE_CALL_COUNT == 3 &&
	length(global.TEST_PROC_OPEN_CALLS) >= 3 &&
	global.TEST_PROC_OPEN_CALLS[0].mode == 'we' &&
	global.TEST_PROC_OPEN_CALLS[1].mode == 're' &&
	global.TEST_PROC_OPEN_CALLS[2].mode == 'we',
	'download startup inherits the lock and clones input, output, and liveness parent ends CLOEXEC');
check(length(global.TEST_PROCESSES) == 1 && length(global.TEST_TIMERS) == 4 &&
	length(global.TEST_HANDLES) == 1 &&
	global.TEST_TIMERS[0].timeout == 600000,
	'all pipe watchers and disabled watchdogs exist before process supervision');
check(global.TEST_LAST_PROCESS.executable == '/usr/bin/setsid' &&
	global.TEST_LAST_PROCESS.environment.PATH == '/usr/sbin:/usr/bin:/sbin:/bin',
	'downloads run in a fixed isolated process-group environment');
const activation_argv = global.TEST_LAST_PROCESS.arguments;
const activation_lpac_index = index(activation_argv, '/usr/bin/lpac');
check(activation_argv[0] == '/usr/libexec/luci-lpac-supervisor' &&
	activation_argv[1] == 'download' &&
	match(activation_argv[2], /^[0-9]+$/) !== null &&
	match(activation_argv[3], /^[0-9]+$/) !== null &&
	match(activation_argv[4], /^[0-9]+$/) !== null &&
	activation_lpac_index == 5,
	'fixed packaged supervisor receives only its mode and inherited descriptors before lpac argv');
same(slice(activation_argv, activation_lpac_index), [
	'/usr/bin/lpac', 'profile', 'download', '-p', '-a',
	'LPA:1$smdp.example.com$MATCHING-ID$1.2.840.113549$1',
	'-i', '1234567890123456', '-c', confirmation_code
], 'activation argv always includes the mandatory interactive preview gate');

result = owner_status(activation_job_id, 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
check(result.success && result.data.phase == 'authenticating' &&
	!('preview' in result.data) && !('decision_token' in result.data),
	'unauthorized polling receives only a sanitized running phase');
result = invoke('get_download_status', { job_id: 0, decision_token: activation_token });
check(result.success && result.data.phase == 'authenticating' &&
	!('preview' in result.data) && !('decision_token' in result.data),
	'global polling remains sanitized even when supplied the owner token');
result = invoke('respond_download_preview', {
	job_id: activation_job_id,
	decision_token: activation_token,
	accept: true
});
check(!result.success && result.error == 'not_ready' &&
	length(global.TEST_DECISION_WRITES) == 0,
	'a decision cannot be consumed before the explicit preview event');

const preview_png = b64enc(chr(137, 80, 78, 71, 13, 10, 26, 10));
const metadata_event = download_progress('es8p_meatadata_parse', {
	iccid: '8912345678901234567',
	serviceProviderName: 'Preview Carrier',
	profileName: 'Preview Plan',
	profileClass: 'operational',
	iconType: 'png',
	icon: preview_png
});
const preview_event = download_progress('preview', 'y/n');
emit_download_output(substr(metadata_event, 0, 17));
emit_download_output(substr(metadata_event, 17) + substr(preview_event, 0, 9));
emit_download_output(substr(preview_event, 9));
result = owner_status(activation_job_id, activation_token);
check(result.success && result.data.phase == 'awaiting_confirmation' &&
	result.data.preview.serviceProviderName == 'Preview Carrier' &&
	result.data.preview.iconType == 'png' &&
	result.data.preview.icon == preview_png,
	'fragmented metadata yields a bounded normalized PNG preview icon');
check(global.TEST_TIMERS[1].timeout == 120000 &&
	global.TEST_TIMERS[0].timeout == 130000,
	'prompt grants a fresh full preview window plus cancellation grace');
result = owner_status(activation_job_id, 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB');
check(result.success && result.data.phase == 'awaiting_confirmation' &&
	!('preview' in result.data),
	'wrong-token polling cannot read provider metadata or the null/no-metadata bit');
result = owner_status(activation_job_id, activation_token + '\n');
check(result.success && result.data.phase == 'awaiting_confirmation' &&
	!('preview' in result.data),
	'a control-suffixed owner token cannot disclose preview metadata');
result = invoke('respond_download_preview', {
	job_id: activation_job_id,
	decision_token: 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
	accept: true
});
check(!result.success && result.error == 'not_authorized' &&
	length(global.TEST_DECISION_WRITES) == 0,
	'wrong decision token cannot write to lpac stdin');
result = invoke('respond_download_preview', {
	job_id: activation_job_id,
	decision_token: activation_token + '\n',
	accept: true
});
check(!result.success && result.error == 'not_authorized' &&
	length(global.TEST_DECISION_WRITES) == 0,
	'a control-suffixed decision token cannot write to lpac stdin');
result = invoke('respond_download_preview', {
	job_id: activation_job_id,
	decision_token: activation_token,
	accept: true
});
check(result.success && result.data.phase == 'installing' &&
	length(global.TEST_DECISION_WRITES) == 1 &&
	global.TEST_DECISION_WRITES[0] == 'y\n' &&
	global.TEST_TIMERS[0].timeout == 600000,
	'acceptance writes one y line and grants a fresh installation watchdog');
result = invoke('respond_download_preview', {
	job_id: activation_job_id,
	decision_token: activation_token,
	accept: false
});
check(!result.success && result.error == 'invalid_state' &&
	length(global.TEST_DECISION_WRITES) == 1,
	'preview decisions are atomic and cannot be replayed or reversed');

emit_download_output(download_progress('es10b_prepare_download', 'redacted') +
	terminal({ seqNumber: 9, private: confirmation_code }));
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_SUCCESS);
result = owner_status(activation_job_id, activation_token);
check(result.success && result.data.status == 'running' &&
	result.data.phase == 'installing',
	'process callback alone cannot finalize before the output pipe reaches EOF');
end_download_output();
result = invoke('get_download_status', { job_id: activation_job_id });
check(result.success && result.data.status == 'success' &&
	result.data.phase == 'complete' &&
	index(sprintf('%J', result), confirmation_code) < 0 &&
	!('decision_token' in result.data),
	'verified success requires terminal success, reserved exit 64, and real EOF');
result = invoke('get_download_status', { job_id: 0 });
check(result.success && result.data.status == 'idle' && result.data.phase == 'idle',
	'global status becomes idle after complete process-and-pipe cleanup');

reset();
result = test_download();
const reject_job_id = result.data.job_id;
const reject_token = result.data.decision_token;
emit_download_output(download_progress('preview', 'y/n'));
result = owner_status(reject_job_id, reject_token);
check(result.success && result.data.preview === null,
	'an explicit preview prompt without metadata returns owner-only null');
global.TEST_PIPE_FLUSH_RESULT = null;
result = invoke('respond_download_preview', {
	job_id: reject_job_id, decision_token: reject_token, accept: false
});
check(result.success && result.data.phase == 'cancelling' &&
	global.TEST_DECISION_WRITES[0] == 'n\n' &&
	global.TEST_TIMERS[3].timeout == 10000,
	'OpenWrt-24 null flush result still delivers one fail-closed rejection line');
emit_download_output(terminal('', -1, 'cancelled'));
end_download_output();
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_FAILED);
result = invoke('get_download_status', { job_id: reject_job_id });
check(result.success && result.data.status == 'cancelled' &&
	result.data.phase == 'cancelled',
	'user rejection is a distinct safe terminal state, not an installation error');

reset();
result = test_download();
const corrected_metadata_job = result.data.job_id;
const corrected_metadata_token = result.data.decision_token;
emit_download_output(download_progress('es8p_metadata_parse', {
	serviceProviderName: 'Corrected spelling carrier',
	iconType: 'svg',
	icon: b64enc('<svg/>')
}) + download_progress('preview', 'y/n'));
result = owner_status(corrected_metadata_job, corrected_metadata_token);
check(result.success &&
	result.data.preview.serviceProviderName == 'Corrected spelling carrier' &&
	!('icon' in result.data.preview),
	'corrected metadata spelling is accepted while unsafe SVG remains omitted');
invoke('respond_download_preview', {
	job_id: corrected_metadata_job,
	decision_token: corrected_metadata_token,
	accept: false
});
emit_download_output(terminal('', -1, 'cancelled'));
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_FAILED);
end_download_output();

reset();
result = test_download();
const preview_timeout_job = result.data.job_id;
emit_download_output(download_progress('preview', 'y/n'));
global.TEST_TIMERS[1].callback();
check(length(global.TEST_DECISION_WRITES) == 1 &&
	global.TEST_DECISION_WRITES[0] == 'n\n' &&
	length(global.TEST_SYSTEM_CALLS) == 0 &&
	global.TEST_TIMERS[1].timeout == 10000,
	'preview timeout rejects once and grants bounded cancellation cleanup time');
global.TEST_TIMERS[1].callback();
check(length(global.TEST_SYSTEM_CALLS) == 0 &&
	global.TEST_TIMERS[3].timeout == 1000,
	'preview cleanup grace first closes liveness for the inner-group guardian');
global.TEST_TIMERS[3].callback();
check(length(global.TEST_SYSTEM_CALLS) == 2,
	'the bounded fallback kills both nested and outer isolated process groups');
const portable_kill = global.TEST_SYSTEM_CALLS[0]?.argv;
same(portable_kill, [ '/bin/kill', '-KILL', '--', '-5432' ],
	'procps fallback targets the nested lpac process group first');
same(global.TEST_SYSTEM_CALLS[1].argv,
	[ '/bin/kill', '-KILL', '--', '-4321' ],
	'outer supervisor cleanup follows the nested process-group kill');
emit_download_output(terminal('', -1, 'cancelled'));
global.TEST_LAST_PROCESS.output(0);
end_download_output();
result = invoke('get_download_status', { job_id: preview_timeout_job });
check(!result.success && result.error == 'timeout' &&
	result.reason == 'preview_timeout',
	'preview timeout remains explicit and never claims an unknown install outcome');

reset();
global.TEST_SYSTEM_EXITS = [ 1, 0, 1, 0 ];
result = test_download();
emit_download_output(download_progress('es10b_prepare_download', 'provider'));
check(length(global.TEST_SYSTEM_CALLS) == 0 &&
	global.TEST_TIMERS[3].timeout == 1000,
	'a gate violation first delegates descendant cleanup to the liveness guardian');
global.TEST_TIMERS[3].callback();
same(map(global.TEST_SYSTEM_CALLS, call => call.argv), [
	[ '/bin/kill', '-KILL', '--', '-5432' ],
	[ '/bin/kill', '-KILL', '-5432' ],
	[ '/bin/kill', '-KILL', '--', '-4321' ],
	[ '/bin/kill', '-KILL', '-4321' ]
], 'BusyBox fallback preserves nested-before-outer fixed argv ordering');
check(global.TEST_TIMERS[3].timeout == 1000,
	'successful delivery retains the bounded terminal cleanup watchdog');
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_FAILED);
end_download_output();

reset();
global.TEST_SYSTEM_EXITS = [ 1, 1, 0 ];
result = test_download();
emit_download_output(download_progress('es10b_prepare_download', 'provider'));
check(length(global.TEST_SYSTEM_CALLS) == 0 &&
	global.TEST_TIMERS[3].timeout == 1000,
	'a failed protocol arms the bounded outer-group fallback');
global.TEST_TIMERS[3].callback();
check(length(global.TEST_SYSTEM_CALLS) == 3 &&
	global.TEST_TIMERS[3].timeout == 1000,
	'a failed nested process-group delivery still kills the outer group and rearms');
global.TEST_TIMERS[3].callback();
check(length(global.TEST_SYSTEM_CALLS) == 4 &&
	global.TEST_SYSTEM_CALLS[3].argv[3] == '-5432',
	'the kill retry later succeeds against the still-unconfirmed nested group');
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_FAILED);
end_download_output();

reset();
result = test_download();
const bypass_after_preview_timeout_job = result.data.job_id;
emit_download_output(download_progress('preview', 'y/n'));
global.TEST_TIMERS[1].callback();
emit_download_output(download_progress('es10b_prepare_download', 'provider'));
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_SUCCESS);
end_download_output();
result = invoke('get_download_status', {
	job_id: bypass_after_preview_timeout_job
});
check(!result.success && result.error == 'timeout' &&
	result.reason == 'outcome_unknown',
	'post-gate activity after a timed-out rejection is classified as uncertain');

reset();
result = test_download();
const auth_timeout_job = result.data.job_id;
global.TEST_TIMERS[0].callback();
global.TEST_LAST_PROCESS.output(0);
end_download_output();
result = invoke('get_download_status', { job_id: auth_timeout_job });
check(!result.success && result.error == 'timeout' &&
	!('reason' in result),
	'overall timeout before any y decision is safely known to precede installation');

reset();
result = test_download();
const accepted_timeout_job = result.data.job_id;
const accepted_timeout_token = result.data.decision_token;
emit_download_output(download_progress('preview', 'y/n'));
invoke('respond_download_preview', {
	job_id: accepted_timeout_job,
	decision_token: accepted_timeout_token,
	accept: true
});
global.TEST_TIMERS[0].callback();
global.TEST_LAST_PROCESS.output(0);
end_download_output();
result = invoke('get_download_status', { job_id: accepted_timeout_job });
check(!result.success && result.error == 'timeout' &&
	result.reason == 'outcome_unknown' &&
	result.data.safety.verification_required &&
	match(result.data.safety.incident_id, /^[A-Za-z0-9_-]{32}$/) !== null,
	'any timeout after an attempted y requires profile and notification verification');
const verification_incident = result.data.safety.incident_id;
check(index(sprintf('%J', global.TEST_SAFETY_UCI), activation_code) < 0 &&
	index(sprintf('%J', global.TEST_SAFETY_UCI), confirmation_code) < 0,
	'durable download safety state stores no activation or confirmation credential');
const restarted_download_methods = fresh_backend_methods();
result = invoke_with(restarted_download_methods, 'get_download_status', {
	job_id: 0, decision_token: ''
});
check(result.success && result.data.status == 'idle' &&
	result.data.safety.verification_required &&
	result.data.safety.incident_id == verification_incident,
	'a fresh rpcd plugin instance reloads the exact durable download incident');
result = test_download();
check(!result.success && result.error == 'retry_blocked' &&
	result.reason == 'outcome_unknown',
	'a durable unknown download blocks another activation before verification');
result = invoke('acknowledge_download_verification', {
	incident_id: verification_incident
});
check(!result.success && result.error == 'verification_incomplete' &&
	!result.data.profiles_refreshed && !result.data.notifications_refreshed,
	'acknowledgement cannot bypass both authoritative post-incident reads');
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal([]) };
check(invoke('list_profiles').success,
	'a successful authoritative profile refresh is recorded for the incident');
result = invoke('acknowledge_download_verification', {
	incident_id: verification_incident
});
check(!result.success && result.data.profiles_refreshed &&
	!result.data.notifications_refreshed,
	'one authoritative refresh alone remains insufficient');
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal([]) };
check(invoke('list_notifications').success,
	'a successful authoritative notification refresh is recorded for the incident');
result = invoke('acknowledge_download_verification', {
	incident_id: verification_incident
});
check(result.success && !result.data.verification_required &&
	!('download_incident' in global.TEST_SAFETY_UCI.state),
	'exact incident acknowledgement clears the durable block only after both reads');
result = invoke_with(fresh_backend_methods(), 'get_download_status', {
	job_id: 0, decision_token: ''
});
check(result.success && !result.data.safety.verification_required,
	'a fresh rpcd plugin sees no false download warning after acknowledgement');

reset();
global.TEST_SAFETY_FILE_EXISTS = true;
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal([ {
		seqNumber: 17,
		profileManagementOperation: 'install',
		notificationAddress: 'rsp.example.com',
		iccid: '8912345678901234567'
	} ])
};
result = invoke('list_notifications');
check(result.success && length(result.data) == 1 &&
	result.data[0].replay_blocked !== true &&
	!('safety_state' in result.data[0]),
	'a canonical empty journal leaves valid notifications unprotected');

reset();
global.TEST_SAFETY_FILE_EXISTS = true;
global.TEST_SAFETY_UCI.state.profiles_refreshed = '1';
global.TEST_SAFETY_UCI.state.notifications_refreshed = '1';
global.TEST_SAFETY_UCI.state.notifications = sprintf('%J', {
	'23': {
		incident: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
		state: 'provider_accepted_local_record_retained'
	}
});
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal([ {
		seqNumber: 23,
		profileManagementOperation: 'install',
		notificationAddress: 'rsp.example.com',
		iccid: '8912345678901234567'
	} ])
};
result = invoke_with(fresh_backend_methods(), 'list_notifications');
check(result.success && result.data[0].replay_blocked &&
	result.data[0].safety_state ==
		'provider_accepted_local_record_retained' &&
	global.TEST_SAFETY_UCI.state.profiles_refreshed == '1' &&
	global.TEST_SAFETY_UCI.state.notifications_refreshed == '1' &&
	json(global.TEST_SAFETY_UCI.state.notifications)['23'].incident ==
		'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
	'a missing download option preserves refresh flags and notification incidents');

reset();
global.TEST_SAFETY_FILE_EXISTS = true;
global.TEST_SAFETY_UCI.state.unexpected = 'value';
check(safety_state_invalid(),
	'an unexpected safety option is rejected by the exact journal schema');

reset();
global.TEST_SAFETY_FILE_EXISTS = true;
global.TEST_SAFETY_UCI.extra = { '.type': 'safety', schema: '1' };
check(safety_state_invalid(),
	'an additional safety section is rejected rather than ignored');

reset();
global.TEST_SAFETY_FILE_EXISTS = true;
delete global.TEST_SAFETY_UCI.state.notifications_refreshed;
check(safety_state_invalid(),
	'a safety section missing one required option fails closed');

reset();
global.TEST_SAFETY_FILE_EXISTS = true;
global.TEST_SAFETY_UCI.state['.type'] = 'unexpected';
check(safety_state_invalid(),
	'a safety section with the wrong UCI type is rejected');

reset();
global.TEST_SAFETY_FILE_EXISTS = true;
global.TEST_SAFETY_UCI.state.schema = '2';
check(safety_state_invalid(),
	'an unknown safety journal schema is never interpreted as the current format');

reset();
global.TEST_SAFETY_FILE_EXISTS = true;
global.TEST_SAFETY_UCI.state.download_incident = 'malformed';
check(safety_state_invalid(),
	'a non-empty malformed download incident token still fails closed');

reset();
global.TEST_SAFETY_FILE_EXISTS = true;
global.TEST_SAFETY_UCI.state.notifications = sprintf('%J', {
	'1': {
		incident: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
		state: 'provider_outcome_unknown',
		unexpected: true
	}
});
check(safety_state_invalid(),
	'a notification replay record with extra keys is rejected');

reset();
global.TEST_SAFETY_FILE_EXISTS = true;
const excessive_safety_notifications = {};
for (let i = 0; i < 257; i++)
	excessive_safety_notifications[`${i}`] = {
		incident: sprintf('%032d', i + 1),
		state: 'provider_outcome_unknown'
	};
global.TEST_SAFETY_UCI.state.notifications = sprintf('%J',
	excessive_safety_notifications);
check(safety_state_invalid(),
	'a safety journal beyond the 256-notification bound fails closed');

for (let file_case in [
	{ type: 'symlink', uid: 0, nlink: 1 },
	{ type: 'file', uid: 1, nlink: 1 },
	{ type: 'file', uid: 0, nlink: 2 }
]) {
	reset();
	global.TEST_SAFETY_FILE_EXISTS = true;
	global.TEST_SAFETY_FILE_TYPE = file_case.type;
	global.TEST_SAFETY_FILE_UID = file_case.uid;
	global.TEST_SAFETY_FILE_NLINK = file_case.nlink;
	check(safety_state_invalid(),
		'a non-regular, non-root-owned, or multiply-linked safety file is rejected');
}

reset();
global.TEST_SAFETY_FILE_EXISTS = true;
global.TEST_SAFETY_FILE_MODE = 0o644;
check(!safety_state_invalid() && global.TEST_SAFETY_FILE_MODE == 0o600,
	'a valid permissive safety file is repaired to mode 0600 before use');

reset();
global.TEST_SAFETY_COMMIT_OK = false;
const processes_before_failed_safety_commit = length(global.TEST_PROCESSES);
result = invoke('process_notification', {
	seq: '87', remove_after_success: false
});
check(!result.success && result.error == 'safety_state_failed' &&
	safety_notifications_empty() &&
	length(global.TEST_PROCESSES) == processes_before_failed_safety_commit,
	'a failed safety commit publishes no staged replay guard or provider job');

reset();
global.TEST_SAFETY_UCI_LOAD_FAIL_AT = 3;
const processes_before_failed_safety_readback = length(global.TEST_PROCESSES);
result = invoke('process_notification', {
	seq: '87', remove_after_success: false
});
check(!result.success && result.error == 'safety_state_failed' &&
	json(global.TEST_SAFETY_UCI.state.notifications)['87'].state ==
		'provider_delivery_possible' &&
	length(global.TEST_PROCESSES) == processes_before_failed_safety_readback,
	'a committed guard remains fail-closed when its fresh readback fails');

reset();
global.TEST_SAFETY_UCI_UNLOAD_FAIL_AT = 2;
result = invoke('process_notification', {
	seq: '87', remove_after_success: false
});
check(result.success && result.data.status == 'running' &&
	json(global.TEST_SAFETY_UCI.state.notifications)['87'].state ==
		'provider_delivery_possible',
	'an exact fresh readback remains authoritative after writer cleanup fails');
const unload_failure_job = result.data.job_id;
const unload_failure_owner = result.data.owner_token;
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_NOT_FOUND);
end_async_output();
result = invoke('get_notification_status', {
	job_id: unload_failure_job, owner_token: unload_failure_owner
});
check(!result.success && result.error == 'not_installed' &&
	safety_notifications_empty(),
	'the writer-cleanup regression job releases its conservative replay guard');

reset();
global.TEST_SAFETY_FILE_EXISTS = true;
global.TEST_SAFETY_UCI.state.download_incident =
	'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
global.TEST_SAFETY_COMMIT_OK = false;
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal([]) };
result = invoke('list_profiles');
check(!result.success && result.error == 'safety_state_failed',
	'a profile refresh reports failure when its verification flag cannot persist');

reset();
global.TEST_SAFETY_FILE_EXISTS = true;
global.TEST_SAFETY_UCI.state.download_incident =
	'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
global.TEST_SAFETY_COMMIT_OK = false;
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal([]) };
result = invoke('list_notifications');
check(!result.success && result.error == 'safety_state_failed',
	'an empty notification refresh still reports a failed safety-state commit');

reset();
result = invoke('process_notification', {
	seq: '88', remove_after_success: false
});
const failed_notification_commit_job = result.data.job_id;
const failed_notification_commit_token = result.data.owner_token;
global.TEST_SAFETY_COMMIT_OK = false;
complete_async_job(DOWNLOAD_EXIT_SUCCESS,
	notification_protocol('88', false, terminal(null)));
result = invoke('get_notification_status', {
	job_id: failed_notification_commit_job,
	owner_token: failed_notification_commit_token
});
check(!result.success && result.error == 'safety_state_failed' &&
	result.reason == 'provider_outcome_unknown',
	'a provider result is never published as safe when replay-state persistence fails');

reset();
global.TEST_SAFETY_FILE_EXISTS = true;
global.TEST_SAFETY_UCI.state.download_incident =
	'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal([]) };
global.TEST_DEFER_QUEUE = true;
invoke('list_profiles');
global.TEST_DEFER_QUEUE = false;
global.TEST_SAFETY_UCI.state.download_incident =
	'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB';
const delayed_profiles = shift(global.TEST_DEFERRED_CALLS);
delayed_profiles.callback(delayed_profiles.status, delayed_profiles.reply);
check(global.TEST_SAFETY_UCI.state.download_incident ==
	'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB' &&
	global.TEST_SAFETY_UCI.state.profiles_refreshed == '0',
	'a delayed Profiles callback cannot verify a newer download incident');

reset();
global.TEST_SAFETY_FILE_EXISTS = true;
global.TEST_SAFETY_UCI.state.notifications = sprintf('%J', {
	'9': {
		incident: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
		state: 'provider_outcome_unknown'
	}
});
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal([]) };
global.TEST_DEFER_QUEUE = true;
invoke('list_notifications');
global.TEST_DEFER_QUEUE = false;
global.TEST_SAFETY_UCI.state.notifications = sprintf('%J', {
	'9': {
		incident: 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
		state: 'provider_delivery_possible'
	}
});
const delayed_notifications = shift(global.TEST_DEFERRED_CALLS);
delayed_notifications.callback(delayed_notifications.status,
	delayed_notifications.reply);
check(json(global.TEST_SAFETY_UCI.state.notifications)['9'].incident ==
	'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
	'a delayed Notifications callback cannot prune a newer replay incident');

reset();
global.TEST_SAFETY_FILE_EXISTS = true;
global.TEST_SAFETY_UCI.state.notifications = sprintf('%J', {
	'10': {
		incident: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
		state: 'provider_outcome_unknown'
	}
});
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal(null) };
global.TEST_DEFER_QUEUE = true;
invoke('remove_all_notifications');
global.TEST_DEFER_QUEUE = false;
global.TEST_SAFETY_UCI.state.notifications = sprintf('%J', {
	'10': {
		incident: 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
		state: 'provider_delivery_possible'
	}
});
const delayed_remove_all = shift(global.TEST_DEFERRED_CALLS);
delayed_remove_all.callback(delayed_remove_all.status,
	delayed_remove_all.reply);
check(json(global.TEST_SAFETY_UCI.state.notifications)['10'].incident ==
	'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
	'a delayed Remove-all callback cannot clear a newer replay incident');

reset();
global.TEST_SAFETY_FILE_EXISTS = true;
global.TEST_SAFETY_UCI_LOAD_FAIL = true;
result = invoke('get_download_status', { job_id: 0, decision_token: '' });
const recovery_incident = result.data.safety.incident_id;
check(result.success && result.data.safety.verification_required &&
	result.data.safety.state_invalid && valid_secret_for_test(recovery_incident),
	'a syntactically invalid safety UCI enters explicit fail-closed recovery');
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal([]) };
check(invoke('list_profiles').success, 'invalid safety UCI still permits profile verification');
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal([]) };
check(invoke('list_notifications').success,
	'invalid safety UCI still permits notification verification');
result = invoke('acknowledge_download_verification', {
	incident_id: recovery_incident
});
check(result.success && !global.TEST_SAFETY_UCI_LOAD_FAIL &&
	global.TEST_SAFETY_UCI.state.schema == '1' &&
	!('download_incident' in global.TEST_SAFETY_UCI.state) &&
	length(global.TEST_TEMP_FILES) == 0,
	'verified acknowledgement atomically repairs a root-owned corrupt safety file');
result = invoke_with(fresh_backend_methods(), 'get_download_status', {
	job_id: 0, decision_token: ''
});
check(result.success && !result.data.safety.verification_required,
	'a repaired canonical journal does not create a false download warning');

reset();
global.TEST_SAFETY_FILE_EXISTS = true;
global.TEST_SAFETY_UCI_LOAD_FAIL = true;
result = invoke('get_download_status', { job_id: 0, decision_token: '' });
const guarded_recovery_incident = result.data.safety.incident_id;
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal([]) };
check(invoke('list_profiles').success,
	'corrupt-journal recovery records an authoritative Profiles refresh');
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal([ {
		seqNumber: 23,
		profileManagementOperation: 'install',
		notificationAddress: 'rsp.example.com',
		iccid: '8912345678901234567'
	} ])
};
result = invoke('list_notifications');
check(result.success && result.data[0].replay_blocked &&
	result.data[0].safety_state == 'safety_state_failed',
	'notifications remain fail-closed while a corrupt journal is verified');
result = invoke('acknowledge_download_verification', {
	incident_id: guarded_recovery_incident
});
const recovered_notifications = json(
	global.TEST_SAFETY_UCI.state.notifications);
check(result.success &&
	!('download_incident' in global.TEST_SAFETY_UCI.state) &&
	recovered_notifications['23'].state == 'provider_outcome_unknown' &&
	valid_secret_for_test(recovered_notifications['23'].incident),
	'raw journal repair preserves visible notifications as conservative guards');
const guarded_recovery_methods = fresh_backend_methods();
result = invoke_with(guarded_recovery_methods, 'list_notifications');
check(result.success && result.data[0].replay_blocked &&
	result.data[0].safety_state == 'provider_outcome_unknown',
	'a fresh backend reloads the recovered notification replay guard');
const processes_before_recovered_retry = length(global.TEST_PROCESSES);
result = invoke_with(guarded_recovery_methods, 'process_notification', {
	seq: '23', remove_after_success: false
});
check(!result.success && result.error == 'retry_blocked' &&
	result.reason == 'provider_outcome_unknown' &&
	length(global.TEST_PROCESSES) == processes_before_recovered_retry,
	'a recovered protected notification cannot be automatically resent');

reset();
global.TEST_SAFETY_FILE_EXISTS = true;
global.TEST_SAFETY_UCI.state.download_incident =
	'DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD';
global.TEST_SAFETY_UCI.state.notifications = sprintf('%J', {
	'31': {
		incident: 'EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE',
		state: 'provider_accepted_local_record_retained'
	}
});
global.TEST_SAFETY_UCI_LOAD_FAIL_UNTIL = 7;
global.TEST_SAFETY_UCI_LOAD_FAIL_AT = 9;
result = invoke('get_download_status', { job_id: 0, decision_token: '' });
const transient_recovery_incident = result.data.safety.incident_id;
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal([]) };
check(invoke('list_profiles').success,
	'a transient recovery can record its authoritative Profiles refresh');
global.TEST_EXEC_REPLY = {
	code: 0,
	stdout: terminal([ {
		seqNumber: 31,
		profileManagementOperation: 'install',
		notificationAddress: 'rsp.example.com',
		iccid: '8912345678901234567'
	} ])
};
check(invoke('list_notifications').success,
	'a transient recovery can record its authoritative Notifications refresh');
result = invoke('acknowledge_download_verification', {
	incident_id: transient_recovery_incident
});
const preserved_transient_notifications = json(
	global.TEST_SAFETY_UCI.state.notifications);
check(!result.success && result.error == 'not_authorized' &&
	global.TEST_SAFETY_UCI.state.download_incident ==
		'DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD' &&
	preserved_transient_notifications['31'].incident ==
		'EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE' &&
	preserved_transient_notifications['31'].state ==
		'provider_accepted_local_record_retained' &&
	!length(global.TEST_UCI_COMMIT_CALLS) &&
	global.TEST_SAFETY_UCI_LOAD_COUNT == 8 &&
	!length(global.TEST_TEMP_FILES),
	'a transient recovery cannot overwrite a journal that becomes valid');
global.TEST_SAFETY_UCI_LOAD_FAIL = true;
result = invoke('get_download_status', { job_id: 0, decision_token: '' });
check(result.success && result.data.safety.state_invalid &&
	valid_secret_for_test(result.data.safety.incident_id) &&
	result.data.safety.incident_id != transient_recovery_incident &&
	!result.data.safety.profiles_refreshed &&
	!result.data.safety.notifications_refreshed,
	'a superseded recovery cannot reuse its token or completed refresh flags');

reset();
result = test_download();
const ambiguous_write_job = result.data.job_id;
const ambiguous_write_token = result.data.decision_token;
emit_download_output(download_progress('preview', 'y/n'));
global.TEST_PIPE_WRITE_PARTIAL = true;
result = invoke('respond_download_preview', {
	job_id: ambiguous_write_job,
	decision_token: ambiguous_write_token,
	accept: true
});
check(!result.success && result.reason == 'outcome_unknown' &&
	result.data.safety.verification_required &&
	valid_secret_for_test(result.data.safety.incident_id),
	'an ambiguous acceptance write returns its durable incident immediately');
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_FAILED);
end_download_output();

reset();
result = test_download();
const bypass_job = result.data.job_id;
emit_download_output(download_progress('es10b_prepare_download', 'provider'));
check(length(global.TEST_SYSTEM_CALLS) == 0 &&
	global.TEST_TIMERS[3].timeout == 1000,
	'post-gate progress before y immediately closes supervisor liveness');
emit_download_output(terminal({ installed: true }));
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_SUCCESS);
end_download_output();
result = invoke('get_download_status', { job_id: bypass_job });
check(!result.success && result.error == 'execution_failed' &&
	result.reason == 'outcome_unknown',
	'a violated mandatory gate is never reported as safely not installed');

reset();
result = test_download();
const trailing_record_job = result.data.job_id;
emit_download_output(download_progress('preview', 'y/n'));
invoke('respond_download_preview', {
	job_id: trailing_record_job,
	decision_token: result.data.decision_token,
	accept: true
});
emit_download_output(terminal(null) +
	download_progress('es10b_load_bound_profile_package', 'late'));
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_SUCCESS);
end_download_output();
result = invoke('get_download_status', { job_id: trailing_record_job });
check(!result.success && result.reason == 'outcome_unknown',
	'a recognized record after terminal success invalidates outcome verification');

reset();
result = test_download();
const malformed_job = result.data.job_id;
emit_download_output('{"type":"progress",bad}\n');
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_FAILED);
result = invoke('get_download_status', { job_id: malformed_job });
check(result.success && result.data.status == 'running',
	'protocol failure still waits for actual output EOF after leader exit');
end_download_output();
result = invoke('get_download_status', { job_id: malformed_job });
check(!result.success && result.reason == 'preview_protocol_error',
	'malformed NDJSON fails closed without fabricating EOF or outcome uncertainty');

reset();
result = test_download();
const truncated_job = result.data.job_id;
emit_download_output(substr(download_progress('preview', 'y/n'), 0, 20));
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_FAILED);
end_download_output();
result = invoke('get_download_status', { job_id: truncated_job });
check(!result.success && result.reason == 'preview_protocol_error',
	'a non-newline NDJSON tail is rejected as truncated protocol data');

reset();
result = test_download();
const oversized_output_job = result.data.job_id;
emit_download_output(make_text('X', 70000));
for (let i = 0; i < 20 && length(global.TEST_OUTPUT_PIPE.buffer); i++)
	global.TEST_TIMERS[2].callback();
check(!length(global.TEST_OUTPUT_PIPE.buffer) &&
	length(global.TEST_SYSTEM_CALLS) == 0 &&
	global.TEST_TIMERS[3].timeout == 1000,
	'oversized output is drained in bounded chunks while guardian cleanup starts');
global.TEST_TIMERS[3].callback();
check(length(global.TEST_SYSTEM_CALLS) >= 2,
	'oversized-output cleanup targets nested and outer process groups');
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_FAILED);
result = invoke('get_download_status', { job_id: oversized_output_job });
check(result.success && result.data.status == 'running',
	'oversized output never fabricates EOF after only the leader callback');
end_download_output();
result = invoke('get_download_status', { job_id: oversized_output_job });
check(!result.success && result.reason == 'preview_protocol_error',
	'oversized output reaches a safe terminal state only after real pipe EOF');

reset();
const whitespace_confirmation = '  confirmation value  ';
result = test_download(whitespace_confirmation);
check(index(global.TEST_LAST_PROCESS.arguments, whitespace_confirmation) >= 0,
	'backend preserves confirmation-code whitespace as exact hashed input bytes');
const whitespace_confirmation_job = result.data.job_id;
const whitespace_confirmation_token = result.data.decision_token;
emit_download_output(download_progress('preview', 'y/n'));
invoke('respond_download_preview', {
	job_id: whitespace_confirmation_job,
	decision_token: whitespace_confirmation_token,
	accept: false
});
emit_download_output(terminal('', -1, 'cancelled'));
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_FAILED);
end_download_output();

reset();
const copied_speedtest =
	'\t\u200b  LPA:1$rsp.truphone.com$QRF-SPEEDTEST\u2060\ufeff\r\n';
result = activation_download(copied_speedtest, '', '');
check(result.success && index(global.TEST_LAST_PROCESS.arguments,
	'LPA:1$rsp.truphone.com$QRF-SPEEDTEST') >= 0,
	'copied Speedtest activation code is normalized only at its boundaries');
const speedtest_job = result.data.job_id;
emit_download_output(download_progress('preview', 'y/n'));
invoke('respond_download_preview', {
	job_id: speedtest_job,
	decision_token: result.data.decision_token,
	accept: false
});
emit_download_output(terminal('', -1, 'cancelled'));
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_FAILED);
end_download_output();

reset();
result = activation_download(make_text('A', 4097), '', '');
check(!result.success && result.error == 'invalid_argument' &&
	global.TEST_LAST_PROCESS === null,
	'oversized activation codes are rejected before pipe or process creation');
result = invoke('download_profile', {
	activation_code: '',
	smdp: 'smdp.example.com/endpoint',
	matching_id: 'MATCH',
	imei: '',
	confirmation_code: ''
});
check(!result.success && result.error == 'invalid_argument' &&
	global.TEST_LAST_PROCESS === null,
	'removed manual parameters cannot start a profile download');

reset();
global.TEST_PIPE_CLONE_FAIL = true;
result = test_download();
check(!result.success && result.error == 'execution_failed' &&
	global.TEST_LAST_PROCESS === null && global.TEST_LOCK_CLOSED,
	'pipe clone failure closes preflight resources before any provider process');
global.TEST_PIPE_CLONE_FAIL = false;
result = test_download();
check(result.success,
	'pipe setup failure leaves no stale running job or lock');
const recovery_job = result.data.job_id;
emit_download_output(download_progress('preview', 'y/n'));
invoke('respond_download_preview', {
	job_id: recovery_job,
	decision_token: result.data.decision_token,
	accept: false
});
emit_download_output(terminal('', -1, 'cancelled'));
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_FAILED);
end_download_output();

reset();
global.TEST_PROCESS_NULL = true;
result = test_download();
check(!result.success && result.error == 'execution_failed' &&
	global.TEST_LOCK_CLOSED && global.TEST_PIPE_CLOSE_COUNT >= 6,
	'a null process spawn closes both child and parent pipe resources');

reset();
global.TEST_TIMER_NULL_AT = 3;
result = test_download();
check(!result.success && result.error == 'execution_failed' &&
	global.TEST_LAST_PROCESS === null,
	'a missing preallocated drain timer prevents unsafe process creation');

reset();
global.TEST_HANDLE_NULL = true;
result = test_download();
check(!result.success && result.error == 'execution_failed' &&
	global.TEST_LAST_PROCESS === null,
	'a missing output watcher prevents a credential-bearing child from spawning');

reset();
global.TEST_HANDLE_NULL_AT = 2;
result = test_download();
const rearm_failure_job = result.data.job_id;
emit_download_output(download_progress('preview', 'y/n'));
check(global.TEST_TIMERS[2].timeout == 100 &&
	global.TEST_TIMERS[3].timeout == 1000 &&
	length(global.TEST_SYSTEM_CALLS) == 0,
	'post-spawn watcher rearm failure retains its reader and schedules safe drain');
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_FAILED);
global.TEST_OUTPUT_PIPE.eof = true;
global.TEST_TIMERS[2].callback();
result = invoke('get_download_status', { job_id: rearm_failure_job });
check(!result.success && result.reason == 'preview_protocol_error',
	'drain retry observes real EOF before finalizing a watcher failure');

reset();
result = test_download();
const bounded_download_read_job = result.data.job_id;
global.TEST_PIPE_READ_THROW = true;
global.TEST_LAST_HANDLE.callback(1, false, false);
exhaust_download_cleanup();
result = invoke('get_download_status', { job_id: bounded_download_read_job });
check(!result.success && result.error == 'execution_failed' &&
	result.reason == 'preview_protocol_error',
	'a permanent download read failure reaches bounded terminal cleanup');

reset();
result = test_download();
const bounded_accepted_job = result.data.job_id;
const bounded_accepted_token = result.data.decision_token;
emit_download_output(download_progress('preview', 'y/n'));
invoke('respond_download_preview', {
	job_id: bounded_accepted_job,
	decision_token: bounded_accepted_token,
	accept: true
});
global.TEST_PIPE_READ_THROW = true;
global.TEST_LAST_HANDLE.callback(1, false, false);
exhaust_download_cleanup();
result = invoke('get_download_status', { job_id: bounded_accepted_job });
check(!result.success && result.error == 'execution_failed' &&
	result.reason == 'outcome_unknown' &&
	result.data.safety.verification_required,
	'forced cleanup after acceptance retains a durable unknown-outcome block');

reset();
result = test_download();
const bounded_missing_eof_download = result.data.job_id;
emit_download_output('');
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_FAILED);
exhaust_download_cleanup();
result = invoke('get_download_status', { job_id: bounded_missing_eof_download });
check(!result.success && result.error == 'execution_failed' &&
	result.reason == 'preview_protocol_error',
	'a download process callback without EOF cannot remain running indefinitely');

reset();
result = test_download();
const failed_drain_timer_download = result.data.job_id;
global.TEST_TIMER_SET_FAIL = true;
emit_download_output(make_text('X', 9000));
result = invoke('get_download_status', { job_id: failed_drain_timer_download });
check(!result.success && result.error == 'execution_failed' &&
	result.reason == 'preview_protocol_error',
	'a failed download drain-timer arm forces an immediate terminal error');

reset();
result = invoke('get_download_status', { job_id: 2147483647 });
check(!result.success && result.error == 'job_not_found',
	'unknown but well-formed download job IDs are rejected');
check(invoke('get_download_status', { job_id: 0 }).success &&
	!invoke('get_download_status', { job_id: -1 }).success &&
	!invoke('get_download_status', { job_id: '1' }).success &&
	!invoke('get_download_status', { job_id: 2147483648 }).success,
	'current-job sentinel is accepted while malformed or out-of-range IDs are rejected');

reset();
const discovered_event_secret = 'DISCOVERY-EVENT-SECRET';
const discovered_imei = '1234567890123456';
result = invoke('discover_profiles', {
	smds: 'lpa.ds.gsma.com', imei: discovered_imei
});
const discovered_source_job = result.data.job_id;
const discovered_source_token = result.data.owner_token;
complete_async_job(DOWNLOAD_EXIT_SUCCESS, discovery_protocol([ {
	eventId: discovered_event_secret,
	rspServerAddress: 'discovered.example.com'
} ]));
result = invoke('get_discovery_status', {
	job_id: discovered_source_job, owner_token: discovered_source_token
});
const discovered_entry_id = result.data.results[0].entry_id;
const discovered_expiry_timer = global.TEST_TIMERS[3];
check(result.success && index(sprintf('%J', result), discovered_event_secret) < 0 &&
	index(sprintf('%J', result), discovered_imei) < 0,
	'discovery exposes only an opaque entry ID and safe server display value');

global.TEST_PROCESS_NULL = true;
result = invoke('download_discovered_profile', {
	entry_id: discovered_entry_id,
	confirmation_code: 'discovery-confirmation-secret'
});
check(!result.success && result.error == 'execution_failed' &&
	index(sprintf('%J', result), discovered_event_secret) < 0,
	'a failed discovered-profile spawn returns no hidden EventID or IMEI');
check(!discovered_expiry_timer.cancelled &&
	discovered_expiry_timer.timeout == 300000,
	'a failed spawn restores the claimed discovery entry with its original expiry');

global.TEST_PROCESS_NULL = false;
result = invoke('download_discovered_profile', {
	entry_id: discovered_entry_id,
	confirmation_code: 'discovery-confirmation-secret'
});
check(result.success && result.data.status == 'running' &&
	discovered_expiry_timer.cancelled,
	'a restored discovery capability can be consumed exactly once');
const discovered_job_id = result.data.job_id;
const discovered_token = result.data.decision_token;
const discovered_argv = global.TEST_LAST_PROCESS.arguments;
const discovered_lpac_index = index(discovered_argv, '/usr/bin/lpac');
same(slice(discovered_argv, discovered_lpac_index), [
	'/usr/bin/lpac', 'profile', 'download', '-p',
	'-s', 'discovered.example.com', '-m', discovered_event_secret,
	'-i', discovered_imei, '-c', 'discovery-confirmation-secret'
], 'discovered download reuses hidden EventID, server, and original IMEI as argv');
check(index(sprintf('%J', result), discovered_event_secret) < 0 &&
	index(sprintf('%J', result), discovered_imei) < 0,
	'discovered start response contains only job ownership state');

emit_download_output(download_progress('preview', 'y/n'));
invoke('respond_download_preview', {
	job_id: discovered_job_id,
	decision_token: discovered_token,
	accept: false
});
emit_download_output(terminal('', -1, 'cancelled'));
global.TEST_LAST_PROCESS.output(DOWNLOAD_EXIT_FAILED);
end_download_output();
result = invoke('download_discovered_profile', {
	entry_id: discovered_entry_id, confirmation_code: ''
});
check(!result.success && result.error == 'entry_unavailable',
	'a successfully spawned discovered entry is permanently consumed');

printf(`1..${checks}\n`);
