extends ToolBase

enum {
  BRUSH_DRAW,
  BRUSH_ERASE,
  BRUSH_PENCIL,
  BRUSH_CLONE,
  BRUSH_SHADING,
  BRUSH_NORMALMAP,
}

var brush_type := 0:
	set(v):
		brush_type = v
		update_tool_ui.call_deferred()
		
@export var crosshair_color := Color(1.0, 1.0, 1.0, 1.0)
@export var crosshair_size := 3
@export var crosshair_size_ruler := 32

var brushsize := 20.0:
	set(x):
		brushsize = x
		brush_offset = Vector2(0.5, 0.5) * float(int(x) % 2)

var brush_offset := Vector2(0.5, 0.5)
var hardness := 1.0
var opacity : float = 1.0
enum pen_flag{size,opacity,tint}
var pen_pressure_usage : pen_flag = pen_flag.size

#var drawing := false
var drawing_color1 := Color()
var drawing_color2 := Color()
var switch_color_function : Callable = switch_color

var ruler_mode := false
var jaggies_removal := true

var edited_object

func _init():
	tool_name = "Brush Tool"
	tool_button_shortcut = "Shift+B"
	tool_desc = ""
	tool_icon = get_icon_from_project_folder("brush")
func get_tool_inspector_properties():
	var PropertiesView : Array = []
	var PropertiesGroups : Array[String] = []
	PropertiesGroups.append("Settings")
	if brush_type == BRUSH_DRAW or brush_type == BRUSH_ERASE or brush_type == BRUSH_PENCIL:
		PropertiesGroups.append("Color")
	if brush_type == BRUSH_PENCIL:
		PropertiesGroups.append("Pencil")
	var PropertiesToShow : Dictionary = {}
	if brush_type == BRUSH_DRAW or brush_type == BRUSH_ERASE or brush_type == BRUSH_PENCIL:
		PropertiesToShow["brush_type,Draw,Erase,Pencil"] = "Settings"
	if brush_type == BRUSH_CLONE:
		PropertiesToShow["copy_from_whole_canvas"] = "Settings"
	if brush_type != BRUSH_PENCIL:
		PropertiesToShow["brushsize:minvalue:1.0:maxvalue:1024.0:step:1.0"] = "Settings"
	PropertiesToShow["hardness:minvalue:0.0:maxvalue:1.0:step:0.01"] = "Settings"
	PropertiesToShow["opacity:minvalue:0.0:maxvalue:1.0:step:0.01"] = "Settings"
	PropertiesToShow["pen_pressure_usage,size,opacity,tint"] = "Settings"
	if brush_type == BRUSH_DRAW or brush_type == BRUSH_ERASE or brush_type == BRUSH_PENCIL:
		PropertiesToShow["drawing_color1"] = "Color"
		PropertiesToShow["drawing_color2"] = "Color"
		PropertiesToShow["switch_color_function"] = "Color"
	if brush_type == BRUSH_PENCIL:
		PropertiesToShow["ruler_mode"] = "Pencil"
		PropertiesToShow["jaggies_removal"] = "Pencil"

	PropertiesView.append(PropertiesGroups)
	PropertiesView.append(PropertiesToShow)
	return PropertiesView
func update_tool_ui():
	changed.emit()
func switch_color():
	var color1 : Color = drawing_color1
	drawing_color1 = drawing_color2
	drawing_color2 = color1
	changed.emit()

func shortcut_pressed():
	if Input.is_action_just_pressed("brush") and not Input.is_key_pressed(KEY_SHIFT) and not Input.is_key_pressed(KEY_CTRL) and not Input.is_key_pressed(KEY_ALT):
		ToolsManager.shortcut_tool = self
		if !tool_active:
			enable_tool()
			return
		if tool_active:
			confirm_tool()
			return
	if Input.is_action_just_pressed("mouse_left"):
		if !tool_active and ToolsManager.current_tool == self:
			enable_tool()
			return
		if tool_active:
			confirm_tool()
			return
	if Input.is_action_just_pressed("cancel"):
		cancel_tool()

func mouse_pressed(
	event : InputEventMouseButton,
	_image : base_layer,
):
	if event.button_index == MOUSE_BUTTON_RIGHT and tool_active:
		cancel_tool()
	if event.button_index == MOUSE_BUTTON_LEFT and tool_active and !event.pressed:
		confirm_tool()



func enable_tool(): # Save History and Enable Tool
	edited_object = ToolsManager.get_paint_layer()
	start_drawing(ToolsManager.current_mouse_position)
	
#	ToolsManager.current_project.undo_redo.create_action("Move Layers")
#	for selected in ToolsManager.current_project.layers_container.selected_layers:
#		ToolsManager.current_project.undo_redo.add_undo_property(selected,"position",selected.position)
	super.enable_tool()
func cancel_tool(): # Redo Actions
#	if ToolsManager.current_project.layers_container.selected_layers:
#		for selected in ToolsManager.current_project.layers_container.selected_layers:
#			ToolsManager.current_project.undo_redo.add_do_property(selected, "position", selected.position)
#		ToolsManager.current_project.undo_redo.commit_action()
#		for selected in ToolsManager.current_project.layers_container.selected_layers:
#			ToolsManager.current_project.undo_redo.undo()
	super.cancel_tool()
