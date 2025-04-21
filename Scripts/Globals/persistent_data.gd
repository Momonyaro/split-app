extends Node

var _data = {
	"setting.vibrate": true,
	"contacts.sort": 0
};

func write_persistent(key: String, value: Variant):
	_data[key] = value;

func try_get_persistent(key: String) -> Variant:
	if !_data.has(key):
		return null;

	return _data[key];
