// SPDX-License-Identifier: Apache-2.0

'use strict';

const DOWNLOAD_EXIT_SUCCESS = 64;
const DOWNLOAD_EXIT_NOT_FOUND = 65;
const DOWNLOAD_EXIT_NOT_EXECUTABLE = 66;
const DOWNLOAD_EXIT_FAILED = 67;
const DOWNLOAD_EXIT_SIGNALED = 68;

function default_config() {
	return {
		global: {
			apdu_backend: 'mbim',
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
			skip_slot_mapping: '1'
		}
	};
}

function reset() {
	global.TEST_UCI = default_config();
	global.TEST_UCI_LOAD_FAIL = false;
	global.TEST_COMMIT_OK = true;
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
	global.TEST_DEFER_THROW = false;
	global.TEST_DEFER_NULL = false;
	global.TEST_EXEC_STATUS = 0;
	global.TEST_EXEC_REPLY = null;
	global.TEST_LAST_CALL = null;
	global.TEST_LPAC_ACCESS = true;
	global.TEST_ACCESS_FAIL_PATH = null;
	global.TEST_ACCESS_CALLS = [];
	global.TEST_PROCESS_THROW = false;
	global.TEST_PROCESS_NULL = false;
	global.TEST_PROCESS_PID_THROW = false;
	global.TEST_PROCESS_PID = 4321;
	global.TEST_PROCESSES = [];
	global.TEST_LAST_PROCESS = null;
	global.TEST_TIMER_THROW = false;
	global.TEST_TIMER_NULL = false;
	global.TEST_TIMERS = [];
	global.TEST_LAST_TIMER = null;
	global.TEST_TIMER_CANCEL_COUNT = 0;
	global.TEST_SYSTEM_EXIT = 0;
	global.TEST_SYSTEM_THROW = false;
	global.TEST_SYSTEM_CALLS = [];
	global.system = function(argv, timeout) {
		push(global.TEST_SYSTEM_CALLS, { argv, timeout });

		if (global.TEST_SYSTEM_THROW)
			die('system failed');

		return global.TEST_SYSTEM_EXIT;
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

function invoke(name, args) {
	let replied = false;
	let response = null;
	const request = {
		args: args || {},
		reply: function(result) {
			replied = true;
			response = result;
		}
	};
	const returned = methods[name].call(request);

	return replied ? response : returned;
}

function activation_download(code, confirmation, imei) {
	return invoke('download_profile', {
		mode: 'activation',
		activation_code: code,
		smdp: '',
		matching_id: '',
		imei: imei || '',
		confirmation_code: confirmation || ''
	});
}

function manual_download(smdp, matching_id, confirmation, imei) {
	return invoke('download_profile', {
		mode: 'manual',
		activation_code: '',
		smdp: smdp || '',
		matching_id: matching_id || '',
		imei: imei || '',
		confirmation_code: confirmation || ''
	});
}

function complete_download(exit_code) {
	global.TEST_LAST_PROCESS.output(exit_code);
}

function make_text(character, count) {
	let value = '';

	for (let i = 0; i < count; i++)
		value += character;

	return value;
}

function terminal(data, code) {
	if (type(code) != 'int')
		code = 0;

	return sprintf('%J\n', {
		type: 'lpa',
		payload: {
			code,
			message: code == 0 ? 'success' : 'failure',
			data
		}
	});
}

global.TEST_EXEC_REPLY = { code: 0, stdout: terminal('v2.3.0') };
let result = invoke('get_version');
check(result.success && result.data == 'v2.3.0', 'version response is normalized');
check(global.TEST_LAST_CALL.request.command == '/usr/bin/lpac',
	'packaged lpac entrypoint is executed directly for non-eUICC commands');
same(global.TEST_LAST_CALL.request.params, [ 'version' ], 'version argv is fixed');

reset();
result = invoke('get_config');
same(result.data, default_config(),
	'configuration reads expose the normalized MBIM slot-mapping preference');

reset();
delete global.TEST_UCI.global.apdu_backend;
delete global.TEST_UCI.mbim.skip_slot_mapping;
result = invoke('get_config');
check(result.success && result.data.global.apdu_backend == 'mbim' &&
	result.data.mbim.skip_slot_mapping == '1',
	'missing release options fall back to MBIM with slot mapping skipped');

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
			icon: 'sensitive-base64-icon',
			profileClass: 'operational'
		},
		{ iccid: '../../invalid', isdpAid: null }
	])
};
result = invoke('list_profiles');
check(result.success && length(result.data) == 1, 'invalid profile records are discarded');
check(!('icon' in result.data[0]), 'profile icons are never returned to LuCI');

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
global.TEST_EXEC_REPLY = { code: 0, stdout: terminal(null) };
result = invoke('remove_notification', { seq: '4294967295' });
check(result.success, 'UINT32_MAX notification can be removed');
	same(global.TEST_LAST_CALL.request.params,
		[ '-n', '/var/run/luci-lpac.lock', '/usr/bin/lpac',
		'notification', 'remove', '4294967295' ],
	'flock and notification arguments remain separate argv elements');
