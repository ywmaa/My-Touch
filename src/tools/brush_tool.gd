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
func get_inspector_properties():
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
	edited_object = ToolsManager.get_paint_layer() as paint_layer
	start_drawing(ToolsManager.current_mouse_position)
	super.enable_tool()
func cancel_tool(): # Redo Actions
	super.cancel_tool()
func confirm_tool(): # Confirm Actions
	super.confirm_tool()


func start_drawing(_start_pos):
	last_stroke_pos = _start_pos
	
	current_stroke = Stroke.new()
	#last_drawn_index = 0
	var undo_redo : UndoRedo = ToolsManager.current_project.undo_redo
	undo_redo.create_action("Brush Stroke")
	
	undo_redo.add_undo_property(edited_object, "strokes", edited_object.strokes.duplicate())
	edited_object.strokes.append(current_stroke)
	undo_redo.add_do_property(edited_object, "strokes", edited_object.strokes.duplicate())
	
	undo_redo.add_do_method(edited_object.main_object.add_child.bind(current_stroke.stroke_node))
	undo_redo.add_do_reference(current_stroke.stroke_node)
	undo_redo.add_do_method(edited_object.main_object.queue_redraw)
	
	undo_redo.add_undo_method(edited_object.main_object.remove_child.bind(current_stroke.stroke_node))
	undo_redo.add_undo_method(edited_object.main_object.queue_redraw)
	
	undo_redo.commit_action(false)
	current_stroke.need_redraw = true
	edited_object.main_object.queue_redraw()

	if brush_type == BRUSH_ERASE:
		current_stroke.mode = Stroke.MODE.ERASE
	else:
		current_stroke.mode = Stroke.MODE.DRAW

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
	#if ToolsManager.mouse_position_delta.length() > 0.0:
	var pt_count = max(abs(event.relative.x), abs(event.relative.y))
	var lerp_step = 0.01 / pt_count
	for i in pt_count:
		var point : Vector2 = ToolsManager.current_mouse_position - event.relative * lerp_step * i
		var draw_pos = last_stroke_pos.lerp(point,0.05) if ToolsManager.effect_scaling_factor == 0.25 else point
		if draw_pos.distance_to(last_stroke_pos) < (brushsize * 0.5): # So we don't draw on the same place
			return
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT != 0.0:
			stroke(draw_pos, event.pressure)
		else:
			stroke(draw_pos, 1.0)
		last_stroke_pos = draw_pos

var current_stroke : Stroke
var last_stroke_pos : Vector2
var cached_pixels : PackedVector2Array = []
var solid_color_rect : Rect2i
var points_to_remove: PackedInt32Array = []
func stroke(point:Vector2, pressure):
	var unsolid_radius : float = (brushsize * 0.5) * (1.0 - hardness)
	var radius : float = (brushsize * 0.5) * (pressure if pen_pressure_usage == pen_flag.size else 1.0)
	var solid_radius : float = radius - unsolid_radius
	var color : Color
	#if brush_type == BRUSH_ERASE:
		#color = Color(1,0,0,0.05)

	#elif pen_pressure_usage == pen_flag.tint:
		#color = lerp(drawing_color2, drawing_color1, pressure)
	#else:
	color = drawing_color1

	color.a *= opacity
	if pen_pressure_usage == pen_flag.opacity:
		color.a *= pressure

	#point = point.floor() #+ Vector2(0.5, 0.5)
	match current_stroke.type:
		Stroke.TYPE.CIRCLE:
			current_stroke.add_point(point, color, radius)
		Stroke.TYPE.LINE:
			current_stroke.add_point(point, color, radius)
			current_stroke.aliasing = jaggies_removal


func get_all_brush_pixels(radius, solid_radius):
		cached_pixels.clear()
		
		
		# for performance, we create a rect2i containing all pixels
		# that will not blend with the background and have same color
		# so we use Image.fill_rect() to improve performance
		
		# Let's assume a Square Side is called A
		# then its value would be like this : A^2 + A^2 = D^2
		# where D is the diagonal, and our diagonal in this case is actually the circle radius
		var square_side = sqrt(pow(solid_radius,2)/2)-2
		solid_color_rect = Rect2i(0-square_side, 0-square_side, square_side*2,square_side*2)
		
		#use Bresenham's algorithm
		var r : int = radius
		var current_point : Vector2i = Vector2i(0,r)
		var d : int = 3 - 2 * r
		if brush_type == BRUSH_DRAW or brush_type == BRUSH_ERASE:
			var first_y_count : int = current_point.y-square_side
			for y in first_y_count:
				if square_side+y < current_point.x: # Ensure that pixel is not repeated
					continue
				cached_pixels.append_array(GetCircleSymmetry(current_point.x,2+square_side+y))
		else:
			var first_y_count : int = current_point.y
			for y in first_y_count:
				if y < current_point.x: # Ensure that pixel is not repeated
					continue
				cached_pixels.append_array(GetCircleSymmetry(current_point.x,y))
		while current_point.y >= current_point.x:
			current_point.x += 1

			if (d > 0):
				current_point.y -= 1
				d = d + 4 * (current_point.x-current_point.y) + 10
			else:
				d = d + 4 * current_point.x + 6
			
			#Fill the circle
			if brush_type == BRUSH_DRAW or brush_type == BRUSH_ERASE: # We Will Only Use the Rect Performance Enhacement with Draw/Erase
				var y_count : int = current_point.y-square_side
				for y in y_count:
					if square_side+y < current_point.x: # Ensure that pixel is not repeated by excluding a coordinate almost less than 45 degrees from the X Axis
						continue
					cached_pixels.append_array(GetCircleSymmetry(current_point.x,2+square_side+y))
			else:
				var y_count : int = current_point.y
				for y in y_count:
					if y < current_point.x: # Ensure that pixel is not repeated
						continue
					cached_pixels.append_array(GetCircleSymmetry(current_point.x,y))


func GetCircleSymmetry(x:int, y:int, x_center:int = 0, y_center:int = 0):
	var pixels : PackedVector2Array = []
	if x == 0:
		pixels.append(Vector2i(x_center, y_center+y))
		pixels.append(Vector2i(x_center, y_center-y))
		pixels.append(Vector2i(x_center+y, y_center))
		pixels.append(Vector2i(x_center-y, y_center))
		return pixels
	elif y == 0:
		pixels.append(Vector2i(x_center, y_center+x))
		pixels.append(Vector2i(x_center, y_center-x))
		pixels.append(Vector2i(x_center+x, y_center))
		pixels.append(Vector2i(x_center-x, y_center))
		return pixels
	elif y == x:
		pixels.append(Vector2i(x_center+x, y_center+y))
		pixels.append(Vector2i(x_center+x, y_center-y))
		pixels.append(Vector2i(x_center-x, y_center+y))
		pixels.append(Vector2i(x_center-x, y_center-y))
		return pixels
	else:
		pixels.append(Vector2i(x_center+x, y_center+y))
		pixels.append(Vector2i(x_center-x, y_center+y))
		pixels.append(Vector2i(x_center+x, y_center-y))
		pixels.append(Vector2i(x_center-x, y_center-y))
		pixels.append(Vector2i(x_center+y, y_center+x))
		pixels.append(Vector2i(x_center-y, y_center+x))
		pixels.append(Vector2i(x_center+y, y_center-x))
		pixels.append(Vector2i(x_center-y, y_center-x))
		return pixels


func draw_preview(image_view : CanvasItem, mouse_position : Vector2i):

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
