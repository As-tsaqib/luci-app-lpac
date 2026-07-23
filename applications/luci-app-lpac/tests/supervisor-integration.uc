// SPDX-License-Identifier: Apache-2.0

'use strict';

import * as fs from 'fs';
import * as uloop from 'uloop';

/*
 * Every mode below executes the packaged production supervisor with inert
 * children, covering real fs/uloop/libubox/setsid behavior without an lpac
 * binary, eUICC, activation credential, or network.
 */
const CHILD_EXIT_SUCCESS = 64;
const CHILD_EXIT_NOT_FOUND = 65;
const CHILD_EXIT_NOT_EXECUTABLE = 66;
const CHILD_EXIT_FAILED = 67;
const CHILD_EXIT_SIGNALED = 68;
const CHILD_EXIT_PIPE_FAILED = 69;
const CHILD_EXIT_TIMEOUT = 70;
const DEFAULT_KILL_PATH = '/bin/kill';
const PROCESS_ENV = { PATH: '/usr/sbin:/usr/bin:/sbin:/bin' };
let supervisor_path;

const FAKE_INTERACTIVE_SCRIPT =
	'printf "%s\\n" \'{"type":"progress","payload":{"code":0,"message":"es8p_meatadata_parse","data":{"iccid":"8944000000000000001","serviceProviderName":"Test Provider","profileName":"Test Profile","profileClass":"operational"}}}\'\n' +
	'printf %s \'{"type":"progress","payload":{"code":0,"message":"pre\'\n' +
	'sleep 0.05\n' +
	'printf "%s\\n" \'view","data":"y/n"}}\'\n' +
	'IFS= read -r answer || answer=eof\n' +
	'printf \'{"type":"decision","answer":"%s"}\\n\' "$answer"\n' +
	'if [ "$answer" = y ]; then\n' +
	'  printf "%s\\n" \'{"type":"progress","payload":{"code":0,"message":"es10b_prepare_download","data":null}}\'\n' +
	'  printf "%s\\n" \'{"type":"lpa","payload":{"code":0,"message":"success","data":null}}\'\n' +
	'else\n' +
	'  printf "%s\\n" \'{"type":"lpa","payload":{"code":-1,"message":"cancelled","data":null}}\'\n' +
	'fi';

const FAKE_DISCOVERY_SCRIPT =
	'sleep 31\n' +
	'printf "%s\\n" \'{"type":"progress","payload":{"code":0,"message":"es10b_get_euicc_challenge_and_info","data":null}}\'\n' +
	'printf "%s\\n" \'{"type":"progress","payload":{"code":0,"message":"es9p_initiate_authentication","data":null}}\'\n' +
	'printf "%s\\n" \'{"type":"progress","payload":{"code":0,"message":"es10b_authenticate_server","data":null}}\'\n' +
	'printf "%s\\n" \'{"type":"progress","payload":{"code":0,"message":"es11_authenticate_client","data":null}}\'\n' +
	'printf "%s\\n" \'{"type":"lpa","payload":{"code":0,"message":"success","data":[]}}\'';

let failures = 0;

function check(condition, message) {
	if (condition)
		printf(`ok - ${message}\n`);
	else {
		warn(`not ok - ${message}\n`);
		failures++;
	}
}

function finish(exit_message) {
	if (failures > 0)
		die(`${exit_message}: ${failures} failure(s)\n`);

	printf(`${exit_message}: all checks passed\n`);
}

function close_file(file) {
	if (!file)
		return;

	try { file.close(); }
	catch (e) { /* Best-effort cleanup in an integration-test failure path. */ }
}

function close_pipe_set(pipes) {
	if (type(pipes) != 'array')
		return;

	for (let file in pipes)
		close_file(file);
}

function prepare_download_pipes() {
	let input = null;
	let output = null;
	let liveness = null;
	let input_writer = null;
	let output_reader = null;
	let liveness_writer = null;

	try {
		input = fs.pipe();
		output = fs.pipe();
		liveness = fs.pipe();

		if (type(input) != 'array' || length(input) != 2 ||
		    type(output) != 'array' || length(output) != 2 ||
		    type(liveness) != 'array' || length(liveness) != 2)
			die('pipe failed');

		input_writer = fs.open(`/proc/self/fd/${input[1].fileno()}`, 'we');
		output_reader = fs.open(`/proc/self/fd/${output[0].fileno()}`, 're');
		liveness_writer = fs.open(`/proc/self/fd/${liveness[1].fileno()}`, 'we');

		if (!input_writer || !output_reader || !liveness_writer)
			die('pipe clone failed');

		close_file(input[1]);
		input[1] = null;
		close_file(output[0]);
		output[0] = null;
		close_file(liveness[1]);
		liveness[1] = null;

		return {
			child_input: input[0],
			child_output: output[1],
			child_liveness: liveness[0],
			input_writer,
			output_reader,
			liveness_writer
		};
	}
	catch (e) {
		close_file(input_writer);
		close_file(output_reader);
		close_file(liveness_writer);
		close_pipe_set(input);
		close_pipe_set(output);
		close_pipe_set(liveness);
		return null;
	}
}

