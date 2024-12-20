extends Camera2D

enum Cameras { MAIN, SECOND, SMALL }

const KEY_MOVE_ACTION_NAMES := ["ui_left", "ui_right", "ui_up", "ui_down"]
const CAMERA_SPEED_RATE := 15.0

var zoom_min := Vector2(0.005, 0.005)
var zoom_max := Vector2(5,5)
var viewport_container: SubViewportContainer
var transparent_checker: ColorRect
var mouse_pos := Vector2.ZERO
var drag := false
var index := 0


func _ready() -> void:
	
	ignore_rotation = false
	viewport_container = get_parent().get_parent()
	transparent_checker = get_parent().get_node("TransparentChecker")
	update_transparent_checker_offset()

#	# signals regarding rotation stats
#	Global.rotation_level_button.connect("pressed", self, "_rotation_button_pressed")
#	Global.rotation_level_spinbox.connect("value_changed", self, "_rotation_value_changed")
#	Global.rotation_level_spinbox.get_child(0).connect(
#		"focus_exited", self, "_rotation_focus_exited"
#	)

#func _rotation_button_pressed() -> void:
#	Global.rotation_level_button.visible = false
#	Global.rotation_level_spinbox.visible = true
#	Global.rotation_level_spinbox.editable = true
#	Global.rotation_level_spinbox.value = str2var(
#		Global.rotation_level_button.text.replace("°", "")
#	)
#	# Since the actual LineEdit is the first child of SpinBox
#	Global.rotation_level_spinbox.get_child(0).grab_focus()


func _rotation_value_changed(value) -> void:
	if index == Cameras.MAIN:
		_set_camera_rotation_degrees(-value)  # Negative makes going up rotate clockwise


#func _rotation_focus_exited() -> void:
#	if Global.rotation_level_spinbox.value != rotation:  # If user pressed enter while editing
#		if index == Cameras.MAIN:
#			# Negative makes going up rotate clockwise
#			_set_camera_rotation_degrees(-Global.rotation_level_spinbox.value)
#	Global.rotation_level_button.visible = true
#	Global.rotation_level_spinbox.visible = false
#	Global.rotation_level_spinbox.editable = false

func _zoom_value_changed(value) -> void:
	if index == Cameras.MAIN:
		zoom_camera_percent(value)


func update_transparent_checker_offset() -> void:
	var o = get_global_transform_with_canvas().get_origin()
	var s = get_global_transform_with_canvas().get_scale()
	o.y = get_viewport_rect().size.y - o.y
	transparent_checker.update_offset(o, s)


func _input(event: InputEvent) -> void:
	if !mt_globals.can_draw:
		drag = false
		return
	mouse_pos = viewport_container.get_local_mouse_position()
	var viewport_size = viewport_container.get_rect().size
	if !Rect2(Vector2.ZERO, viewport_size).has_point(mouse_pos):
		drag = false
		return

	var get_velocity := false
	for action in KEY_MOVE_ACTION_NAMES:
		if event.is_action(action):
			get_velocity = true

	if get_velocity:
		var velocity := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
#		if velocity != Vector2.ZERO and !_has_selection_tool():
		offset += velocity.rotated(rotation) * zoom * CAMERA_SPEED_RATE
#			_update_rulers()

	if event.is_action_pressed("pan"):
		drag = true
	elif event.is_action_released("pan"):
		drag = false
	elif event.is_action_pressed("zoom_in", false, true):  # Wheel Up Event
		if !drag:
			zoom_camera(-1)
	elif event.is_action_pressed("zoom_out", false, true):  # Wheel Down Event
		if !drag:
			zoom_camera(1)
	elif event is InputEventPanGesture:
		# Pan Gesture on a Laptop touchpad
		offset = offset + event.delta.rotated(rotation) * 1/zoom * 2  # for moving the canvas
	elif event is InputEventMagnifyGesture:  # Zoom Gesture on a Laptop touchpad
		if event.factor < 1:
			zoom_camera(-0.2*event.factor)
		else:
			zoom_camera(0.2*event.factor)
	elif event is InputEventMouseMotion && drag:
		offset = offset - event.relative.rotated(rotation) * 1/zoom
		update_transparent_checker_offset()
#		_update_rulers()

#	save_values_to_project()


# Rotate Camera
func _rotate_camera_around_point(degrees: float, point: Vector2) -> void:
	offset = (offset - point).rotated(deg_to_rad(degrees)) + point
	rotation = wrapf(rotation + degrees, -180, 180)