check(!invoke('remove_notification', { seq: '0' }).success &&
	!invoke('remove_notification', { seq: '01' }).success &&
	!invoke('remove_notification', { seq: '4294967296' }).success,
	'invalid notification sequences are rejected');

reset();
result = invoke('enable_profile', {
	iccid: 'A0000005591010FFFFFFFF8900001000',
	refresh: true
});
check(!result.success && result.error == 'execution_failed',
	'missing lpac output is handled without exposing process data');
same(global.TEST_LAST_CALL.request.params, [
	'-n', '/var/run/luci-lpac.lock', '/usr/bin/lpac', 'profile', 'enable',
	'A0000005591010FFFFFFFF8900001000', '1'
], 'flock, profile AID, and refresh flag remain separate argv elements');
check(!invoke('enable_profile', {
	iccid: '891234567890123456789',
	refresh: false
}).success, 'ICCID longer than the lpac 20-digit buffer is rejected');
check(!invoke('nickname_profile', {
	iccid: 'A0000005591010FFFFFFFF8900001000',
	nickname: 'Alias'
}).success, 'nickname operation requires an ICCID');

reset();
global.TEST_EXEC_REPLY = { code: 1, stdout: '' };
result = invoke('list_profiles');
check(!result.success && result.error == 'busy', 'concurrent eUICC access is rejected');
check(global.TEST_LAST_CALL.request.command == '/usr/bin/flock',
	'eUICC operations are serialized by inherited flock');

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
global.TEST_EXEC_REPLY = { code: 1, stdout: terminal('private detail', -1) };
result = invoke('delete_profile', { iccid: '8912345678901234567' });
check(!result.success && result.error == 'lpac_error' &&
	!('data' in result) && !('reason' in result),
	'unknown lpac error payload is not returned');

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
config.global.apdu_backend = 'uqmi';
config.uqmi.device = '/dev/wwan0qmi0';
result = invoke('set_config', { config });
check(!result.success && result.error == 'invalid_config',
	'active uqmi backend retains its strict control-device allowlist');

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

reset();
const activation_code =
	'lpa:1$smdp.example.com$MATCHING-ID$1.2.840.113549$1';
const confirmation_code = 'confirm-secret';
result = activation_download(activation_code, confirmation_code, '1234567890123456');
check(result.success && result.data.status == 'running' &&
	type(result.data.job_id) == 'int',
	'activation-code downloads start as asynchronous jobs');
const activation_job_id = result.data.job_id;
same(global.TEST_ACCESS_CALLS, [
	{ path: '/usr/bin/lpac', mode: 'x' },
	{ path: '/usr/bin/setsid', mode: 'x' },
	{ path: '/bin/kill', mode: 'x' }
], 'download startup verifies lpac and its fixed process supervisor tools');
check(global.TEST_LOCK_FLAGS == 'xn' && global.TEST_LOCK_CLOSED &&
	global.TEST_LOCK_CLOSE_COUNT == 1 && global.TEST_OPEN.mode == 'a',
	'download startup passes an inheritable shared lock to the process group');
check(length(global.TEST_PROCESSES) == 1 && length(global.TEST_TIMERS) == 1 &&
	length(global.TEST_SYSTEM_CALLS) == 0,
	'download startup returns after registering one process and one timer');
check(global.TEST_LAST_PROCESS.executable == '/usr/bin/setsid' &&
	global.TEST_LAST_TIMER.timeout == 600000,
	'downloads run in an isolated process group with a ten-minute timer');
same(global.TEST_LAST_PROCESS.environment,
	{ PATH: '/usr/sbin:/usr/bin:/sbin:/bin' },
	'the supervisor receives only the fixed command search path');
