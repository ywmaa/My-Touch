extends ToolBase

## Drag on the canvas to fill the paint layer with a gradient from the press point to the release point.
## After releasing, the last gradient stays editable: drag one of its end handles to adjust it.
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

var edited_layer : paint_layer
var current_stroke : Stroke
var start_point : Vector2
var end_point : Vector2
## Which point is being dragged: -1 none, 0 start, 1 end (a new gradient drags its end).
var dragged_point : int = -1
var is_new_gradient : bool = false
# Points before dragging a handle, for undo.
var points_before_edit : PackedVector2Array
# Canvas pixels per screen pixel, taken from the preview when drawing.
var view_scale : float = 1.0

func _init():
	tool_name = "Gradient Tool"
	tool_button_shortcut = "Shift+D"
	tool_desc = "Drag to draw a gradient, drag its ends to adjust it"
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
	changed.emit()
	# Settings apply to the gradient being edited, so they can be tweaked after drawing it.
	if _has_editable_stroke():
		_apply_to_stroke()
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

func _apply_to_stroke():
	current_stroke.mode = Stroke.MODE.ERASE if mode == E_MODE.ERASE else Stroke.MODE.DRAW
	current_stroke.gradient_shape = shape as Stroke.GRADIENT_SHAPE
	current_stroke.set_gradient(start_point, end_point, get_start_color(), get_end_color())

func _has_editable_stroke() -> bool:
	# The gradient may have been removed by undo, or the layer deleted.
	return current_stroke != null and edited_layer != null and edited_layer.strokes.has(current_stroke)


# Polled every frame, like the brush, so it works even when no layer is selected yet.
func shortcut_pressed():
	if ToolsManager.current_tool != self:
		if tool_active:
			cancel_tool()
		current_stroke = null # Handles are only kept while the tool is selected
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
	# Grab a handle of the gradient being edited, the nearest one wins.
	if _has_editable_stroke():
		var grab_distance := _handle_radius() * 1.5
		var to_start := pos.distance_to(start_point)
		var to_end := pos.distance_to(end_point)
		if min(to_start, to_end) <= grab_distance:
			dragged_point = 0 if to_start < to_end else 1
			is_new_gradient = false
			points_before_edit = PackedVector2Array([start_point, end_point])
			super.enable_tool()
			return
	# Otherwise start a new gradient
	edited_layer = ToolsManager.get_paint_layer() as paint_layer
	if edited_layer == null:
		return
	start_point = pos
	end_point = pos
	dragged_point = 1
	is_new_gradient = true
	current_stroke = Stroke.new()
	current_stroke.type = Stroke.TYPE.GRADIANT
	_apply_to_stroke()
	current_stroke.stroke_node.visible = false # Until it is dragged
	edited_layer.strokes.append(current_stroke)
	edited_layer.main_object.add_child(current_stroke.stroke_node)
	super.enable_tool()

func _drag_to(pos: Vector2):
	if !_has_editable_stroke():
		return
	if dragged_point == 0:
		if pos == start_point:
			return
		start_point = pos
	else:
		if pos == end_point:
			return
		end_point = pos
	_apply_to_stroke()
	current_stroke.stroke_node.visible = !is_new_gradient or _dragged_far_enough()

func _dragged_far_enough() -> bool:
	return start_point.distance_to(end_point) >= MIN_DRAG_DISTANCE * view_scale

func cancel_tool():
	if is_new_gradient and current_stroke:
		_remove_new_stroke()
	else:
		cancel_edit()
	super.cancel_tool()
	dragged_point = -1

func confirm_tool():
	if is_new_gradient:
		if !_dragged_far_enough():
			_remove_new_stroke() # A tap, not a gradient
			tool_active = false
			dragged_point = -1
			return
		_commit_new_stroke()
	elif _has_editable_stroke():
		var points_after := PackedVector2Array([start_point, end_point])
		if points_after == points_before_edit:
			tool_active = false
			dragged_point = -1
			return
		var undo_redo : UndoRedo = ToolsManager.current_project.undo_redo
		undo_redo.create_action("Edit Gradient")
		undo_redo.add_do_method(_set_stroke_points.bind(current_stroke, points_after))
		undo_redo.add_undo_method(_set_stroke_points.bind(current_stroke, points_before_edit))
		undo_redo.commit_action(false)
	dragged_point = -1
	is_new_gradient = false
	super.confirm_tool()

func cancel_edit():
	if !is_new_gradient and _has_editable_stroke() and points_before_edit.size() == 2:
		_set_stroke_points(current_stroke, points_before_edit)

func _set_stroke_points(stroke: Stroke, new_points: PackedVector2Array):
	stroke.points = new_points
	stroke.update()
	if stroke == current_stroke:
		start_point = new_points[0]
		end_point = new_points[1]

func _remove_new_stroke():
	if edited_layer:
		edited_layer.strokes.erase(current_stroke)
		if current_stroke.stroke_node.get_parent():
			current_stroke.stroke_node.get_parent().remove_child(current_stroke.stroke_node)
	current_stroke = null
	is_new_gradient = false

func _commit_new_stroke():
	var undo_redo : UndoRedo = ToolsManager.current_project.undo_redo
	var strokes_before : Array[Stroke] = edited_layer.strokes.duplicate()
	strokes_before.erase(current_stroke)
	undo_redo.create_action("Gradient")
	undo_redo.add_undo_property(edited_layer, "strokes", strokes_before)
	undo_redo.add_undo_method(edited_layer.main_object.remove_child.bind(current_stroke.stroke_node))
	undo_redo.add_undo_method(edited_layer.main_object.queue_redraw)
	undo_redo.add_do_property(edited_layer, "strokes", edited_layer.strokes.duplicate())
	undo_redo.add_do_method(edited_layer.main_object.add_child.bind(current_stroke.stroke_node))
	undo_redo.add_do_reference(current_stroke.stroke_node)
	undo_redo.add_do_method(edited_layer.main_object.queue_redraw)
	undo_redo.commit_action(false)
	current_stroke.need_redraw = false


func draw_preview(image_view : CanvasItem, mouse_position : Vector2i):
	var screen_scale := image_view.get_global_transform_with_canvas().get_scale().x
	view_scale = 1.0 / screen_scale if screen_scale > 0.0 else 1.0
	var line_width := 1.5 * view_scale
	if !_has_editable_stroke() or (is_new_gradient and !_dragged_far_enough()):
		if !DisplayServer.is_touchscreen_available():
			draw_crosshair(image_view, mouse_position, 3, Color.WHITE)
		return
	var radius := _handle_radius()
	# Dark outline under a light line so it's visible on any image
	image_view.draw_line(start_point, end_point, Color(0, 0, 0, 0.6), line_width * 3.0)
	image_view.draw_line(start_point, end_point, Color.WHITE, line_width)
	if shape == E_SHAPE.RADIAL:
		image_view.draw_arc(start_point, start_point.distance_to(end_point), 0.0, TAU, 64, Color(1, 1, 1, 0.5), line_width)
	for i in 2:
		var point := start_point if i == 0 else end_point
		var handle_color : Color = get_start_color() if i == 0 else get_end_color()
		handle_color.a = 1.0
		image_view.draw_circle(point, radius, Color(0, 0, 0, 0.6))
		image_view.draw_circle(point, radius - line_width, handle_color)
		image_view.draw_arc(point, radius - line_width, 0.0, TAU, 32, Color.WHITE if dragged_point != i else ToolsManager.selected_tool_color, line_width)
