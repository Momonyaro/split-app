extends Node

const DATASTORE_PATH = "user://datastore.sqlite";

var contact_utils = SQLContactsUtils.new();

var _sqlite = SQLite.new();

func _ready() -> void:
	_sqlite.path = DATASTORE_PATH;
	_sqlite.open_db();

	pass;

func query(_query: String):
	_sqlite.query(_query);

func query_with_bindings(_query: String, _bindings: Array) -> bool:
	return _sqlite.query_with_bindings(_query, _bindings);

func get_query_result() -> Array[Dictionary]:
	return _sqlite.query_result;;

func _exit_tree() -> void:
	_sqlite.close_db();
