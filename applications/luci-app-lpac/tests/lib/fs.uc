// SPDX-License-Identifier: Apache-2.0

export function open(path, mode, permissions) {
	global.TEST_OPEN = { path, mode, permissions };

	if (global.TEST_LOCK_OPEN_FAIL)
		return null;

	return {
		lock: function(flags) {
			global.TEST_LOCK_FLAGS = flags;
			return !global.TEST_LOCK_BUSY;
		},

		close: function() {
			global.TEST_LOCK_CLOSED = true;
			return true;
		}
	};
}