function prepare_async_pipes() {
	let output = null;
	let liveness = null;
	let output_reader = null;
	let liveness_writer = null;

	try {
		output = fs.pipe();
		liveness = fs.pipe();

		if (type(output) != 'array' || length(output) != 2 ||
		    type(liveness) != 'array' || length(liveness) != 2)
			die('pipe failed');

		output_reader = fs.open(`/proc/self/fd/${output[0].fileno()}`, 're');
		liveness_writer = fs.open(`/proc/self/fd/${liveness[1].fileno()}`, 'we');

		if (!output_reader || !liveness_writer)
			die('pipe clone failed');

		close_file(output[0]);
		output[0] = null;
		close_file(liveness[1]);
		liveness[1] = null;

		return {
			child_output: output[1],
			child_liveness: liveness[0],
			output_reader,
			liveness_writer
		};
	}
	catch (e) {
		close_file(output_reader);
		close_file(liveness_writer);
		close_pipe_set(output);
		close_pipe_set(liveness);
		return null;
	}
}

function close_download_pipes(pipes) {
	if (!pipes)
		return;

	close_file(pipes.child_input);
	close_file(pipes.child_output);
	close_file(pipes.child_liveness);
	close_file(pipes.input_writer);
	close_file(pipes.output_reader);
	close_file(pipes.liveness_writer);
}

function close_async_pipes(pipes) {
	if (!pipes)
		return;

	close_file(pipes.child_output);
	close_file(pipes.child_liveness);
	close_file(pipes.output_reader);
	close_file(pipes.liveness_writer);
}

function watch_output(reader, on_data, on_eof) {
	const state = {
		file: reader,
		handle: null,
		data: '',
		eof: false,
		callbacks: 0
	};
	let output_ready;

	function register_watch() {
		state.handle = uloop.handle(state.file, output_ready, uloop.ULOOP_READ);

		if (!state.handle)
			die(`unable to watch supervisor output: ${uloop.error()}\n`);
	}

	function reopen_watch() {
		const old_file = state.file;
		const old_fd = old_file.fileno();
		const replacement = fs.open(`/proc/self/fd/${old_fd}`, 're');

		if (!replacement)
			die(`unable to rearm supervisor output: ${fs.error()}\n`);

		state.handle.delete();
		old_file.close();
		state.file = replacement;
		register_watch();
	}

	output_ready = function() {
		state.callbacks++;

		for (let i = 0; i < 8192; i++) {
			const byte = state.file.read(1);

			if (byte === null) {
				reopen_watch();
				return;
			}

			if (type(byte) != 'string' || !length(byte)) {
				state.handle.delete();
				state.handle = null;
				state.file.close();
				state.file = null;
				state.eof = true;
				on_eof?.(state);
				return;
			}

			state.data += byte;
			on_data?.(byte, state);
		}
	};

	register_watch();
	return state;
}

function close_output_watch(state) {
	if (!state)
		return;

	try { state.handle?.delete(); }
	catch (e) { /* The EOF callback may already have detached it. */ }

	close_file(state.file);
	state.handle = null;
	state.file = null;
}

function read_small_file(path) {
	const file = fs.open(path, 'r');

	if (!file)
		return null;

	let data = '';

	for (let i = 0; i < 16; i++) {
		const chunk = file.read(4096);

		if (chunk === null || type(chunk) != 'string' || !length(chunk))
			break;

		data += chunk;

		if (length(chunk) < 4096)
			break;
	}

	file.close();
	return data;
}

function valid_pid(pid) {
	return type(pid) == 'int' && pid > 1;
}

function read_pid_pair(path) {
	const data = read_small_file(path);
	const parsed = type(data) == 'string'
		? match(data, /^([0-9]+) ([0-9]+)[\r\n]*$/) : null;

	if (!parsed)
		return null;

	const leader = int(parsed[1]);
	const descendant = int(parsed[2]);

	return valid_pid(leader) && valid_pid(descendant) && leader != descendant
		? { leader, descendant } : null;
}

function proc_stat(pid) {
	if (!valid_pid(pid))
		return null;

	const data = read_small_file(`/proc/${pid}/stat`);
	const parsed = type(data) == 'string'
		? match(data, /^([0-9]+) \((.*)\) ([A-Za-z]) ([0-9]+) ([0-9]+) /)
		: null;

	if (!parsed)
		return null;

	return {
		pid: int(parsed[1]),
		state: parsed[3],
		ppid: int(parsed[4]),
		pgrp: int(parsed[5])
	};
}

