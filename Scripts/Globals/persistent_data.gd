extends Node

const SETTING_VIBRATE = "setting.vibrate";
const CONTACTS_SORT = "contacts.sort";

var _data = {
	SETTING_VIBRATE: true,
	CONTACTS_SORT: 0
};

func write_persistent(key: String, value: Variant):
	_data[key] = value;

func try_get_persistent(key: String) -> Variant:
	if !_data.has(key):
		return null;

	return _data[key];
