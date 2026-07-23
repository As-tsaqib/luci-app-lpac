// SPDX-License-Identifier: Apache-2.0

'use strict';

export const ULOOP_READ = 1;

export function handle(file, callback, events) {
	global.TEST_HANDLE_CALL_COUNT++;

	if (global.TEST_HANDLE_THROW)
		die('handle failed');

	if (global.TEST_HANDLE_NULL ||
	    global.TEST_HANDLE_NULL_AT == global.TEST_HANDLE_CALL_COUNT)
		return null;

	const state = {
		file,
		callback,
		events,
		deleted: false
	};

	global.TEST_LAST_HANDLE = state;
	push(global.TEST_HANDLES, state);

	return {
		delete: function() {
			global.TEST_HANDLE_DELETE_COUNT++;
			state.deleted = true;
			return true;
		}
	};
};

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
	global.TEST_TIMER_CALL_COUNT++;

	if (global.TEST_TIMER_THROW)
		die('timer failed');

	if (global.TEST_TIMER_NULL ||
	    global.TEST_TIMER_NULL_AT == global.TEST_TIMER_CALL_COUNT)
		return null;

	const state = {
		timeout,
		callback,
		cancelled: false
	};

	global.TEST_LAST_TIMER = state;
	push(global.TEST_TIMERS, state);

	return {
		set: function(new_timeout) {
			global.TEST_TIMER_SET_COUNT++;

			if (global.TEST_TIMER_SET_THROW)
				die('timer set failed');

			if (global.TEST_TIMER_SET_FAIL)
				return null;

			state.timeout = new_timeout;
			state.cancelled = false;
			push(state.set_calls || (state.set_calls = []), new_timeout);
			return true;
		},

		cancel: function() {
			global.TEST_TIMER_CANCEL_COUNT++;
			state.cancelled = true;
			return true;
		}
	};
};
