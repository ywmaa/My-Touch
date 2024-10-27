extends SpinBox
class_name FloatEdit


var sliding : bool = false
var start_position : float
var last_position : float
var start_value : float
var modifiers : int
var from_lower_bound : bool = false
var from_upper_bound : bool = false



signal value_changed_undo(value, merge_undo)
var has_focus : bool
func _ready() -> void:
	get_line_edit().deselect_on_focus_loss_enabled = true
	self.connect("mouse_entered",_on_mouse_entered)
	self.connect("mouse_exited",_on_mouse_exited)

func get_modifiers(event):
	var new_modifiers = 0
	if event.shift_pressed:
		new_modifiers |= 1
	if event.ctrl_pressed:
		new_modifiers |= 2
	if event.alt_pressed:
		new_modifiers |= 4
	return new_modifiers

func _input(event : InputEvent) -> void:
	#if !has_focus:
		#get_line_edit().deselect()
		#get_line_edit().release_focus()
	if !sliding and !editable:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		
		if event.is_pressed() and has_focus:
			get_line_edit().grab_focus()
			get_line_edit().select_all()
			last_position = event.position.x
			start_position = last_position
			start_value = value
			sliding = true
			from_lower_bound = value <= min_value
			from_upper_bound = value >= max_value
			modifiers = get_modifiers(event)
			emit_signal("value_changed_undo", value)
			editable = true
			get_line_edit().selecting_enabled = false
			#Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
		else:
			sliding = false
			editable = true
			#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_line_edit().selecting_enabled = true

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


func _on_mouse_entered():
	has_focus = true


func _on_mouse_exited():
	has_focus = false
