extends LineEdit
class_name FloatEdit
@export var value : float = 0.5 :
	set(v):
		if v is float:
			value = clampf(v, min_value, max_value)
			text = str(v)
			do_update()
			$Slider.visible = true
			emit_signal("value_changed", value)
			emit_signal("value_changed_undo", value, false)
@export var min_value : float = 0.0:
	set(v):
		min_value = v
		do_update()
@export var max_value : float = 1.0 :
	set(v):
		max_value = v
		do_update()
@export var step : float = 0.0 :
	set(v):
		step = v
		do_update()
@export var float_only : bool = false

var sliding : bool = false
var start_position : float
var last_position : float
var start_value : float
var modifiers : int
var from_lower_bound : bool = false
var from_upper_bound : bool = false

@onready var slider = $Slider
@onready var cursor = $Slider/Cursor

signal value_changed(value)
signal value_changed_undo(value, merge_undo)

func _ready() -> void:
	connect("text_submitted",_on_LineEdit_text_entered)
	connect("focus_exited",_on_LineEdit_text_entered)
	connect("mouse_exited",_on_LineEdit_text_entered)
	do_update()


func do_update(update_text : bool = true) -> void:
	if update_text and $Slider.visible:
		text = str(value)
		if cursor != null:
			if max_value != min_value:
				cursor.get_rect().size.x = (clamp(value, min_value, max_value)-min_value)*(slider.get_rect().size.x-cursor.get_rect().size.x)/(max_value-min_value)
			else:
				cursor.get_rect().size.x = 0

func get_modifiers(event):
	var new_modifiers = 0
	if event.shift_pressed:
		new_modifiers |= 1
	if event.ctrl_pressed:
		new_modifiers |= 2
	if event.alt_pressed:
		new_modifiers |= 4
	return new_modifiers

func _gui_input(event : InputEvent) -> void:
	if !slider.visible or !sliding and !editable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			if event.double_click:
				await get_tree().process_frame
				select_all()
			else:
				last_position = event.position.x
				start_position = last_position
				start_value = value
				sliding = true
				from_lower_bound = value <= min_value
				from_upper_bound = value >= max_value
				modifiers = get_modifiers(event)
				emit_signal("value_changed_undo", value)
				editable = false
				selecting_enabled = false
		else:
			sliding = false
			editable = true
			selecting_enabled = true
	elif sliding and event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		var new_modifiers = get_modifiers(event)
		if new_modifiers != modifiers:
			start_position = last_position
			start_value = value
			modifiers = new_modifiers
		else:
			last_position = event.position.x
			var delta : float = last_position-start_position
			var current_step = step
			if event.ctrl_pressed:
				delta *= 0.2
			elif event.shift_pressed:
				delta *= 5.0
			if event.alt_pressed:
				current_step *= 0.01
			var v : float = start_value+sign(delta)*pow(abs(delta)*0.005, 2)*abs(max_value - min_value)
			if current_step != 0:
				v = min_value+floor((v - min_value)/current_step)*current_step
			if !from_lower_bound and v < min_value:
				v = min_value
			if !from_upper_bound and v > max_value:
				v = max_value
			value = v
			emit_signal("value_changed", value)
			emit_signal("value_changed_undo", value, true)
		accept_event()
	elif event is InputEventKey and !event.echo:
		match event.keycode:
			
			KEY_SHIFT, KEY_CTRL, KEY_ALT:
				start_position = last_position
				start_value = value
				modifiers = get_modifiers(event)



func _on_LineEdit_text_entered(new_text : String = text, release = true) -> void:
	new_text = str(new_text.to_float())
	var expr : Expression = Expression.new()
	expr.parse(new_text)
	var new_value : float = expr.execute()
	value = new_value
	do_update()
	emit_signal("value_changed", value)
	emit_signal("value_changed_undo", value, false)
	$Slider.visible = true
	if release:
		release_focus()