function proc_children(pid) {
	const data = read_small_file(`/proc/${pid}/task/${pid}/children`);
	const result = [];

	if (type(data) == 'string' && length(trim(data))) {
		for (let token in split(trim(data), ' ')) {
			token = trim(token);

			if (match(token, /^[0-9]+$/) !== null) {
				const child = int(token);

				if (valid_pid(child))
					push(result, child);
			}
		}

		return result;
	}

	/* Some OpenWrt kernels omit the task children file; scan bounded procfs. */
	let paths = null;

	try { paths = fs.glob('/proc/[0-9]*/stat'); }
	catch (e) { paths = null; }

	if (type(paths) != 'array' || length(paths) > 4096)
		return result;

	for (let path in paths) {
		const matched = match(path, /^\/proc\/([0-9]+)\/stat$/);

		if (!matched)
			continue;

		const child = int(matched[1]);
		const stat = proc_stat(child);

		if (stat?.ppid == pid)
			push(result, child);
	}

	return result;
}

function live_process(pid) {
	const stat = proc_stat(pid);

	return stat !== null && stat.state != 'Z' && stat.state != 'X';
}

function find_guardian(outer_pid, child_pid) {
	let guardian = null;

	for (let pid in proc_children(outer_pid)) {
		if (pid == child_pid)
			continue;

		if (guardian !== null)
			return null;

		guardian = pid;
	}

	return guardian;
}

function run_protocol(setsid_path, shell_path, kill_path) {
	const cases = [
		{
			name: 'a successful download child is translated to reserved status 64',
			kind: 'download',
			arguments: [ shell_path, '-c', 'exit 0' ],
			expected: CHILD_EXIT_SUCCESS
		},
		{
			name: 'a missing download child is translated to reserved status 65',
			kind: 'download',
			arguments: [ '/luci-lpac-test/does-not-exist' ],
			expected: CHILD_EXIT_NOT_FOUND
		},
		{
			name: 'a non-executable download child is translated to reserved status 66',
			kind: 'download',
			arguments: [ '/etc/passwd' ],
			expected: CHILD_EXIT_NOT_EXECUTABLE
		},
		{
			name: 'an ordinary download child failure is translated to reserved status 67',
			kind: 'download',
			arguments: [ shell_path, '-c', 'exit 23' ],
			expected: CHILD_EXIT_FAILED
		},
		{
			name: 'a signalled download child is translated to reserved status 68',
			kind: 'download',
			arguments: [ shell_path, '-c', 'kill -TERM "$$"' ],
			expected: CHILD_EXIT_SIGNALED
		},
		{
			name: 'a successful async child uses the same reserved status 64',
			kind: 'async',
			arguments: [ shell_path, '-c', 'printf async' ],
			expected: CHILD_EXIT_SUCCESS
		},
		{
			name: 'malformed download descriptors use reserved status 69',
			kind: 'download',
			arguments: [],
			expected: CHILD_EXIT_PIPE_FAILED,
			malformed: true
		},
		{
			name: 'malformed async descriptors use reserved status 69',
			kind: 'async',
			arguments: [],
			expected: CHILD_EXIT_PIPE_FAILED,
			malformed: true
		},
		{
			name: 'download redirect failure closes inherited descriptors and returns 69',
			kind: 'download',
			arguments: [ shell_path, '-c', 'exit 0' ],
			expected: CHILD_EXIT_PIPE_FAILED,
			redirect_failure: true
		},
		{
			name: 'async redirect failure closes inherited descriptors and returns 69',
			kind: 'async',
			arguments: [ shell_path, '-c', 'exit 0' ],
			expected: CHILD_EXIT_PIPE_FAILED,
			redirect_failure: true
		}
	];
	const processes = [];
	const entries = [];
	let pending = length(cases);

	function complete(entry) {
		if (entry.done || !entry.process_exited ||
		    (entry.output_watch && !entry.output_watch.eof))
			return;

		entry.done = true;
		if (entry.pipes) {
			close_file(entry.pipes.liveness_writer);
			entry.pipes.liveness_writer = null;
		}
		close_output_watch(entry.output_watch);
		pending--;

		if (pending == 0)
			uloop.end();
	}

	function launch(testcase) {
		let pipes = null;
		let arguments;
		const entry = {
			done: false,
			process_exited: false,
			output_watch: null,
			pipes: null,
			process: null
		};

		if (testcase.malformed) {
			arguments = testcase.kind == 'download'
				? [ supervisor_path, 'download', '', 'not-a-descriptor', '3' ]
				: [ supervisor_path, 'async', '', 'not-a-descriptor' ];
		}
		else if (testcase.kind == 'download') {
			pipes = prepare_download_pipes();

			if (!pipes) {
				check(false, `three real pipes were created for: ${testcase.name}`);
				pending--;
				return;
			}

			const input_fd = pipes.child_input.fileno();
			const output_fd = testcase.redirect_failure
				? 1048575 : pipes.child_output.fileno();
			const liveness_fd = pipes.child_liveness.fileno();

			arguments = [
				supervisor_path, 'download', `${input_fd}`, `${output_fd}`,
				`${liveness_fd}`
			];
		}
		else {
			pipes = prepare_async_pipes();

			if (!pipes) {
				check(false, `two real pipes were created for: ${testcase.name}`);
				pending--;
				return;
			}

			const output_fd = testcase.redirect_failure
				? 1048575 : pipes.child_output.fileno();
			const liveness_fd = pipes.child_liveness.fileno();

			arguments = [
				supervisor_path, 'async', `${output_fd}`, `${liveness_fd}`
			];
		}

		for (let argument in testcase.arguments)
			push(arguments, argument);

		entry.pipes = pipes;
		push(entries, entry);

		if (pipes) {
			entry.output_watch = watch_output(pipes.output_reader, null,
				function() { complete(entry); });
			pipes.output_reader = null;
		}

		entry.process = uloop.process(setsid_path, arguments, PROCESS_ENV,
			function(exit_code) {
				entry.process_exited = true;
				check(exit_code == testcase.expected, testcase.name);
				complete(entry);
			});

		if (entry.process)
			push(processes, entry.process);
		else {
			check(false, `uloop.process() started the case: ${testcase.name}`);
			entry.process_exited = true;
			close_output_watch(entry.output_watch);
			entry.output_watch = null;
			complete(entry);
		}

		if (pipes) {
			close_file(pipes.child_input);
			pipes.child_input = null;
			close_file(pipes.child_output);
			pipes.child_output = null;
			close_file(pipes.child_liveness);
			pipes.child_liveness = null;
			close_file(pipes.input_writer);
			pipes.input_writer = null;
		}
	}

	for (let testcase in cases)
		launch(testcase);

	const watchdog = uloop.timer(5000, function() {
		check(false, 'all wrapper callbacks and output EOFs arrived within five seconds');
		uloop.end();
	});

	const run_result = uloop.run();

	watchdog.cancel();

	for (let entry in entries) {
		close_output_watch(entry.output_watch);
		close_download_pipes(entry.pipes);
	}

	check(run_result == 0, 'the protocol uloop event loop completed normally');
	check(pending == 0 && length(processes) == length(cases),
		'uloop.process() completed every download and async protocol case');
	finish('uloop supervisor protocols');
}

