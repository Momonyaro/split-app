extends PanelContainer
class_name FloatingButton;

signal pressed;

func _ready():
	$MarginContainer/Button.pressed.connect(func (): pressed.emit());
