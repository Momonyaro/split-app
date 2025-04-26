extends Control

@onready var red_fill = $RED_FILL;
@onready var dimmed_fill = $ColorRect;

@onready var prompt_panel = $PanelContainer;
@onready var instructions = $PanelContainer/VBoxContainer/Instructions;
@onready var outside_warning = $PanelContainer/Control/Instructions;

var _explode_action: Callable;

var fuse_lit := false;
var exploded := false;
var defused := false;
var fuse_time = 3.0;
var _fuse = 0;

func _ready():
	prompt_panel.pivot_offset = prompt_panel.size * 0.5;
	_tween_in();

func _process(delta: float) -> void:
	if fuse_lit && not defused:
		_fuse += delta;
		_fuse = minf(_fuse, fuse_time);
		if _fuse >= fuse_time:
			fuse_lit = false;
			exploded = true;
			if PersistentData.try_get_persistent(PersistentData.SETTING_VIBRATE):
				Input.vibrate_handheld(80, .7); # Slight vibration for device feedback
			_tween_out();
	elif not exploded && not defused:
		_fuse -= delta * 3;
		_fuse = maxf(_fuse, 0);

	_set_red_fill(_fuse / fuse_time);
	_set_dim_fill(_fuse / fuse_time);
	_update_instructions();

func set_explode_action(action: Callable):
	_explode_action = action;

func set_fuse_length(length: float):
	fuse_time = length;

func defuse():
	defused = true;
	exploded = false;
	fuse_lit = false;
	_tween_out();

func _update_instructions():
	instructions.text = str('Keep your finger on the bomb for ' + str(roundi(fuse_time)) + ' seconds.');

func _tween_in():
	prompt_panel.scale = Vector2.ZERO;
	prompt_panel.modulate.a = 0;
	outside_warning.self_modulate.a = 0;
	dimmed_fill.self_modulate.a = 0;

	prompt_panel.create_tween().tween_property(prompt_panel, "scale", Vector2.ONE, 0.1);
	prompt_panel.create_tween().tween_property(prompt_panel, "modulate", Color(1, 1, 1, 1), 0.2);
	dimmed_fill.create_tween().tween_property(dimmed_fill, "self_modulate", Color(1, 1, 1, 1), 0.2);

	await get_tree().create_timer(0.5).timeout;

	outside_warning.create_tween().tween_property(outside_warning, "self_modulate", Color(1, 1, 1, 1), 1);

func _tween_out():
	prompt_panel.scale = Vector2.ONE;
	prompt_panel.modulate.a = 1;
	outside_warning.self_modulate.a = 1;
	dimmed_fill.self_modulate.a = 1;

	prompt_panel.create_tween().tween_property(prompt_panel, "scale", Vector2.ZERO, 0.1);
	prompt_panel.create_tween().tween_property(prompt_panel, "modulate", Color(1, 1, 1, 0), 0.1);
	dimmed_fill.create_tween().tween_property(dimmed_fill, "self_modulate", Color(1, 1, 1, 0), 0.2);
	red_fill.create_tween().tween_property(red_fill, "self_modulate", Color(1, 1, 1, 0), 0.2);
	outside_warning.create_tween().tween_property(outside_warning, "self_modulate", Color(1, 1, 1, 0), .2);

	await get_tree().create_timer(0.2).timeout;

	if exploded:
		_explode_action.call();

	queue_free();

func _set_red_fill(x: float):
	var y = size.y - (size.y * x);

	var _position = Vector2(0, y);
	var _size = Vector2(size.x, size.y * x);
	red_fill.position = _position;
	red_fill.size = _size;

func _set_dim_fill(x: float):
	var alpha = .75;
	dimmed_fill.color.a = alpha + alpha * 0.33 * x;

func _on_bomb_button_up() -> void:
	fuse_lit = false;
	pass # Replace with function body.

func _on_bomb_button_down() -> void:
	fuse_lit = true;
	pass # Replace with function body.

func _on_background_gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and not defused:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			defuse();
	pass # Replace with function body.
