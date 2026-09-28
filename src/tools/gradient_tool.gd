extends ToolBase

## Drag on the canvas to create a gradient layer from the press point to the release point.
## When the active layer is a gradient layer, its end handles can always be dragged to edit it,
## and the tool settings show (and change) that layer's gradient.
## Works the same with a mouse and with touch (touch is emulated as the left mouse button).

enum E_MODE { DRAW, ERASE }
enum E_SHAPE { LINEAR, RADIAL, REFLECTED }

var mode : E_MODE = E_MODE.DRAW:
	set(v):
		mode = v
		_on_settings_changed()
var shape : E_SHAPE = E_SHAPE.LINEAR:
	set(v):
		shape = v
		_on_settings_changed()
var drawing_color1 := Color.BLACK:
	set(v):
		drawing_color1 = v
		_on_settings_changed()
var drawing_color2 := Color.WHITE:
	set(v):
		drawing_color2 = v
		_on_settings_changed()
var switch_color_function : Callable = switch_color
## End with the start color fully transparent instead of the second color.
var fade_to_transparent := false:
	set(v):
		fade_to_transparent = v
		_on_settings_changed()
var opacity : float = 1.0:
	set(v):
		opacity = v
		_on_settings_changed()

## Handle size on screen, bigger on touch screens so fingers can grab them.
const HANDLE_RADIUS_MOUSE := 7.0
const HANDLE_RADIUS_TOUCH := 22.0
## Drags shorter than this (screen pixels) are treated as a tap and ignored.
const MIN_DRAG_DISTANCE := 4.0

## The gradient layer being created or edited.
var edited_layer : gradient_layer
## Which point is being dragged: -1 none, 0 start, 1 end (a new gradient drags its end).
var dragged_point : int = -1
var is_new_gradient : bool = false
# Points before dragging a handle, for undo.
var points_before_edit : PackedVector2Array
# Canvas pixels per screen pixel, taken from the preview when drawing.
var view_scale : float = 1.0
# Set while copying a layer's gradient into the settings, so it isn't written back.
var _syncing : bool = false
var _synced_layer : gradient_layer

func _init():
	tool_name = "Gradient Tool"
	tool_button_shortcut = "Shift+D"
	tool_desc = "Drag to create a gradient layer, drag its ends to edit it"
	tool_icon = get_icon_from_project_folder("gradient")

func get_inspector_properties():
	var PropertiesGroups : Array[String] = ["Settings", "Color"]
	var PropertiesToShow : Dictionary = {}
	PropertiesToShow["mode,Draw,Erase"] = "Settings"
	PropertiesToShow["shape,Linear,Radial,Reflected"] = "Settings"
	PropertiesToShow["opacity:minvalue:0.0:maxvalue:1.0:step:0.01"] = "Settings"
	if mode == E_MODE.DRAW:
		PropertiesToShow["drawing_color1"] = "Color"
		if !fade_to_transparent:
			PropertiesToShow["drawing_color2"] = "Color"
			PropertiesToShow["switch_color_function"] = "Color"
		PropertiesToShow["fade_to_transparent"] = "Color"
	return [PropertiesGroups, PropertiesToShow]

func switch_color():
	var color1 : Color = drawing_color1
	drawing_color1 = drawing_color2
	drawing_color2 = color1
	changed.emit()

func _on_settings_changed():
	if _syncing:
		return
	changed.emit()
	# Settings apply to the active gradient layer, so it can be tweaked any time.
	var layer := get_editable_layer()
	if layer:
		_apply_settings_to(layer)
		_synced_state = _layer_state(layer) # Our own change, don't sync it back
		ProjectsManager.send_changed_signal()

func get_start_color() -> Color:
	if mode == E_MODE.ERASE:
		return Color(0, 0, 0, opacity) # Erase fully at the start...
	var color := drawing_color1
	color.a *= opacity
	return color

func get_end_color() -> Color:
	if mode == E_MODE.ERASE:
		return Color(0, 0, 0, 0) # ...fading to no erasing at the end
	var color := drawing_color1 if fade_to_transparent else drawing_color2
	color.a = 0.0 if fade_to_transparent else color.a * opacity
	return color

func _apply_settings_to(layer: gradient_layer):
	layer.mode = gradient_layer.MODE.ERASE if mode == E_MODE.ERASE else gradient_layer.MODE.DRAW
	layer.shape = shape as gradient_layer.SHAPE
	layer.start_color = get_start_color()
	layer.end_color = get_end_color()

