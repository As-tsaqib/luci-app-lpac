// SPDX-License-Identifier: Apache-2.0

'use strict';

export function process(executable, arguments, environment, output) {
	if (global.TEST_PROCESS_THROW)
		die('process failed');

	if (global.TEST_PROCESS_NULL)
		return null;

	const state = {
		executable,
		arguments,
		environment,
		output,
		pid: global.TEST_PROCESS_PID
	};

	global.TEST_LAST_PROCESS = state;
	push(global.TEST_PROCESSES, state);

	return {
		pid: function() {
			if (global.TEST_PROCESS_PID_THROW)
				die('pid failed');

			return state.pid;
		}
	};
};

export function timer(timeout, callback) {
	if (global.TEST_TIMER_THROW)
		die('timer failed');

	if (global.TEST_TIMER_NULL)
		return null;

	const state = {
		timeout,
		callback,
		cancelled: false
	};

	global.TEST_LAST_TIMER = state;
	push(global.TEST_TIMERS, state);

	return {
		cancel: function() {
			global.TEST_TIMER_CANCEL_COUNT++;
			state.cancelled = true;
			return true;
		}
	};
};
