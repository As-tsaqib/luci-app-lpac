// SPDX-License-Identifier: Apache-2.0

'use strict';

function next_fd() {
	global.TEST_FD_COUNTER++;
	return global.TEST_FD_COUNTER;
}

function make_pipe_handle(state, mode) {
	const descriptor = next_fd();
	const resource = {
		state,
		mode,
		descriptor,
		closed: false,
		sticky_error: false
	};

	global.TEST_FD_STATES[descriptor] = state;
	push(global.TEST_PIPE_HANDLES, resource);

	return {
		fileno: function() {
			if (global.TEST_PIPE_FILENO_THROW)
				die('fileno failed');

			return resource.closed ? null : resource.descriptor;
		},

		read: function(count) {
			if (global.TEST_PIPE_READ_THROW)
				die('read failed');

			if (resource.closed || mode != 'r' || resource.sticky_error)
				return null;

			if (length(state.buffer)) {
				const value = substr(state.buffer, 0, 1);
				state.buffer = substr(state.buffer, 1);
				return value;
			}

			if (state.eof)
				return '';

			resource.sticky_error = true;
			return null;
		},

		write: function(value) {
			if (global.TEST_PIPE_WRITE_THROW)
				die('write failed');

			if (resource.closed || mode != 'w' || type(value) != 'string')
				return null;

			push(state.writes, value);
			push(global.TEST_DECISION_WRITES, value);

			return global.TEST_PIPE_WRITE_PARTIAL ? 1 : length(value);
		},

		flush: function() {
			global.TEST_PIPE_FLUSH_COUNT++;

			if (global.TEST_PIPE_FLUSH_THROW)
				die('flush failed');

			return global.TEST_PIPE_FLUSH_RESULT;
		},

		close: function() {
			if (resource.closed)
				return false;

			resource.closed = true;
			state.close_count++;
			global.TEST_PIPE_CLOSE_COUNT++;
			return true;
		}
	};
}

export function access(path, mode) {
	push(global.TEST_ACCESS_CALLS, { path, mode });

	return global.TEST_LPAC_ACCESS && global.TEST_ACCESS_FAIL_PATH !== path;
};

export function glob(pattern) {
	const result = global.TEST_GLOB_RESULTS?.[pattern];

	return type(result) == 'array' ? result : [];
};

export function readlink(path) {
	push(global.TEST_READLINK_CALLS, path);

	if (global.TEST_READLINK_THROW || global.TEST_READLINK_THROW_PATH === path)
		die('readlink failed');

	const result = global.TEST_READLINK_RESULTS?.[path];

	return type(result) == 'string' ? result : null;
};

export function lstat(path) {
	global.TEST_LSTAT_PATH = path;

	if (!global.TEST_LOCK_EXISTS)
		return null;

	return {
		type: global.TEST_LOCK_TYPE,
		uid: global.TEST_LOCK_UID,
		nlink: global.TEST_LOCK_NLINK,
		mode: global.TEST_LOCK_MODE
	};
};

export function open(path, mode, permissions) {
	global.TEST_OPEN = { path, mode, permissions };

	if (path == '/dev/urandom') {
		global.TEST_RANDOM_OPEN_COUNT++;

		if (global.TEST_RANDOM_OPEN_FAIL)
			return null;

		return {
			read: function(count) {
				global.TEST_RANDOM_READ_COUNT++;

				if (global.TEST_RANDOM_READ_FAIL)
					return null;

				return sprintf('%024d', global.TEST_RANDOM_READ_COUNT);
			},

			close: function() {
				global.TEST_RANDOM_CLOSE_COUNT++;
				return true;
			}
		};
	}

	const proc_fd = match(path, /^\/proc\/self\/fd\/([0-9]+)$/);

	if (proc_fd !== null) {
		push(global.TEST_PROC_OPEN_CALLS, { path, mode });

		if (global.TEST_PIPE_CLONE_FAIL)
			return null;

		const state = global.TEST_FD_STATES[int(proc_fd[1])];

		return state ? make_pipe_handle(state, substr(mode, 0, 1)) : null;
	}

	if (global.TEST_LOCK_OPEN_FAIL)
		return null;

	global.TEST_LOCK_OPEN = { path, mode, permissions };

	if (!global.TEST_LOCK_EXISTS) {
		global.TEST_LOCK_EXISTS = true;
		global.TEST_LOCK_MODE = permissions;
	}

	return {
		lock: function(flags) {
			global.TEST_LOCK_FLAGS = flags;
			return !global.TEST_LOCK_BUSY;
		},

		close: function() {
			global.TEST_LOCK_CLOSED = true;
			global.TEST_LOCK_CLOSE_COUNT++;
			return true;
		}
	};
};

export function pipe() {
	global.TEST_PIPE_CALL_COUNT++;

	if (global.TEST_PIPE_THROW)
		die('pipe failed');

	if (global.TEST_PIPE_NULL)
		return null;

	const state = {
		id: global.TEST_PIPE_CALL_COUNT,
		buffer: '',
		eof: false,
		writes: [],
		close_count: 0
	};

	push(global.TEST_PIPES, state);

	if (global.TEST_PIPE_CALL_COUNT % 2 == 0)
		global.TEST_OUTPUT_PIPE = state;

	return [ make_pipe_handle(state, 'r'), make_pipe_handle(state, 'w') ];
};

export function chmod(path, mode) {
	global.TEST_CHMOD = { path, mode };

	if (global.TEST_LOCK_CHMOD_FAIL)
		return null;

	global.TEST_LOCK_MODE = mode;
	return true;
};
