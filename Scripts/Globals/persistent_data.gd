extends Node

const SETTING_VIBRATE = "setting.vibrate";
const SETTING_DEFAULT_CURRENCY = "setting.default_currency";
const CONTACTS_SORT = "contacts.sort";
const PAYMENTS_SORT = "payments.sort";

var _data = {
	SETTING_VIBRATE: true,
	SETTING_DEFAULT_CURRENCY: "SEK",
	CONTACTS_SORT: 0,
	PAYMENTS_SORT: 0
};

func write_persistent(key: String, value: Variant):
	_data[key] = value;

func try_get_persistent(key: String) -> Variant:
	if !_data.has(key):
		return null;

	return _data[key];
