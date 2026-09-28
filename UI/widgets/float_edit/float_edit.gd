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

# Touch: a press waits to see if it's a tap (type a value), a horizontal drag (slide the value)
# or a vertical drag (scrolling the panel), so scrolling doesn't open the keyboard.
const TOUCH_DRAG_THRESHOLD := 12.0
var touch_pending : bool = false
var touch_press_position : Vector2
# Shows the value being typed above the on-screen keyboard, which covers the field.
var touch_preview : CanvasLayer = null

func _ready() -> void:
	get_line_edit().deselect_on_focus_loss_enabled = true
	get_line_edit().virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
	get_line_edit().focus_exited.connect(_on_line_edit_focus_exited)
	get_line_edit().text_changed.connect(_update_touch_preview.unbind(1))
	get_line_edit().text_submitted.connect(_on_line_edit_text_submitted)
	self.connect("mouse_entered",_on_mouse_entered)
	self.connect("mouse_exited",_on_mouse_exited)
	set_process(false) # Only while the typing preview is shown

func _exit_tree() -> void:
	_hide_touch_preview()

func _start_sliding(x_position: float, event) -> void:
	last_position = x_position
	start_position = last_position
	start_value = value
	sliding = true
	from_lower_bound = value <= min_value
	from_upper_bound = value >= max_value
	modifiers = get_modifiers(event)
	emit_signal("value_changed_undo", value)
	editable = true
	get_line_edit().selecting_enabled = false

func _set_focusable(focusable: bool) -> void:
	var mode := Control.FOCUS_ALL if focusable else Control.FOCUS_NONE
	get_line_edit().focus_mode = mode
	focus_mode = mode

var touch_keyboard_suppressed : bool = false

func _restore_virtual_keyboard() -> void:
	touch_keyboard_suppressed = false
	get_line_edit().virtual_keyboard_enabled = true

## A deliberate tap: edit the value with the on-screen keyboard.
func _start_touch_typing() -> void:
	_set_focusable(true)
	get_line_edit().grab_focus()
	get_line_edit().select_all()
	_show_touch_preview()

func _on_line_edit_focus_exited() -> void:
	_hide_touch_preview()

func _on_line_edit_text_submitted(_text: String) -> void:
	if touch_preview: # Done on the on-screen keyboard: finish editing
		get_line_edit().release_focus()
		_hide_touch_preview()

func _show_touch_preview() -> void:
	if touch_preview:
		return
	touch_preview = CanvasLayer.new()
	touch_preview.layer = 128
	var panel := PanelContainer.new()
	panel.name = "Panel"
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	var label := Label.new()
	label.name = "Label"
	label.add_theme_font_size_override("font_size", 56)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	margin.add_child(label)
	panel.add_child(margin)
	touch_preview.add_child(panel)
	get_tree().root.add_child(touch_preview)
	_update_touch_preview()
	set_process(true)

func _hide_touch_preview() -> void:
	set_process(false)
	if touch_preview:
		touch_preview.queue_free()
		touch_preview = null

## Name of the property this field edits, from the label next to it (if any).
func _get_field_name() -> String:
	if get_parent():
		for child in get_parent().get_children():
			if child is Label and child.text != "":
				return child.text
	return ""

func _update_touch_preview() -> void:
	if !touch_preview:
		return
	var panel : PanelContainer = touch_preview.get_node("Panel")
	var field_name := _get_field_name()
	var text := get_line_edit().text
	panel.find_child("Label", true, false).text = (field_name + ": " if field_name != "" else "") + text
	panel.reset_size()
	# Just above the on-screen keyboard (or near the top until its height is known)
	var root := get_tree().root
	var visible_size := root.get_visible_rect().size
	var keyboard_height := DisplayServer.virtual_keyboard_get_height() / root.content_scale_factor
	var y := visible_size.y - keyboard_height - panel.size.y - 16.0 if keyboard_height > 0 else 48.0
	panel.position = Vector2((visible_size.x - panel.size.x) * 0.5, max(y, 8.0))

func _process(_delta: float) -> void:
	if touch_preview:
		_update_touch_preview() # The keyboard slides in, follow it

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
			if event.device == InputEvent.DEVICE_ID_EMULATION:
				# Touch: decide on release/drag. Not focusable meanwhile, so the press itself
				# doesn't open the keyboard, but still reaches the panel so it can scroll.
				if !get_line_edit().has_focus():
					_set_focusable(false)
				# LineEdit also shows the keyboard on every release it gets, so keep it off until
				# we know this is a tap (not a slide or a scroll)
				get_line_edit().virtual_keyboard_enabled = false
				touch_keyboard_suppressed = true
				touch_pending = true
				touch_press_position = event.position
				return
			_set_focusable(true)
			get_line_edit().grab_focus()
			get_line_edit().select_all()
			_start_sliding(event.position.x, event)
			#Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
		else:
			if touch_pending and !event.is_pressed():
				touch_pending = false
				_restore_virtual_keyboard()
				_start_touch_typing() # A tap, not a drag
			elif touch_keyboard_suppressed and !event.is_pressed():
				# Slide/scroll ended: turn the keyboard back on only after LineEdit got this release
				_restore_virtual_keyboard.call_deferred()
			sliding = false
			editable = true
			#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_line_edit().selecting_enabled = true

	elif touch_pending and event is InputEventMouseMotion:
		var moved : Vector2 = event.position - touch_press_position
		if moved.length() > TOUCH_DRAG_THRESHOLD:
			touch_pending = false
			_set_focusable(true)
			if abs(moved.x) > abs(moved.y):
				_start_sliding(event.position.x, event) # Horizontal: slide the value
				accept_event()
			# Vertical: the panel is being scrolled, leave it alone

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