same(global.TEST_LAST_PROCESS.arguments, [
	'/bin/sh', '-c', '"$@" >/dev/null 2>&1\n' +
		'code=$?\n' +
		'[ "$code" -eq 0 ] && exit 64\n' +
		'[ "$code" -eq 127 ] && exit 65\n' +
		'[ "$code" -eq 126 ] && exit 66\n' +
		'[ "$code" -ge 128 ] && [ "$code" -lt 255 ] && exit 68\n' +
		'exit 67',
	'luci-lpac-download', '/usr/bin/lpac', 'profile', 'download', '-a',
	'LPA:1$smdp.example.com$MATCHING-ID$1.2.840.113549$1',
	'-i', '1234567890123456', '-c', confirmation_code
], 'the fixed redirection script keeps activation values in positional argv');
check(index(global.TEST_LAST_PROCESS.arguments[2], confirmation_code) < 0 &&
	index(global.TEST_LAST_PROCESS.arguments[2], 'MATCHING-ID') < 0,
	'the fixed shell program contains no activation or confirmation secret');
result = invoke('get_download_status', { job_id: activation_job_id });
check(result.success && result.data.status == 'running',
	'running download jobs can be polled without exposing arguments');
result = invoke('get_download_status', { job_id: 0 });
check(result.success && result.data.status == 'running' &&
	result.data.job_id == activation_job_id,
	'the current-job query can recover a running download after UI state loss');
complete_download(DOWNLOAD_EXIT_SUCCESS);
result = invoke('get_download_status', { job_id: activation_job_id });
check(result.success && result.data.status == 'success' &&
	index(sprintf('%J', result), confirmation_code) < 0 &&
	index(sprintf('%J', result), 'MATCHING-ID') < 0 &&
	global.TEST_TIMER_CANCEL_COUNT == 1,
	'success polling is redacted and completion cancels the watchdog');
result = invoke('get_download_status', { job_id: 0 });
check(result.success && result.data.status == 'idle' && !('job_id' in result.data),
	'the current-job query does not replay stale terminal jobs');

reset();
const copied_speedtest =
	'\t\u200b  LPA:1$rsp.truphone.com$QRF-SPEEDTEST\u2060\ufeff\r\n';
result = activation_download(copied_speedtest, '', '');
check(result.success && result.data.status == 'running',
	'harmless whitespace and invisible formatting at activation-code edges are accepted');
const speedtest_job_id = result.data.job_id;
same(slice(global.TEST_LAST_PROCESS.arguments, 4), [
	'/usr/bin/lpac', 'profile', 'download', '-a',
	'LPA:1$rsp.truphone.com$QRF-SPEEDTEST'
], 'the exact copied Speedtest code is stripped only at its boundaries');
complete_download(DOWNLOAD_EXIT_SUCCESS);
result = invoke('get_download_status', { job_id: speedtest_job_id });
check(result.success && result.data.status == 'success',
	'the normalized copied activation code completes normally');

reset();
result = activation_download('LPA:1$smdp.example.com$', '', '');
check(result.success && result.data.status == 'running',
	'activation codes accept an empty optional matching ID like upstream lpac');
const empty_matching_job_id = result.data.job_id;
same(slice(global.TEST_LAST_PROCESS.arguments, 4), [
	'/usr/bin/lpac', 'profile', 'download', '-a',
	'LPA:1$smdp.example.com$'
], 'an empty activation-code matching ID is preserved in its exact argv element');
complete_download(DOWNLOAD_EXIT_SUCCESS);
check(invoke('get_download_status', { job_id: empty_matching_job_id }).success,
	'activation downloads without a matching ID complete normally');

reset();
result = activation_download('LPA:1$smdp.example.com$MATCH$OID$', '', '');
check(result.success && result.data.status == 'running',
	'an empty optional fifth activation-code field is accepted');
const empty_flag_job_id = result.data.job_id;
same(slice(global.TEST_LAST_PROCESS.arguments, 4), [
	'/usr/bin/lpac', 'profile', 'download', '-a',
	'LPA:1$smdp.example.com$MATCH$OID'
], 'an empty fifth field is omitted for lpac 2.3.0 compatibility');
complete_download(DOWNLOAD_EXIT_SUCCESS);
check(invoke('get_download_status', { job_id: empty_flag_job_id }).success,
	'the canonicalized optional-flag download completes normally');

reset();
result = manual_download('[2001:db8::1]:443', 'MANUAL-ID', '1234',
	'12345678901234');