function run_interactive_pipe(setsid_path, shell_path, kill_path, accept) {
	/* Force every communication descriptor beyond dash's one-digit range. */
	const filler = [];

	for (let i = 0; i < 16; i++) {
		const file = fs.open('/dev/null', 're');

		if (file)
			push(filler, file);
	}

	const pipes = prepare_download_pipes();

	if (!pipes)
		die(`unable to create interactive test pipes: ${fs.error()}\n`);

	const child_input_fd = pipes.child_input.fileno();
	const child_output_fd = pipes.child_output.fileno();
	const child_liveness_fd = pipes.child_liveness.fileno();

	check(child_input_fd > 9 && child_output_fd > 9 && child_liveness_fd > 9,
		'interactive input, output, and liveness descriptors are greater than nine');

	let process_exited = false;
	let output_eof = false;
	let exit_code = null;
	let decision_writes = 0;
	let decision_write_ok = null;
	let output_watch = null;

	function maybe_complete() {
		if (process_exited && output_eof)
			uloop.end();
	}

	const process_handle = uloop.process(setsid_path, [
		supervisor_path, 'download', `${child_input_fd}`, `${child_output_fd}`,
		`${child_liveness_fd}`,
		shell_path, '-c', FAKE_INTERACTIVE_SCRIPT, 'fake-lpac'
	], PROCESS_ENV, function(code) {
		process_exited = true;
		exit_code = code;
		maybe_complete();
	});

	check(process_handle !== null,
		'interactive wrapper started in an outer setsid process group');

	close_file(pipes.child_input);
	pipes.child_input = null;
	close_file(pipes.child_output);
	pipes.child_output = null;
	close_file(pipes.child_liveness);
	pipes.child_liveness = null;

	for (let file in filler)
		file.close();

	if (!process_handle)
		die(`unable to start interactive test wrapper: ${uloop.error()}\n`);

	output_watch = watch_output(pipes.output_reader, function(byte, state) {
		if (pipes.input_writer !== null &&
		    index(state.data, '"message":"preview"') >= 0) {
			if (accept) {
				decision_writes++;
				decision_write_ok = pipes.input_writer.write('y\n') == 2;

				/* OpenWrt 24 may return null for a successful flush. */
				try { pipes.input_writer.flush(); }
				catch (e) { /* close below remains the final best effort. */ }
			}

			close_file(pipes.input_writer);
			pipes.input_writer = null;
		}
	}, function() {
		output_eof = true;
		maybe_complete();
	});
	pipes.output_reader = null;

	const watchdog = uloop.timer(5000, function() {
		check(false, 'interactive pipe reached process callback and real EOF');
		uloop.end();
	});

	const run_result = uloop.run();

	watchdog.cancel();
	close_output_watch(output_watch);
	close_download_pipes(pipes);

	check(run_result == 0, 'interactive uloop event loop completed normally');
	check(process_exited && output_eof,
		'interactive completion waited for both process exit and output EOF');
	check(exit_code == CHILD_EXIT_SUCCESS,
		'interactive inert child success uses reserved wrapper status 64');
	check(output_watch.callbacks >= 2,
		'fragmented NDJSON required multiple nonblocking output callbacks');
	check(index(output_watch.data, '"message":"preview"') >= 0,
		'fragmented preview JSON was reconstructed without lost bytes');
	check(index(output_watch.data, '"serviceProviderName":"Test Provider"') >= 0,
		'preview metadata traversed the real output pipe intact');

	if (accept) {
		check(decision_writes == 1 && decision_write_ok === true,
			'exactly one acceptance line was written to the child');
		check(index(output_watch.data, '"answer":"y"') >= 0,
			'the inert child received the acceptance decision');
		check(index(output_watch.data, '"message":"es10b_prepare_download"') >= 0 &&
		      index(output_watch.data, '"message":"success"') >= 0,
			'acceptance allowed the inert post-gate and terminal records');
	}
	else {
		check(decision_writes == 0,
			'EOF cancellation did not write an installation decision');
		check(index(output_watch.data, '"answer":"eof"') >= 0,
			'the child observed EOF after the last parent writer closed');
		check(index(output_watch.data, '"message":"cancelled"') >= 0 &&
		      index(output_watch.data, 'es10b_prepare_download') < 0,
			'EOF cancellation never crossed the inert installation gate');
	}

	finish(accept ? 'interactive preview acceptance' : 'interactive preview EOF');
}