func confirm_tool(): # Confirm Actions
	if brush_type != BRUSH_ERASE:
		edited_object.strokes.append(current_stroke)
		edited_object.main_object.queue_redraw()
	super.confirm_tool()

func start_drawing(_start_pos):
	# Break the image up into tiles - small images are faster to edit.
	last_stroke_pos = _start_pos
	
	current_stroke = Stroke.new()
	if brush_type == BRUSH_PENCIL:
		current_stroke.type = Stroke.TYPE.LINE
	else:
		current_stroke.type = Stroke.TYPE.CIRCLE

#var cached_to_draw_mouse_moves : PackedVector2Array
func mouse_moved(event : InputEventMouseMotion):
	if !tool_active:
		return
	if !edited_object:
		return
	var pt_count = max(abs(event.relative.x), abs(event.relative.y))
	var lerp_step = 1 / pt_count
	#if stroke_end.distance_to(last_stroke_pos) < (brushsize * 0.5) and (ToolsManager.effect_scaling_factor == 0.25 or brushsize > 200.0):
		#return
	for i in pt_count:
		var point : Vector2 = ToolsManager.current_mouse_position + Vector2.ONE - event.relative * i * lerp_step - Vector2.ONE
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT != 0.0:
			stroke(point, event.pressure)
		else:
			stroke(point, 1.0)


var current_stroke : Stroke
var last_stroke_pos : Vector2
func stroke(point:Vector2, pressure):

	var unsolid_radius : float = (brushsize * 0.5) * (1.0 - hardness)
	var radius : float = (brushsize * 0.5) * (pressure if pen_pressure_usage == pen_flag.size else 1.0)
	var _solid_radius : float = radius - unsolid_radius
	
	var color : Color
	if brush_type == BRUSH_ERASE:
		color = Color(1,0,0,0.05)

	elif pen_pressure_usage == pen_flag.tint:
		color = lerp(drawing_color2, drawing_color1, pressure)
	else:
		color = drawing_color1

	color.a *= opacity
	if pen_pressure_usage == pen_flag.opacity:
		color.a *= pressure

	#point = point.floor() #+ Vector2(0.5, 0.5)
	if brush_type != BRUSH_ERASE:
		match current_stroke.type:
			Stroke.TYPE.CIRCLE:
				current_stroke.add_point(point, color, radius)
			Stroke.TYPE.LINE:
				current_stroke.add_point(point, color, radius)
				current_stroke.aliasing = jaggies_removal
	else:
		for stroke in edited_object.strokes:
			var points_to_remove: PackedInt32Array = []
			for i in stroke.points.size():
				if stroke.points[i].distance_squared_to(point) < pow(radius,2):
					var point_color : Color = stroke.color[i]
					point_color.a = clampf(point_color.a - opacity, 0.0, 1.0)
					if point_color.a == 0:
						points_to_remove.append(i)
					else:
						stroke.color[i] = point_color
			for i in points_to_remove:
				stroke.remove_point(i)
				edited_object.main_object.queue_redraw()


func draw_preview(image_view : CanvasItem, mouse_position : Vector2i):
	if edited_object and tool_active:
		current_stroke.draw(image_view)

	if brush_type == BRUSH_PENCIL:
		if !ruler_mode:
			draw_crosshair(image_view, mouse_position, crosshair_size, crosshair_color)
		else:
			draw_crosshair(image_view, mouse_position, crosshair_size_ruler, crosshair_color)
			var diag_distance := 8
			var posf := Vector2(mouse_position) + Vector2(0.5, 0.5)
			image_view.draw_line(posf + Vector2(-1, +1) * diag_distance, posf + Vector2(-1, +1) * (diag_distance + crosshair_size_ruler), crosshair_color, 1)
			image_view.draw_line(posf + Vector2(+1, -1) * diag_distance, posf + Vector2(+1, -1) * (diag_distance + crosshair_size_ruler), crosshair_color, 1)
			image_view.draw_line(posf + Vector2(+1, +1) * diag_distance, posf + Vector2(+1, +1) * (diag_distance + crosshair_size_ruler), crosshair_color, 1)
			image_view.draw_line(posf + Vector2(-1, -1) * diag_distance, posf + Vector2(-1, -1) * (diag_distance + crosshair_size_ruler), crosshair_color, 1)
	else:
		var circle_center = Vector2(mouse_position + Vector2i.ONE) - brush_offset
		image_view.draw_arc(circle_center, brushsize * 0.5 + 0.5, PI * 0.1, PI * 0.9, 32, crosshair_color, 1.0)
		image_view.draw_arc(circle_center, brushsize * 0.5 + 0.5, PI * 1.1, PI * 1.9, 32, crosshair_color, 1.0)
		if ToolsManager.effect_scaling_factor == 0.25:
			image_view.draw_line(last_stroke_pos, mouse_position, Color.RED)
	# With region set to (0, 0, 0, 0), hides the image.
	# image_view.region_enabled = drawing