check(result.success && result.data.status == 'running',
	'manual downloads accept explicit SM-DP+, matching ID, confirmation code, and IMEI');
const manual_job_id = result.data.job_id;
same(slice(global.TEST_LAST_PROCESS.arguments, 4), [
	'/usr/bin/lpac', 'profile', 'download',
	'-s', '[2001:db8::1]:443', '-m', 'MANUAL-ID',
	'-i', '12345678901234', '-c', '1234'
], 'manual download options remain distinct positional argv elements');
complete_download(DOWNLOAD_EXIT_SUCCESS);
check(invoke('get_download_status', { job_id: manual_job_id }).success,
	'manual download completion is pollable');
result = invoke('get_download_status', { job_id: activation_job_id });
check(result.success && result.data.status == 'success',
	'a completed job remains pollable after a later download starts');

reset();
result = manual_download('', '', '', '');
check(result.success && result.data.status == 'running',
	'manual mode may use the eUICC default SM-DP+ without optional flags');
const default_server_job_id = result.data.job_id;
same(slice(global.TEST_LAST_PROCESS.arguments, 4),
	[ '/usr/bin/lpac', 'profile', 'download' ],
	'an empty manual request mirrors the upstream default-server invocation');
complete_download(DOWNLOAD_EXIT_SUCCESS);
result = invoke('get_download_status', { job_id: default_server_job_id });
check(result.success && result.data.status == 'success',
	'default-server download completion is reported');

reset();
result = manual_download('', 'MATCH-ONLY', '', '');
check(result.success, 'manual mode accepts an independently supplied matching ID');
const matching_only_job_id = result.data.job_id;
same(slice(global.TEST_LAST_PROCESS.arguments, 4),
	[ '/usr/bin/lpac', 'profile', 'download', '-m', 'MATCH-ONLY' ],
	'matching-ID-only downloads omit the SM-DP+ flag');
complete_download(DOWNLOAD_EXIT_SUCCESS);
check(invoke('get_download_status', { job_id: matching_only_job_id }).success,
	'matching-ID-only completion is pollable');

reset();
result = activation_download('LPA:1$smdp.example.com$MATCH$OID$1', '', '');
check(!result.success && result.error == 'invalid_argument' &&
	global.TEST_LAST_PROCESS === null,
	'activation codes that require confirmation are rejected without a confirmation code');
result = activation_download('LPA:1$smdp.example.com$BAD_ID', '', '');
check(!result.success && result.error == 'invalid_argument' &&
	global.TEST_LAST_PROCESS === null,
	'activation-code matching IDs use the same strict format as upstream lpac');
result = activation_download('LPA:1$smdp.example.com$MATCH\u2060ID', '', '');
check(!result.success && result.error == 'invalid_argument' &&
	global.TEST_LAST_PROCESS === null,
	'invisible formatting inside an activation secret is never removed silently');
result = activation_download('LPA:1$smdp.example.com/path$MATCH', '', '');
check(!result.success && result.error == 'invalid_argument' &&
	global.TEST_LAST_PROCESS === null,
	'activation-code SM-DP+ values containing URL paths are rejected');
result = activation_download('LPA:1$smdp.example.com$MATCH\nSECOND', '', '');
check(!result.success && result.error == 'invalid_argument' &&
	global.TEST_LAST_PROCESS === null,
	'activation codes containing control characters are rejected');
result = activation_download(make_text('A', 4097), '', '');
check(!result.success && result.error == 'invalid_argument' &&
	global.TEST_LAST_PROCESS === null,
	'oversized activation codes are rejected before process creation');

reset();
result = manual_download('smdp.example.com/endpoint', 'MATCH', '', '');
check(!result.success && result.error == 'invalid_argument' &&
	global.TEST_LAST_PROCESS === null,
	'manual SM-DP+ URL paths are rejected');
result = manual_download('smdp.example.com', 'BAD_ID', '', '');
check(!result.success && result.error == 'invalid_argument' &&
	global.TEST_LAST_PROCESS === null,
	'manual matching IDs containing punctuation are rejected');
result = manual_download('smdp.example.com', 'MATCH', 'bad\ncode', '');
check(!result.success && result.error == 'invalid_argument' &&
	global.TEST_LAST_PROCESS === null,
	'confirmation codes containing control characters are rejected');