function run_liveness_guardian(setsid_path, shell_path, kill_path, pid_file) {
	const pipes = prepare_async_pipes();

	if (!pipes)
		die(`unable to create liveness test pipes: ${fs.error()}\n`);

	const child_script =
		'pid_file=$1\n' +
		'shell=$2\n' +
		'"$shell" -c \'trap "" HUP TERM; while :; do sleep 30; done\' &\n' +
		'descendant=$!\n' +
		'printf "%s %s\\n" "$$" "$descendant" > "$pid_file"\n' +
		'printf "ready\\n"\n' +
		'wait "$descendant"';
	const child_output_fd = pipes.child_output.fileno();
	const child_liveness_fd = pipes.child_liveness.fileno();
	let process_exited = false;
	let output_eof = false;
	let exit_code = null;
	let inspected = false;
	let liveness_closed = false;
	let pair = null;
	let guardian_pid = null;
	let death_polls = 0;
	let output_watch = null;
	let death_timer = null;
	let maybe_complete;
	let guardian_polls = 0;

	const process_handle = uloop.process(setsid_path, [
		supervisor_path, 'async', `${child_output_fd}`, `${child_liveness_fd}`,
		shell_path, '-c', child_script, 'fake-lpac', pid_file, shell_path
	], PROCESS_ENV, function(code) {
		process_exited = true;
		exit_code = code;
		maybe_complete();
	});

	check(process_handle !== null,
		'uloop.process() started the outer liveness supervisor');

	if (!process_handle)
		finish('liveness guardian');

	const outer_pid = process_handle.pid();

	close_file(pipes.child_output);
	pipes.child_output = null;
	close_file(pipes.child_liveness);
	pipes.child_liveness = null;

	maybe_complete = function() {
		if (!process_exited || !output_eof || !inspected || death_timer)
			return;

		death_timer = uloop.timer(10, function() {
			if (!live_process(pair.leader) && !live_process(pair.descendant) &&
			    !live_process(guardian_pid)) {
				uloop.end();
			}
			else if (++death_polls < 200)
				death_timer.set(10);
			else {
				check(false, 'guardian killed the nested process group promptly');
				uloop.end();
			}
		});
	};

	output_watch = watch_output(pipes.output_reader, null, function() {
		output_eof = true;
		maybe_complete();
	});
	pipes.output_reader = null;

	let inspect_polls = 0;
	let inspect_timer = null;
	inspect_timer = uloop.timer(10, function() {
		pair = read_pid_pair(pid_file);

		if (!pair && ++inspect_polls < 200) {
			inspect_timer.set(10);
			return;
		}

		if (!pair) {
			check(false, 'the nested child published valid leader and descendant PIDs');
			inspected = true;
			close_file(pipes.liveness_writer);
			pipes.liveness_writer = null;
			liveness_closed = true;
			maybe_complete();
			return;
		}

		const outer = proc_stat(outer_pid);
		const child = proc_stat(pair.leader);
		const descendant = proc_stat(pair.descendant);

		guardian_pid = find_guardian(outer_pid, pair.leader);
		const guardian = proc_stat(guardian_pid);
		const guardian_ready = valid_pid(guardian_pid) &&
			guardian_pid != pair.leader && guardian?.ppid == outer_pid &&
			guardian.pgrp == outer_pid;

		if (!guardian_ready && ++guardian_polls < 200) {
			guardian_pid = null;
			inspect_timer.set(10);
			return;
		}

		check(valid_pid(outer_pid) && outer?.pgrp == outer_pid,
			'outer setsid PID is a valid process-group leader');
		check(child?.pid == pair.leader && child.ppid == outer_pid &&
		      child.pgrp == pair.leader,
			'nested setsid child PID is valid, parented by the wrapper, and owns its group');
		check(descendant?.pid == pair.descendant && descendant.ppid == pair.leader &&
		      descendant.pgrp == pair.leader,
			'descendant belongs to the nested child process group');
		check(valid_pid(guardian_pid) && guardian_pid != pair.leader &&
		      guardian?.ppid == outer_pid && guardian.pgrp == outer_pid,
			'guardian PID is valid, distinct from the child, and remains in the outer group');

		inspected = true;
		close_file(pipes.liveness_writer);
		pipes.liveness_writer = null;
		liveness_closed = true;
		maybe_complete();
	});

	const watchdog = uloop.timer(5000, function() {
		check(false, 'closing the liveness writer terminated the nested group promptly');
		uloop.end();
	});

	const run_result = uloop.run();

	inspect_timer.cancel();
	death_timer?.cancel();
	watchdog.cancel();
	close_output_watch(output_watch);
	close_async_pipes(pipes);

	check(run_result == 0, 'liveness uloop event loop completed normally');
	check(inspected && liveness_closed,
		'parent/rpcd death was simulated by closing only the liveness writer');
	check(process_exited && output_eof,
		'liveness termination reached both wrapper callback and output EOF');
	check(exit_code == CHILD_EXIT_SIGNALED,
		'guardian SIGKILL is translated to reserved signalled status 68');
	check(pair !== null && !live_process(pair.leader) &&
	      !live_process(pair.descendant) && !live_process(guardian_pid),
		'no live child, descendant, or guardian remains after parent death');
	finish('liveness guardian');
}

