@tool
extends PanelContainer
class_name TextField;

signal value_changed(value: String);

@export var title: String = "Text Field":
	set(new_title):
		_on_title_changed(new_title);
		title = new_title;

@export var required: bool = true:
	set(new_required):
		_on_required_changed(new_required);
		required = new_required;

@export var editable: bool = true:
	set(new_editable):
		_on_editable_changed(new_editable);
		editable = new_editable;

@export var placeholder: String = "Enter text":
	set(new_placeholder):
		_on_placeholder_changed(new_placeholder);
		placeholder = new_placeholder;

var last_value: String = "";
@export var value: String = "":
	set(new_value):
		_on_value_changed(new_value);
		value = new_value;

@export var error_message: String = "":
	set(new_error_message):
		_on_error_message_changed(new_error_message);
		error_message = new_error_message;

##-- INITIALIZATION

func _enter_tree() -> void:
	get_line_edit().text_changed.connect(_on_field_modified);

	_on_title_changed(title);
	_on_required_changed(required);
	_on_editable_changed(editable);
	_on_value_changed(value);
	_on_placeholder_changed(placeholder);
	_on_error_message_changed(error_message);

func _exit_tree() -> void:
	get_line_edit().text_changed.disconnect(_on_field_modified);

func overwrite_value(_value: String) -> void:
	get_line_edit().text = _value;

##-- GETTERS

func get_line_edit() -> LineEdit:
	return $VBoxContainer/LineEdit;

func get_title_label() -> Label:
	return $VBoxContainer/HBoxContainer/Label;

func get_required_label() -> Label:
	return $VBoxContainer/HBoxContainer/Required;

func get_error_label() -> Label:
	return $VBoxContainer/ErrorLabel;

##-- ON CHANGE EVENTS

func _on_title_changed(new_title: String):
	get_title_label().text = new_title;

func _on_required_changed(new_required: bool):
	get_required_label().visible = new_required;

func _on_editable_changed(new_editable: bool):
	get_line_edit().editable = new_editable;

func _on_placeholder_changed(new_placeholder: String):
	get_line_edit().placeholder_text = new_placeholder;

func _on_value_changed(new_value: String):
	if Engine.is_editor_hint():
		get_line_edit().text = new_value;
	value_changed.emit(new_value);

func _on_field_modified(new_value: String):
	value = new_value;

func _on_error_message_changed(new_error_message: String):
	get_error_label().text = new_error_message;
	if new_error_message.length() == 0:
		get_error_label().visible = false;
	else:
		get_error_label().visible = true;