result = manual_download('smdp.example.com', 'MATCH', '', '1234');
check(!result.success && result.error == 'invalid_argument' &&
	global.TEST_LAST_PROCESS === null,
	'invalid IMEI lengths are rejected');
result = invoke('download_profile', {
	mode: 'manual',
	activation_code: 'LPA:1$smdp.example.com$MATCH',
	smdp: 'smdp.example.com',
	matching_id: 'MATCH',
	imei: '',
	confirmation_code: ''
});
check(!result.success && result.error == 'invalid_argument' &&
	global.TEST_LAST_PROCESS === null,
	'manual mode cannot mix an activation code with separate parameters');
result = invoke('download_profile', {
	mode: 'other',
	activation_code: '',
	smdp: '',
	matching_id: '',
	imei: '',
	confirmation_code: ''
});
check(!result.success && result.error == 'invalid_argument' &&
	global.TEST_LAST_PROCESS === null,
	'unknown download modes are rejected');

reset();
result = manual_download('smdp.example.com', 'FIRST', 'do-not-return', '');
check(result.success, 'a download can be started for concurrency checks');
const busy_job_id = result.data.job_id;
const busy_process = global.TEST_LAST_PROCESS;
result = manual_download('smdp.example.com', 'SECOND', '', '');
check(!result.success && result.error == 'busy' &&
	length(global.TEST_PROCESSES) == 1 &&
	index(sprintf('%J', result), 'FIRST') < 0,
	'duplicate download requests are rejected without leaking the active secret');
result = invoke('get_download_status', { job_id: 0 });
check(result.success && result.data.job_id == busy_job_id,
	'a client can attach to the active job after a duplicate or lost start response');
global.TEST_LOCK_BUSY = true;
result = invoke('set_config', { config: default_config() });
check(!result.success && result.error == 'busy',
	'the inherited download lock serializes configuration changes');
global.TEST_LOCK_BUSY = false;
global.TEST_LAST_PROCESS = busy_process;
complete_download(DOWNLOAD_EXIT_SUCCESS);
check(invoke('get_download_status', { job_id: busy_job_id }).success,
	'the active job still completes after rejected concurrent operations');

reset();
global.TEST_LOCK_BUSY = true;
result = manual_download('smdp.example.com', 'MATCH', '', '');
check(!result.success && result.error == 'busy' &&
	global.TEST_LAST_PROCESS === null && global.TEST_LOCK_CLOSED,
	'a busy shared lock prevents process creation and closes its handle');

reset();
global.TEST_UCI_LOAD_FAIL = true;
result = manual_download('smdp.example.com', 'MATCH', '', '');
check(!result.success && result.error == 'invalid_config' &&
	length(global.TEST_ACCESS_CALLS) == 0 && global.TEST_LAST_PROCESS === null,
	'invalid UCI prevents executable checks, locking, and process creation');

reset();
global.TEST_LPAC_ACCESS = false;
result = manual_download('smdp.example.com', 'MATCH', '', '');
check(!result.success && result.error == 'not_installed' &&
	global.TEST_LAST_PROCESS === null && !global.TEST_LOCK_EXISTS,
	'a missing or non-executable lpac entrypoint is detected before locking');

reset();
global.TEST_ACCESS_FAIL_PATH = '/usr/bin/setsid';
result = manual_download('smdp.example.com', 'MATCH', '', '');
check(!result.success && result.error == 'not_installed' &&
	global.TEST_LAST_PROCESS === null && !global.TEST_LOCK_EXISTS,
	'a missing process supervisor is detected before locking');

reset();
global.TEST_PROCESS_NULL = true;
result = manual_download('smdp.example.com', 'MATCH', '', '');
check(!result.success && result.error == 'execution_failed' &&
	global.TEST_LOCK_CLOSED && global.TEST_TIMER_CANCEL_COUNT == 1,
	'a null uloop process result cancels its timer and releases the parent lock');
global.TEST_PROCESS_NULL = false;
result = manual_download('smdp.example.com', 'RECOVERY', '', '');
check(result.success, 'process startup failure does not leave a stale running job');
const recovered_job_id = result.data.job_id;
complete_download(DOWNLOAD_EXIT_SUCCESS);
check(invoke('get_download_status', { job_id: recovered_job_id }).success,
	'a job can complete after recovery from process startup failure');

reset();
global.TEST_TIMER_NULL = true;
result = manual_download('smdp.example.com', 'MATCH', '', '');
check(!result.success && result.error == 'execution_failed' &&
	global.TEST_LOCK_CLOSED && global.TEST_LAST_PROCESS === null,
	'a missing watchdog timer prevents process creation and releases the lock');

