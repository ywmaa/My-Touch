extends HBoxContainer
class_name Vector2Edit

var value: Vector2
var lock_aspect: bool = false
signal value_changed(value:Vector2)
signal lock_aspect_changed(value:bool)

@onready var float_edit_x = $VBoxContainer/PanelContainer/HBoxContainer/FloatEditX
@onready var float_edit_y = $VBoxContainer/Panel/HBoxContainer/FloatEditY
@onready var lock_button = $LockButton



func _ready():
	float_edit_x.value = value.x
	float_edit_y.value = value.y
	lock_button.button_pressed = lock_aspect
	float_edit_x.value_changed.connect(x_value_changed)
	float_edit_y.value_changed.connect(y_value_changed)
	lock_button.toggled.connect(_on_lock_button_toggled)

#func _enter_tree():


func x_value_changed(v: float):
	if lock_aspect:
		float_edit_y.value_changed.disconnect(y_value_changed)
		float_edit_y.value += v - value.x
		value.y = float_edit_y.value
		float_edit_y.value_changed.connect(y_value_changed)
	value.x = v
	value_changed.emit(value)

func y_value_changed(v: float):
	if lock_aspect:
		float_edit_x.value_changed.disconnect(x_value_changed)
		float_edit_x.value += v - value.y
		value.x = float_edit_x.value
		float_edit_x.value_changed.connect(x_value_changed)
	value.y = v
	value_changed.emit(value)


func _on_lock_button_toggled(toggled_on):
	lock_aspect = toggled_on
	lock_aspect_changed.emit(lock_aspect)