function run_lock_descendant(setsid_path, shell_path, kill_path, lock_file, pid_file) {
	const pipes = prepare_async_pipes();

	if (!pipes)
		die(`unable to create descendant-cleanup pipes: ${fs.error()}\n`);

	const descendant_script =
		'pid_file=$1\n' +
		'shell=$2\n' +
		'"$shell" -c \'trap "" HUP TERM; while :; do sleep 30; done\' &\n' +
		'descendant=$!\n' +
		'printf "%s %s\\n" "$$" "$descendant" > "$pid_file"\n' +
		'printf "leader-exiting\\n"\n' +
		'exit 0';
	const lock_handle = fs.open(lock_file, 'a', 0o600);

	check(lock_handle !== null, 'fs.open() created the synthetic operation lock');
	check(lock_handle?.lock('xn') === true,
		'fs.file.lock() acquired an exclusive nonblocking flock');

	if (!lock_handle)
		finish('descendant cleanup and inherited lock');

	const child_output_fd = pipes.child_output.fileno();
	const child_liveness_fd = pipes.child_liveness.fileno();
	let process_exited = false;
	let output_eof = false;
	let exit_code = null;
	let output_watch = null;

	function maybe_complete() {
		if (process_exited && output_eof)
			uloop.end();
	}

	const process_handle = uloop.process(setsid_path, [
		supervisor_path, 'async', `${child_output_fd}`, `${child_liveness_fd}`,
		shell_path, '-c', descendant_script, 'fake-lpac', pid_file, shell_path
	], PROCESS_ENV, function(code) {
		process_exited = true;
		exit_code = code;
		maybe_complete();
	});

	check(process_handle !== null,
		'uloop.process() started a supervisor whose child forks a descendant');
	check(lock_handle.close() === true,
		'the ucode parent released its own lock after process creation');

	close_file(pipes.child_output);
	pipes.child_output = null;
	close_file(pipes.child_liveness);
	pipes.child_liveness = null;

	if (!process_handle)
		finish('descendant cleanup and inherited lock');

	output_watch = watch_output(pipes.output_reader, null, function() {
		output_eof = true;
		maybe_complete();
	});
	pipes.output_reader = null;

	const watchdog = uloop.timer(5000, function() {
		check(false, 'leader exit triggered descendant cleanup, callback, and EOF promptly');
		uloop.end();
	});

	const run_result = uloop.run();

	watchdog.cancel();
	close_output_watch(output_watch);
	close_async_pipes(pipes);

	const pair = read_pid_pair(pid_file);
	const contender = fs.open(lock_file, 'a', 0o600);
	const lock_released = contender?.lock('xn') === true;

	check(run_result == 0, 'descendant-cleanup uloop event loop completed normally');
	check(process_exited && output_eof,
		'wrapper completion waited for callback and EOF after descendant cleanup');
	check(exit_code == CHILD_EXIT_SUCCESS,
		'leader exit zero is translated to reserved success status 64');
	check(pair !== null && !live_process(pair.leader) && !live_process(pair.descendant),
		'leader and its inherited-output descendant are no longer live');
	check(index(output_watch.data, 'leader-exiting') >= 0,
		'child output traversed the async output descriptor before cleanup');
	check(lock_released,
		'inherited flock was released when the prompt wrapper cleanup completed');

	close_file(contender);
	finish('descendant cleanup and inherited lock');
}

