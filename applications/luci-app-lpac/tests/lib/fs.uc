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

	if (path == '/etc/config/lpac_safety') {
		if (!global.TEST_SAFETY_FILE_EXISTS)
			return null;

		return {
			type: global.TEST_SAFETY_FILE_TYPE,
			uid: global.TEST_SAFETY_FILE_UID,
			nlink: global.TEST_SAFETY_FILE_NLINK,
			mode: global.TEST_SAFETY_FILE_MODE
		};
	}

	const temporary = global.TEST_TEMP_FILES?.[path];

	if (type(temporary) == 'object')
		return {
			type: temporary.type,
			uid: temporary.uid,
			nlink: temporary.nlink,
			mode: temporary.mode
		};

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

		if (state && substr(mode, 0, 1) == 'r')
			global.TEST_OUTPUT_PIPE = state;

		return state ? make_pipe_handle(state, substr(mode, 0, 1)) : null;
	}

	if (path == '/etc/config/lpac_safety' ||
	    match(path, /^\/etc\/config\/lpac_safety\.tmp\.[A-Za-z0-9_-]{32}$/) !== null) {
		if (global.TEST_SAFETY_OPEN_FAIL)
			return null;

		const is_temporary = path != '/etc/config/lpac_safety';

		if (is_temporary)
			global.TEST_TEMP_FILES[path] = {
				type: 'file', uid: 0, nlink: 1,
				mode: permissions || 0o600, content: ''
			};
		else {
			global.TEST_SAFETY_FILE_EXISTS = true;
			global.TEST_SAFETY_FILE_MODE = permissions || 0o600;
		}
		let closed = false;

		return {
			write: function(value) {
				if (closed || type(value) != 'string' || global.TEST_SAFETY_WRITE_FAIL)
					return null;

				if (is_temporary)
					global.TEST_TEMP_FILES[path].content = value;
				else
					global.TEST_SAFETY_FILE_CONTENT = value;
				return length(value);
			},

			flush: function() {
				if (global.TEST_SAFETY_FLUSH_THROW)
					die('safety flush failed');

				return true;
			},

			close: function() {
				if (closed)
					return false;

				closed = true;
				return global.TEST_SAFETY_CLOSE_FAIL ? false : true;
			}
		};
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

	if (path == '/etc/config/lpac_safety') {
		if (global.TEST_SAFETY_CHMOD_FAIL)
			return null;

		global.TEST_SAFETY_FILE_MODE = mode;
		return true;
	}

	if (type(global.TEST_TEMP_FILES?.[path]) == 'object') {
		global.TEST_TEMP_FILES[path].mode = mode;
		return true;
	}

	if (global.TEST_LOCK_CHMOD_FAIL)
		return null;

	global.TEST_LOCK_MODE = mode;
	return true;
};

export function rename(old_path, new_path) {
	const temporary = global.TEST_TEMP_FILES?.[old_path];

	if (type(temporary) != 'object' || new_path != '/etc/config/lpac_safety' ||
	    global.TEST_SAFETY_RENAME_FAIL)
		return null;

	const schema = match(temporary.content, /option schema '([^']*)'/);
	const incident = match(temporary.content,
		/option download_incident '([^']*)'/);
	const profiles = match(temporary.content,
		/option profiles_refreshed '([^']*)'/);
	const notifications_refreshed = match(temporary.content,
		/option notifications_refreshed '([^']*)'/);
	const notifications = match(temporary.content,
		/option notifications '([^']*)'/);

	if (index(temporary.content, "config safety 'state'") < 0 ||
	    schema === null || profiles === null ||
	    notifications_refreshed === null || notifications === null)
		return null;

	const state = {
		schema: schema[1],
		profiles_refreshed: profiles[1],
		notifications_refreshed: notifications_refreshed[1],
		notifications: notifications[1]
	};

	if (incident !== null)
		state.download_incident = incident[1];

	global.TEST_SAFETY_FILE_EXISTS = true;
	global.TEST_SAFETY_FILE_TYPE = temporary.type;
	global.TEST_SAFETY_FILE_UID = temporary.uid;
	global.TEST_SAFETY_FILE_NLINK = temporary.nlink;
	global.TEST_SAFETY_FILE_MODE = temporary.mode;
	global.TEST_SAFETY_FILE_CONTENT = temporary.content;
	global.TEST_SAFETY_UCI_LOAD_FAIL = false;
	global.TEST_SAFETY_UCI = { state };
	delete global.TEST_TEMP_FILES[old_path];
	return true;
};

export function unlink(path) {
	if (type(global.TEST_TEMP_FILES?.[path]) != 'object')
		return null;

	delete global.TEST_TEMP_FILES[path];
	return true;
};