#	rotation_changed()


func _set_camera_rotation_degrees(degrees: float) -> void:
	var difference := degrees - rotation
	var canvas_center: Vector2 = mt_globals.main_window.get_current_graph_edit().canvas_size / 2
	offset = (offset - canvas_center).rotated(deg_to_rad(difference)) + canvas_center
	rotation = wrapf(degrees, -180, 180)
#	rotation_changed()


#func rotation_changed() -> void:
#	if index == Cameras.MAIN:
#		# Negative to make going up in value clockwise, and match the spinbox which does the same
#		Global.rotation_level_button.text = str(wrapi(round(-rotation), -180, 180)) + " °"
#		_update_rulers()


# Zoom Camera
func zoom_camera(dir: float) -> void:
	var viewport_size = get_viewport().size
	if mt_globals.smooth_zoom:
		var zoom_margin = (zoom * dir) / (pow(mt_globals.zoom_speed, -1))
		var new_zoom = zoom + zoom_margin
		if new_zoom > zoom_min && new_zoom < zoom_max:
			var new_offset = (
				offset
				+ ((viewport_size * 0.5) - mouse_pos).rotated(rotation) * -(new_zoom - zoom)
			)
			var tween := create_tween().set_parallel()
			tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
			tween.connect("step_finished", _on_tween_step)
			tween.tween_property(self, "zoom", new_zoom, 0.05)
			#tween.tween_property(self, "offset", new_offset, 0.05)

	else:
		var prev_zoom := zoom
		var zoom_margin = zoom * dir / 5.0
		if zoom + zoom_margin > zoom_min:
			zoom += zoom_margin

		if zoom > zoom_max:
			zoom = zoom_max

		#offset = offset + ((viewport_size * 0.5) - mouse_pos).rotated(rotation) * -(zoom - prev_zoom)
		zoom_changed()


func zoom_camera_percent(value: float) -> void:
	var percent: float = value / 100.0
	var new_zoom = Vector2(percent, percent)
	if mt_globals.smooth_zoom:
		var tween := create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
		tween.connect("step_finished", _on_tween_step)
		tween.tween_property(self, "zoom", new_zoom, 0.05)
	else:
		zoom = new_zoom
		zoom_changed()


func zoom_changed() -> void:
	update_transparent_checker_offset()
#	viewport_container.canvas.pixel_grid.queue_redraw()
#	_update_rulers()
#	for guide in Global.current_project.guides:
#		guide.width = zoom.x * 2
#
#	Global.canvas.selection.update_on_zoom(zoom.x)


#func _update_rulers() -> void:
#	Global.horizontal_ruler.update()
#	Global.vertical_ruler.update()


func _on_tween_step(_idx: int) -> void:
	zoom_changed()


func zoom_100() -> void:
	zoom = Vector2.ONE
	offset = ProjectsManager.current_project.canvas_size / 2
	zoom_changed()


func fit_to_frame(size: Vector2) -> void:
	offset = size / 2

	# Adjust to the rotated size:
	if rotation != 0.0:
		# Calculating the rotated corners of the frame to find its rotated size
		var a := Vector2.ZERO  # Top left
		var b := Vector2(size.x, 0).rotated(rotation)  # Top right
		var c := Vector2(0, size.y).rotated(rotation)  # Bottom left
		var d := Vector2(size.x, size.y).rotated(rotation)  # Bottom right

		# Find how far apart each opposite point is on each axis, and take the longer one
		size.x = max(abs(a.x - d.x), abs(b.x - c.x))
		size.y = max(abs(a.y - d.y), abs(b.y - c.y))

	viewport_container = get_parent().get_parent()
	var h_ratio := size.x / viewport_container.get_rect().size.x
	var v_ratio := size.y / viewport_container.get_rect().size.y
	var ratio = max(h_ratio, v_ratio)
	if ratio == 0 or !viewport_container.visible:
		ratio = 0.1  # Set it to a non-zero value just in case

	ratio = clamp(ratio, 0.1, ratio)
	zoom = Vector2(1 / ratio, 1 / ratio) - (Vector2.ONE*0.01)
	zoom_changed()


#func save_values_to_project() -> void:
#	Global.current_project.cameras_rotation[index] = rotation
#	Global.current_project.cameras_zoom[index] = zoom
#	Global.current_project.cameras_offset[index] = offset
#	Global.current_project.cameras_zoom_max[index] = zoom_max