reset();
global.TEST_TIMER_THROW = true;
result = manual_download('smdp.example.com', 'MATCH', '', '');
check(!result.success && result.error == 'execution_failed' &&
	global.TEST_LOCK_CLOSED && global.TEST_LAST_PROCESS === null &&
	global.TEST_TIMER_CANCEL_COUNT == 0,
	'a thrown watchdog startup failure prevents process creation and releases the lock');

reset();
global.TEST_PROCESS_THROW = true;
result = manual_download('smdp.example.com', 'MATCH', '', '');
check(!result.success && result.error == 'execution_failed' &&
	global.TEST_LOCK_CLOSED && global.TEST_TIMER_CANCEL_COUNT == 1,
	'a thrown process startup failure is normalized and cancels the timer');

reset();
result = manual_download('smdp.example.com', 'MATCH', '', '');
const pid_throw_job_id = result.data.job_id;
global.TEST_PROCESS_PID_THROW = true;
global.TEST_LAST_TIMER.callback();
check(length(global.TEST_SYSTEM_CALLS) == 0 &&
	invoke('get_download_status', { job_id: pid_throw_job_id }).data.status == 'running',
	'a thrown PID lookup cannot signal an unrelated process or finish the job early');
complete_download(DOWNLOAD_EXIT_SUCCESS);
result = invoke('get_download_status', { job_id: pid_throw_job_id });
check(!result.success && result.error == 'timeout' &&
	result.reason == 'outcome_unknown' && global.TEST_TIMER_CANCEL_COUNT == 1,
	'the watchdog remains authoritative when PID lookup throws');

reset();
global.TEST_PROCESS_PID = 1;
result = manual_download('smdp.example.com', 'MATCH', '', '');
const invalid_pid_job_id = result.data.job_id;
global.TEST_LAST_TIMER.callback();
check(length(global.TEST_SYSTEM_CALLS) == 0 &&
	invoke('get_download_status', { job_id: invalid_pid_job_id }).data.status == 'running',
	'an unsafe process-group PID is never passed to kill');
complete_download(DOWNLOAD_EXIT_SUCCESS);
result = invoke('get_download_status', { job_id: invalid_pid_job_id });
check(!result.success && result.error == 'timeout' &&
	result.reason == 'outcome_unknown' && global.TEST_TIMER_CANCEL_COUNT == 1,
	'the watchdog remains authoritative for an invalid process PID');

reset();
global.TEST_SYSTEM_EXIT = 1;
result = manual_download('smdp.example.com', 'MATCH', '', '');
const kill_failure_job_id = result.data.job_id;
global.TEST_LAST_TIMER.callback();
check(length(global.TEST_SYSTEM_CALLS) == 1 &&
	invoke('get_download_status', { job_id: kill_failure_job_id }).data.status == 'running',
	'a failed group-kill command leaves cleanup to the process callback');
complete_download(DOWNLOAD_EXIT_SUCCESS);
result = invoke('get_download_status', { job_id: kill_failure_job_id });
check(!result.success && result.error == 'timeout' &&
	result.reason == 'outcome_unknown' && global.TEST_TIMER_CANCEL_COUNT == 1,
	'the watchdog remains authoritative when group kill returns failure');

reset();
global.TEST_SYSTEM_THROW = true;
result = manual_download('smdp.example.com', 'MATCH', '', '');
const kill_throw_job_id = result.data.job_id;
global.TEST_LAST_TIMER.callback();
check(length(global.TEST_SYSTEM_CALLS) == 1 &&
	invoke('get_download_status', { job_id: kill_throw_job_id }).data.status == 'running',
	'a thrown group-kill error leaves cleanup to the process callback');
complete_download(DOWNLOAD_EXIT_SUCCESS);
result = invoke('get_download_status', { job_id: kill_throw_job_id });
check(!result.success && result.error == 'timeout' &&
	result.reason == 'outcome_unknown' && global.TEST_TIMER_CANCEL_COUNT == 1,
	'the watchdog remains authoritative when group kill throws');

