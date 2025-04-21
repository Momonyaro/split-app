extends Control

const MAX_LINES = 8;
@export var line_height = 20;

var labels = [];

func _ready() -> void:
	write_line("Starting...");

func _process(_delta: float) -> void:
	for i in labels.size():
		var target_pos = Vector2(0, i * line_height);
		labels[i].position.y = lerpf(labels[i].position.y, target_pos.y, 0.25);
		labels[i].self_modulate = Color(1, 1, 1, 1.0 - float(i) / MAX_LINES);

func write_line(text: String) -> void:
	labels.push_front(_create_label(text, self));
	while labels.size() > MAX_LINES:
		var to_delete = labels.pop_back();
		to_delete.queue_free();

func _create_label(text: String, parent: Control) -> Label:
	var label = Label.new()
	label.text = text;
	parent.add_child(label)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT;
	label.uppercase = true;
	label.label_settings = ResourceLoader.load("res://Components/Footer/footer_label_active.tres");
	label.size.x = parent.size.x - (16);
	label.position.x = 16;
	label.set_anchors_preset(Control.PRESET_TOP_WIDE);
	return label
