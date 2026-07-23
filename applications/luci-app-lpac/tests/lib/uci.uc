// SPDX-License-Identifier: Apache-2.0

function normalize_empty_options(values) {
	if (type(values) != 'object')
		return;

	for (let section, options in values) {
		if (type(options) != 'object')
			continue;

		for (let option, value in options) {
			if (option != '.type' && type(value) == 'string' && !length(value))
				delete options[option];
		}
	}
}

export function cursor() {
	global.TEST_UCI_CURSOR_COUNT++;
	const cursor_id = global.TEST_UCI_CURSOR_COUNT;
	let safety_storage = null;
	let luci_lpac_storage = null;

	try { safety_storage = json(sprintf('%J', global.TEST_SAFETY_UCI)); }
	catch (e) { safety_storage = null; }

	try { luci_lpac_storage = json(sprintf('%J', global.TEST_LUCI_LPAC_UCI)); }
	catch (e) { luci_lpac_storage = null; }

	function storage(config) {
		if (config == 'lpac')
			return global.TEST_UCI;

		if (config == 'lpac_safety')
			return safety_storage;

		if (config == 'luci_lpac')
			return luci_lpac_storage;

		return null;
	}

	function section_type(config, section, values) {
		if (type(values?.['.type']) == 'string')
			return values['.type'];

		if (config == 'lpac_safety' && section == 'state')
			return 'safety';

		if (config == 'luci_lpac' && section == 'profiles')
			return 'preferences';

		return section;
	}

	function section_record(config, section, values, index) {
		const record = {
			'.anonymous': false,
			'.index': index,
			'.name': section,
			'.type': section_type(config, section, values)
		};

		for (let key, value in values) {
			if (key != '.type')
				record[key] = value;
		}

		return record;
	}

	return {
		load: function(config) {
			let loaded = false;

			push(global.TEST_UCI_LOAD_CALLS, { cursor_id, config });

			if (config == 'lpac')
				loaded = !global.TEST_UCI_LOAD_FAIL;

			else if (config == 'lpac_safety') {
				global.TEST_SAFETY_UCI_LOAD_COUNT++;
				loaded = global.TEST_SAFETY_FILE_EXISTS &&
					!global.TEST_SAFETY_UCI_LOAD_FAIL &&
					global.TEST_SAFETY_UCI_LOAD_FAIL_AT !=
						global.TEST_SAFETY_UCI_LOAD_COUNT &&
					global.TEST_SAFETY_UCI_LOAD_COUNT >
						global.TEST_SAFETY_UCI_LOAD_FAIL_UNTIL;
			}

			else if (config == 'luci_lpac') {
				global.TEST_LUCI_LPAC_LOAD_COUNT++;

				loaded = global.TEST_LUCI_LPAC_FILE_EXISTS &&
					!global.TEST_LUCI_LPAC_LOAD_FAIL &&
					global.TEST_LUCI_LPAC_LOAD_FAIL_AT !=
						global.TEST_LUCI_LPAC_LOAD_COUNT;
			}

			if (loaded)
				normalize_empty_options(storage(config));

			return loaded;
		},

		get: function(config, section, option) {
			const values = storage(config)?.[section];
			return type(values) == 'object'
				? values[option]
				: null;
		},

		get_all: function(config, section) {
			const values = storage(config)?.[section];

			return type(values) == 'object'
				? section_record(config, section, values, 0)
				: null;
		},

		foreach: function(config, section_type_filter, callback) {
			const values = storage(config);
			let index = 0;
			let count = 0;

			if (type(values) != 'object' || type(callback) != 'function')
				return 0;

			for (let section, options in values) {
				if (type(options) != 'object')
					continue;

				const record = section_record(config, section, options, index++);

				if (section_type_filter !== null &&
				    section_type_filter != record['.type'])
					continue;

				count++;

				if (callback(record) === false)
					break;
			}

			return count;
		},

		set: function(...args) {
			if (length(args) < 3)
				return null;

			const values = storage(args[0]);
			push(global.TEST_UCI_SET_CALLS, {
				cursor_id,
				config: args[0],
				section: args[1],
				option: length(args) == 4 ? args[2] : null,
				value: args[length(args) - 1]
			});

			if (type(values) != 'object')
				return null;

			if (args[0] == 'luci_lpac' && global.TEST_LUCI_LPAC_SET_FAIL)
				return null;

			const section = args[1];

			if (type(values[section]) != 'object')
				values[section] = {};

			if (length(args) == 3)
				values[section]['.type'] = args[2];
			else if (length(args) == 4) {
				if (type(args[3]) == 'string' && !length(args[3]))
					delete values[section][args[2]];
				else
					values[section][args[2]] = args[3];
			}

			return true;
		},

		delete: function(...args) {
			const config = args[0];
			const section = args[1];
			const option = args[2];
			const values = storage(config);

			if (type(values) != 'object' || type(values[section]) != 'object')
				return false;

			if (length(args) >= 3 && option !== null) {
				delete values[section][option];
				return true;
			}

			delete values[section];
			return true;
		},

		commit: function(config) {
			push(global.TEST_UCI_COMMIT_CALLS, { cursor_id, config });

			if (config == 'lpac') {
				if (global.TEST_COMMIT_OK === false)
					return false;

				normalize_empty_options(global.TEST_UCI);
				return true;
			}

			if (config == 'lpac_safety') {
				if (global.TEST_SAFETY_COMMIT_OK === false)
					return false;

				normalize_empty_options(safety_storage);

				try {
					global.TEST_SAFETY_UCI =
						json(sprintf('%J', safety_storage));
				}
				catch (e) {
					return false;
				}

				return true;
			}

			if (config == 'luci_lpac') {
				if (global.TEST_LUCI_LPAC_COMMIT_OK === false)
					return false;

				normalize_empty_options(luci_lpac_storage);

				try {
					global.TEST_LUCI_LPAC_UCI = json(sprintf('%J', luci_lpac_storage));
				}
				catch (e) {
					return false;
				}

				return true;
			}

			return false;
		},

		unload: function(config) {
			push(global.TEST_UCI_UNLOAD_CALLS, { cursor_id, config });

			if (config == 'lpac_safety') {
				global.TEST_SAFETY_UCI_UNLOAD_COUNT++;

				if (global.TEST_SAFETY_UCI_UNLOAD_FAIL_AT ==
				    global.TEST_SAFETY_UCI_UNLOAD_COUNT)
					die('safety unload failed');
			}

			if (config == 'luci_lpac') {
				global.TEST_LUCI_LPAC_UNLOAD_COUNT++;

				if (global.TEST_LUCI_LPAC_UNLOAD_FAIL_AT ==
				    global.TEST_LUCI_LPAC_UNLOAD_COUNT)
					die('preference unload failed');
			}

			return true;
		}
	};
};