function run_oneshot_timeout(setsid_path, shell_path, kill_path, pid_file) {
	const child_script =
		'pid_file=$1\n' +
		'shell=$2\n' +
		'"$shell" -c \'trap "" HUP TERM; while :; do sleep 30; done\' &\n' +
		'descendant=$!\n' +
		'printf "%s %s\\n" "$$" "$descendant" > "$pid_file"\n' +
		'wait "$descendant"';
	let process_exited = false;
	let exit_code = null;
	let pair = null;
	let inspected = false;
	let guardian_pid = null;
	let death_timer = null;
	let death_polls = 0;
	let maybe_complete;
	let guardian_polls = 0;

	const process_handle = uloop.process(setsid_path, [
		supervisor_path, 'oneshot', '1', shell_path, '-c', child_script,
		'fake-lpac', pid_file, shell_path
	], PROCESS_ENV, function(code) {
		process_exited = true;
		exit_code = code;
		maybe_complete();
	});

	check(process_handle !== null,
		'uloop.process() started the one-shot watchdog wrapper');

	if (!process_handle)
		finish('one-shot timeout');

	const outer_pid = process_handle.pid();

	maybe_complete = function() {
		if (!process_exited || !inspected || death_timer)
			return;

		death_timer = uloop.timer(10, function() {
			if (!live_process(pair.leader) && !live_process(pair.descendant) &&
			    !live_process(guardian_pid))
				uloop.end();
			else if (++death_polls < 200)
				death_timer.set(10);
			else {
				check(false, 'one-shot timeout removed its child group and timer guardian');
				uloop.end();
			}
		});
	};

	let inspect_polls = 0;
	let inspect_timer = null;
	inspect_timer = uloop.timer(10, function() {
		pair = read_pid_pair(pid_file);

		if (!pair && ++inspect_polls < 80) {
			inspect_timer.set(10);
			return;
		}

		if (!pair) {
			check(false, 'one-shot child published valid PIDs before its deadline');
			inspected = true;
			maybe_complete();
			return;
		}

		guardian_pid = find_guardian(outer_pid, pair.leader);
		const child = proc_stat(pair.leader);
		const guardian = proc_stat(guardian_pid);
		const guardian_ready = valid_pid(guardian_pid) &&
			guardian_pid != pair.leader && guardian?.ppid == outer_pid &&
			guardian.pgrp == outer_pid;

		if (!guardian_ready && ++guardian_polls < 80) {
			guardian_pid = null;
			inspect_timer.set(10);
			return;
		}

		check(child?.ppid == outer_pid && child.pgrp == pair.leader,
			'one-shot nested child owns a distinct process group');
		check(valid_pid(guardian_pid) && guardian_pid != pair.leader &&
		      guardian?.ppid == outer_pid && guardian.pgrp == outer_pid,
			'one-shot timer guardian has a valid PID distinct from its child');
		inspected = true;
		maybe_complete();
	});

	const watchdog = uloop.timer(5000, function() {
		check(false, 'one-shot child deadline returned within five seconds');
		uloop.end();
	});

	const run_result = uloop.run();

	inspect_timer.cancel();
	death_timer?.cancel();
	watchdog.cancel();

	check(run_result == 0, 'one-shot uloop event loop completed normally');
	check(inspected && process_exited,
		'one-shot timeout completed after its PID contract was observed');
	check(exit_code == CHILD_EXIT_TIMEOUT,
		'one-shot deadline uses the dedicated reserved timeout status 70');
	check(pair !== null && !live_process(pair.leader) &&
	      !live_process(pair.descendant) && !live_process(guardian_pid),
		'one-shot timeout leaves no live nested child, descendant, or guardian');
	finish('one-shot timeout');
}