## Show the layer's gradient in the tool settings (e.g. after it was edited in the inspector).
func _sync_settings_from(layer: gradient_layer):
	_syncing = true
	mode = E_MODE.ERASE if layer.mode == gradient_layer.MODE.ERASE else E_MODE.DRAW
	shape = layer.shape as E_SHAPE
	opacity = layer.start_color.a
	if mode == E_MODE.DRAW:
		drawing_color1 = Color(layer.start_color, 1.0)
		fade_to_transparent = layer.end_color.a == 0.0 and Color(layer.end_color, 1.0) == drawing_color1
		if !fade_to_transparent:
			drawing_color2 = Color(layer.end_color, 1.0)
	_syncing = false
	changed.emit()

# Last known gradient of the synced layer, to notice edits made elsewhere (e.g. the inspector)
var _synced_state : Array = []

func _layer_state(layer: gradient_layer) -> Array:
	return [layer.start_color, layer.end_color, layer.shape, layer.mode]

## The active layer when it's a visible gradient layer: the one handles and settings edit.
func get_editable_layer() -> gradient_layer:
	if !ToolsManager.current_project:
		return null
	var layer := ToolsManager.current_project.layers_container.get_active_layer() as gradient_layer
	if layer == null or layer.hidden or !ToolsManager.current_project.layers_container.find_parent_array(layer):
		return null
	return layer


# Polled every frame, like the brush, so it works even when no layer is selected yet.
func shortcut_pressed():
	if ToolsManager.current_tool != self:
		if tool_active:
			cancel_tool()
		_synced_layer = null
		return
	if Input.is_action_just_pressed("cancel") and tool_active:
		cancel_tool()
		return
	if Input.is_action_just_pressed("mouse_left") and !tool_active:
		_begin_drag(ToolsManager.current_mouse_position)
	elif tool_active:
		_drag_to(ToolsManager.current_mouse_position)
		if !Input.is_action_pressed("mouse_left"):
			confirm_tool()

## Called every frame while this is the current tool (even when the mouse is over other panels):
## keeps the settings showing the active gradient layer, e.g. after editing it in the inspector.
func update_every_frame():
	var layer := get_editable_layer()
	if layer and !tool_active and (layer != _synced_layer or _layer_state(layer) != _synced_state):
		_sync_settings_from(layer)
	_synced_layer = layer
	_synced_state = _layer_state(layer) if layer else []

func mouse_pressed(event : InputEventMouseButton, _image : base_layer):
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and tool_active:
		cancel_tool()

func mouse_moved(_event : InputEventMouseMotion):
	if tool_active:
		_drag_to(ToolsManager.current_mouse_position)

func key_pressed(_event : InputEventKey):
	pass

func multi_touch_started():
	# Pinching or panning with two fingers, the first finger was not meant to draw.
	if tool_active:
		cancel_tool()

func _handle_radius() -> float:
	var radius := HANDLE_RADIUS_TOUCH if DisplayServer.is_touchscreen_available() else HANDLE_RADIUS_MOUSE
	return radius * view_scale

func _begin_drag(pos: Vector2):
	# Grab a handle of the active gradient layer, the nearest one wins.
	var layer := get_editable_layer()
	if layer:
		var grab_distance := _handle_radius() * 1.5
		var to_start := pos.distance_to(layer.point_to_canvas(layer.start_point))
		var to_end := pos.distance_to(layer.point_to_canvas(layer.end_point))
		if min(to_start, to_end) <= grab_distance:
			edited_layer = layer
			dragged_point = 0 if to_start < to_end else 1
			is_new_gradient = false
			points_before_edit = PackedVector2Array([layer.start_point, layer.end_point])
			super.enable_tool()
			return
	# Otherwise create a new gradient layer, on top
	var project := ToolsManager.current_project
	edited_layer = gradient_layer.new()
	edited_layer.name = _unused_gradient_name()
	edited_layer.parent_project = project
	_apply_settings_to(edited_layer)
	edited_layer.polygon.visible = false # Until it is dragged
	project.layers_container.add_layer(edited_layer)
	var point := edited_layer.point_from_canvas(pos)
	edited_layer.start_point = point
	edited_layer.end_point = point
	dragged_point = 1
	is_new_gradient = true
	super.enable_tool()

func _unused_gradient_name() -> String:
	var names : Array = []
	for l in ToolsManager.current_project.layers_container.layers:
		names.append(l.name)
	var count := 1
	while names.has("Gradient %d" % count):
		count += 1
	return "Gradient %d" % count

func _drag_to(pos: Vector2):
	if edited_layer == null:
		return
	var point := edited_layer.point_from_canvas(pos)
	if dragged_point == 0:
		edited_layer.start_point = point
	else:
		edited_layer.end_point = point
	edited_layer.polygon.visible = !is_new_gradient or _dragged_far_enough()