reset();
result = manual_download('smdp.example.com', 'MATCH', 'timeout-secret', '');
const timeout_job_id = result.data.job_id;
global.TEST_LAST_TIMER.callback();
same(global.TEST_SYSTEM_CALLS, [ {
	argv: [ '/bin/kill', '-KILL', '-4321' ],
	timeout: null
} ], 'the timeout kills the entire isolated lpac process group');
result = invoke('get_download_status', { job_id: timeout_job_id });
check(result.success && result.data.status == 'running' &&
	global.TEST_TIMER_CANCEL_COUNT == 0,
	'the timeout callback does not release state or cancel its timer before process reap');
complete_download(0);
result = invoke('get_download_status', { job_id: timeout_job_id });
check(!result.success && result.error == 'timeout' &&
	result.reason == 'outcome_unknown' && !('code' in result) &&
	index(sprintf('%J', result), 'timeout-secret') < 0 &&
	global.TEST_TIMER_CANCEL_COUNT == 1,
	'timeout is redacted and warns that the resulting eUICC state is unknown');

reset();
result = manual_download('smdp.example.com', 'MATCH', '', '');
const supervisor_signal_job_id = result.data.job_id;
complete_download(0);
result = invoke('get_download_status', { job_id: supervisor_signal_job_id });
check(!result.success && result.error == 'execution_failed' &&
	result.reason == 'outcome_unknown' && !('code' in result),
	'a supervisor signal reported as raw zero by uloop is never treated as success');

reset();
result = manual_download('smdp.example.com', 'MATCH', '', '');
const child_signal_job_id = result.data.job_id;
complete_download(DOWNLOAD_EXIT_SIGNALED);
result = invoke('get_download_status', { job_id: child_signal_job_id });
check(!result.success && result.error == 'execution_failed' &&
	result.reason == 'outcome_unknown' && !('code' in result),
	'the wrapper reports a signalled lpac child as an uncertain execution failure');

reset();
result = manual_download('smdp.example.com', 'MATCH', '', '');
const wrapper_missing_job_id = result.data.job_id;
complete_download(DOWNLOAD_EXIT_NOT_FOUND);
result = invoke('get_download_status', { job_id: wrapper_missing_job_id });
check(!result.success && result.error == 'not_installed',
	'a packaged wrapper that cannot exec its lpac binary is mapped as not installed');

reset();
result = manual_download('smdp.example.com', 'MATCH', 'failure-secret', '');
const lpac_failure_job_id = result.data.job_id;
complete_download(DOWNLOAD_EXIT_FAILED);
result = invoke('get_download_status', { job_id: lpac_failure_job_id });
check(!result.success && result.error == 'lpac_error' &&
	result.reason == 'download_failed' && !('code' in result) &&
	index(sprintf('%J', result), 'failure-secret') < 0,
	'the generic lpac failure is mapped without exposing provider, input, or raw 255');

reset();
result = manual_download('smdp.example.com', 'MATCH', '', '');
const noexec_job_id = result.data.job_id;
complete_download(DOWNLOAD_EXIT_NOT_EXECUTABLE);
result = invoke('get_download_status', { job_id: noexec_job_id });
check(!result.success && result.error == 'execution_failed' &&
	!('reason' in result),
	'a non-executable wrapper or binary is reported as an execution failure');

reset();
result = manual_download('smdp.example.com', 'MATCH', '', '');
const supervisor_failure_job_id = result.data.job_id;
complete_download(255);
result = invoke('get_download_status', { job_id: supervisor_failure_job_id });
check(!result.success && result.error == 'execution_failed' &&
	result.reason == 'outcome_unknown' && !('code' in result),
	'an exit outside the fixed wrapper protocol is an uncertain supervisor failure');

reset();
result = manual_download('smdp.example.com', 'MATCH', '', '');
const missing_status_job_id = result.data.job_id;
complete_download(null);
result = invoke('get_download_status', { job_id: missing_status_job_id });
check(!result.success && result.error == 'execution_failed' &&
	result.reason == 'outcome_unknown' && !('code' in result),
	'a missing process status is an uncertain execution failure');

reset();
result = invoke('get_download_status', { job_id: 2147483647 });
check(!result.success && result.error == 'job_not_found',
	'unknown but well-formed download job IDs are rejected');
check(invoke('get_download_status', { job_id: 0 }).success &&
	!invoke('get_download_status', { job_id: -1 }).success &&
	!invoke('get_download_status', { job_id: '1' }).success &&
	!invoke('get_download_status', { job_id: 2147483648 }).success,
	'current-job sentinel is accepted while malformed or out-of-range IDs are rejected');

printf(`1..${checks}\n`);