function run_long_discovery(setsid_path, shell_path, kill_path) {
	const pipes = prepare_async_pipes();

	if (!pipes)
		die(`unable to create long discovery pipes: ${fs.error()}\n`);

	const child_output_fd = pipes.child_output.fileno();
	const child_liveness_fd = pipes.child_liveness.fileno();
	let process_exited = false;
	let output_eof = false;
	let exit_code = null;
	let survived_thirty_seconds = false;
	let output_watch = null;

	function maybe_complete() {
		if (process_exited && output_eof)
			uloop.end();
	}

	const process_handle = uloop.process(setsid_path, [
		supervisor_path, 'async', `${child_output_fd}`, `${child_liveness_fd}`,
		shell_path, '-c', FAKE_DISCOVERY_SCRIPT, 'fake-lpac'
	], PROCESS_ENV, function(code) {
		process_exited = true;
		exit_code = code;
		maybe_complete();
	});

	check(process_handle !== null,
		'uloop.process() started an inert asynchronous discovery');

	close_file(pipes.child_output);
	pipes.child_output = null;
	close_file(pipes.child_liveness);
	pipes.child_liveness = null;

	if (!process_handle)
		finish('long asynchronous discovery');

	output_watch = watch_output(pipes.output_reader, null, function() {
		output_eof = true;
		maybe_complete();
	});
	pipes.output_reader = null;

	const thirty_second_mark = uloop.timer(30000, function() {
		survived_thirty_seconds = !process_exited && !output_eof &&
			match(output_watch.data, /^@luci-lpac-pgid:[0-9]+\n$/) !== null;
		check(survived_thirty_seconds,
			'async discovery emits only its internal PID frame before the old 30-second RPC window');
	});
	const watchdog = uloop.timer(45000, function() {
		check(false, '31-second inert discovery completed within 45 seconds');
		uloop.end();
	});

	const run_result = uloop.run();

	thirty_second_mark.cancel();
	watchdog.cancel();
	close_output_watch(output_watch);
	close_async_pipes(pipes);

	check(run_result == 0, 'long-discovery uloop event loop completed normally');
	check(survived_thirty_seconds && process_exited && output_eof,
		'long discovery reached both wrapper callback and real output EOF after 30 seconds');
	check(exit_code == CHILD_EXIT_SUCCESS,
		'long asynchronous discovery uses reserved success status 64');
	check(index(output_watch.data, 'es10b_get_euicc_challenge_and_info') >= 0 &&
	      index(output_watch.data, 'es9p_initiate_authentication') >= 0 &&
	      index(output_watch.data, 'es10b_authenticate_server') >= 0 &&
	      index(output_watch.data, 'es11_authenticate_client') >= 0 &&
	      index(output_watch.data, '"type":"lpa"') >= 0,
		'inert discovery delivered the complete staged NDJSON protocol without network access');
	finish('long asynchronous discovery');
}

if (length(ARGV) < 4)
	die('usage: supervisor-integration.uc MODE SETSID SHELL SUPERVISOR [MODE_ARGS...]\n');

const mode = ARGV[0];
const setsid_path = ARGV[1];
const shell_path = ARGV[2];
supervisor_path = ARGV[3];

if (fs.access(supervisor_path, 'x') !== true)
	die(`production supervisor is not executable: ${supervisor_path}\n`);

if (!uloop.init())
	die(`unable to initialize uloop: ${uloop.error()}\n`);

if (mode == 'protocol' && (length(ARGV) == 4 || length(ARGV) == 5))
	run_protocol(setsid_path, shell_path, ARGV[4] || DEFAULT_KILL_PATH);
else if (mode == 'pipe-accept' && (length(ARGV) == 4 || length(ARGV) == 5))
	run_interactive_pipe(setsid_path, shell_path, ARGV[4] || DEFAULT_KILL_PATH, true);
else if (mode == 'pipe-eof' && (length(ARGV) == 4 || length(ARGV) == 5))
	run_interactive_pipe(setsid_path, shell_path, ARGV[4] || DEFAULT_KILL_PATH, false);
else if (mode == 'raw-group' && length(ARGV) == 6)
	run_liveness_guardian(setsid_path, shell_path, ARGV[4], ARGV[5]);
else if (mode == 'lock-descendant' && length(ARGV) == 6)
	run_lock_descendant(setsid_path, shell_path, DEFAULT_KILL_PATH, ARGV[4], ARGV[5]);
else if (mode == 'lock-descendant' && length(ARGV) == 7)
	run_lock_descendant(setsid_path, shell_path, ARGV[4], ARGV[5], ARGV[6]);
else if (mode == 'oneshot-timeout' && length(ARGV) == 6)
	run_oneshot_timeout(setsid_path, shell_path, ARGV[4], ARGV[5]);
else if (mode == 'async-long' && (length(ARGV) == 4 || length(ARGV) == 5))
	run_long_discovery(setsid_path, shell_path, ARGV[4] || DEFAULT_KILL_PATH);
else
	die(`invalid supervisor integration mode or arguments: ${mode}\n`);