func _dragged_far_enough() -> bool:
	return edited_layer.point_to_canvas(edited_layer.start_point).distance_to(edited_layer.point_to_canvas(edited_layer.end_point)) >= MIN_DRAG_DISTANCE * view_scale

func cancel_tool():
	if edited_layer:
		if is_new_gradient:
			_remove_new_layer()
		elif points_before_edit.size() == 2:
			_set_layer_points(edited_layer, points_before_edit)
	super.cancel_tool()
	_end_drag()

func confirm_tool():
	if edited_layer == null:
		tool_active = false
		return
	if is_new_gradient:
		if !_dragged_far_enough():
			_remove_new_layer() # A tap, not a gradient
			tool_active = false
			_end_drag()
			return
		_commit_new_layer()
	else:
		var points_after := PackedVector2Array([edited_layer.start_point, edited_layer.end_point])
		if points_after == points_before_edit:
			tool_active = false
			_end_drag()
			return
		var undo_redo : UndoRedo = ToolsManager.current_project.undo_redo
		undo_redo.create_action("Edit Gradient")
		undo_redo.add_do_method(_set_layer_points.bind(edited_layer, points_after))
		undo_redo.add_undo_method(_set_layer_points.bind(edited_layer, points_before_edit))
		undo_redo.commit_action(false)
	_end_drag()
	super.confirm_tool()

func _end_drag():
	dragged_point = -1
	is_new_gradient = false
	edited_layer = null

func _set_layer_points(layer: gradient_layer, new_points: PackedVector2Array):
	layer.start_point = new_points[0]
	layer.end_point = new_points[1]

func _remove_new_layer():
	ToolsManager.current_project.layers_container.remove_layer(edited_layer)
	edited_layer = null
	is_new_gradient = false

func _commit_new_layer():
	var layers : layers_manager = ToolsManager.current_project.layers_container
	var previous_selection : Array[base_layer] = layers.selected_layers.duplicate()
	previous_selection.erase(edited_layer)
	var new_selection : Array[base_layer] = [edited_layer]
	var undo_redo : UndoRedo = ToolsManager.current_project.undo_redo
	undo_redo.create_action("Gradient Layer")
	undo_redo.add_do_method(layers.add_layer.bind(edited_layer))
	undo_redo.add_do_property(layers, "selected_layers", new_selection)
	undo_redo.add_do_reference(edited_layer)
	undo_redo.add_undo_method(layers.remove_layer.bind(edited_layer))
	undo_redo.add_undo_property(layers, "selected_layers", previous_selection)
	undo_redo.commit_action(false)
	edited_layer.polygon.visible = true
	# The new gradient becomes the active layer, so it can be edited right away
	layers.selected_layers = new_selection
	_synced_layer = edited_layer
	_synced_state = _layer_state(edited_layer)


func draw_preview(image_view : CanvasItem, mouse_position : Vector2i):
	var screen_scale := image_view.get_global_transform_with_canvas().get_scale().x
	view_scale = 1.0 / screen_scale if screen_scale > 0.0 else 1.0
	var layer : gradient_layer = edited_layer if edited_layer else get_editable_layer()
	if layer == null or (is_new_gradient and !_dragged_far_enough()):
		if !DisplayServer.is_touchscreen_available():
			draw_crosshair(image_view, mouse_position, 3, Color.WHITE)
		return
	var line_width := 1.5 * view_scale
	var radius := _handle_radius()
	var start := layer.point_to_canvas(layer.start_point)
	var end := layer.point_to_canvas(layer.end_point)
	# Dark outline under a light line so it's visible on any image
	image_view.draw_line(start, end, Color(0, 0, 0, 0.6), line_width * 3.0)
	image_view.draw_line(start, end, Color.WHITE, line_width)
	if layer.shape == gradient_layer.SHAPE.RADIAL:
		image_view.draw_arc(start, start.distance_to(end), 0.0, TAU, 64, Color(1, 1, 1, 0.5), line_width)
	for i in 2:
		var point := start if i == 0 else end
		var handle_color : Color = layer.start_color if i == 0 else layer.end_color
		if layer.mode == gradient_layer.MODE.ERASE:
			handle_color = Color.WHITE if i == 0 else Color.GRAY
		handle_color.a = 1.0
		image_view.draw_circle(point, radius, Color(0, 0, 0, 0.6))
		image_view.draw_circle(point, radius - line_width, handle_color)
		image_view.draw_arc(point, radius - line_width, 0.0, TAU, 32, Color.WHITE if dragged_point != i else ToolsManager.selected_tool_color, line_width)
