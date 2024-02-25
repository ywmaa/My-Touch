extends ToolBase

enum {
  BRUSH_DRAW,
  BRUSH_ERASE,
  BRUSH_CLONE,
  BRUSH_SHADING,
  BRUSH_NORMALMAP,
}

@export_enum("Draw", "Erase", "Clone", "Normal Map") var brush_type := 0
@export var chunk_count : int = 1
@export var crosshair_color := Color(1.0, 1.0, 1.0, 1.0)

var chunk_size := Vector2i(960, 540)
var brushsize := 50.0:
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
var last_edits_chunks := {}
var last_edits_textures := {}

var edited_object
var EditedImage : Image

func _init():
	tool_name = "Brush Tool"
	tool_button_shortcut = "Shift+B"
	tool_desc = ""
	tool_icon = get_icon_from_project_folder("brush")
func get_tool_inspector_properties():
	var PropertiesView : Array = []
	var PropertiesGroups : Array[String] = []
	PropertiesGroups.append("Settings")
	if brush_type == 0 or brush_type == 1:
		PropertiesGroups.append("Color")
	var PropertiesToShow : Dictionary = {}
	if brush_type == 0 or brush_type == 1:
		PropertiesToShow["brush_type,Draw,Erase"] = "Settings"
	if brush_type == 2:
		PropertiesToShow["copy_from_whole_canvas"] = "Settings"
	PropertiesToShow["brushsize:minvalue:1.0:maxvalue:1024.0:step:1.0"] = "Settings"
	PropertiesToShow["hardness:minvalue:0.0:maxvalue:1.0:step:0.01"] = "Settings"
	PropertiesToShow["opacity:minvalue:0.0:maxvalue:1.0:step:0.01"] = "Settings"
	PropertiesToShow["pen_pressure_usage,size,opacity,tint"] = "Settings"
	if brush_type == 0 or brush_type == 1:
		PropertiesToShow["drawing_color1"] = "Color"
		PropertiesToShow["drawing_color2"] = "Color"
		PropertiesToShow["switch_color_function"] = "Color"
	PropertiesView.append(PropertiesGroups)
	PropertiesView.append(PropertiesToShow)
	return PropertiesView

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
	EditedImage = edited_object.image.texture.get_image()
	start_drawing(EditedImage, ToolsManager.current_mouse_position)
	
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

	
	if brush_type == BRUSH_ERASE:
		var worker = TaskManager.create_task(apply_eraser.bind(EditedImage))
		paint_threads.append(worker)
	TaskManager.create_task(apply_texture)
#	if EditedImage:
#		EditedImage.save_png(ToolsManager.current_project.layers_container.selected_layers[0].image_path)
#	ToolsManager.current_project.layers_container.selected_layers[0].texture = ImageTexture.create_from_image(EditedImage)
#	ToolsManager.current_project.layers_container.selected_layers[0].image.texture = ToolsManager.current_project.layers_container.selected_layers[0].texture
#	if ToolsManager.current_project.layers_container.selected_layers:
#		for selected in ToolsManager.current_project.layers_container.selected_layers:
#			ToolsManager.current_project.undo_redo.add_do_property(selected, "position", selected.position)
#		ToolsManager.current_project.undo_redo.commit_action()
	super.confirm_tool()
func apply_texture():
	for thread in paint_threads:
		thread.wait()
	paint_threads.clear()
	if brush_type != BRUSH_ERASE:
		apply_brush(EditedImage)
	if edited_object:
		edited_object.image.texture.update(EditedImage) #= ImageTexture.create_from_image(EditedImage)
		edited_object.save_paint_image()
func start_drawing(image, _start_pos):
	# Break the image up into tiles - small images are faster to edit.
	last_stroke_pos = _start_pos
	chunk_size = image.get_size()/chunk_count
	for i in ceil(float(image.get_width()) / chunk_size.x):
		for j in ceil(float(image.get_height()) / chunk_size.y):
			last_edits_chunks[Vector2i(i, j) * chunk_size] = Image.create(
				chunk_size.x, chunk_size.y,
				false, image.get_format()
			)
	for k in last_edits_chunks:
		last_edits_textures[k] = ImageTexture.create_from_image(last_edits_chunks[k])
		# Copy the image to the tiles. Worse opacity handling,
		# but with more work can make eraser editing more performant and previewable.
		# last_edits_chunks[k].blit_rect(image, Rect2i(k, chunk_size), Vector2i.ZERO)


func apply_brush(image):
	for k in last_edits_chunks:
		image.blend_rect(
			last_edits_chunks[k],
			Rect2i(Vector2i.ZERO, chunk_size),
			k
		)


func apply_eraser(image):
	# Cutting off a smaller image does not increase performance.
	# Must find another way - erasing is very slow.
	paint_mutex.lock()
	var pos
	for k in last_edits_chunks:
		var chunk = last_edits_chunks[k]
		var height = mini(image.get_height() - k.y, chunk.get_height())
		for i in mini(image.get_width() - k.x, chunk.get_width()):
			for j in height:
				pos = Vector2i(i + k.x, j + k.y)
				chunk.set_pixel(
					i, j,
					image.get_pixelv(pos) - chunk.get_pixel(i, j)
				)
		image.blit_rect(last_edits_chunks[k], Rect2i(Vector2i.ZERO, chunk_size), k)
	paint_mutex.unlock()

#var cached_to_draw_mouse_moves : PackedVector2Array
func mouse_moved(event : InputEventMouseMotion):
	if !tool_active:
		return
	if !edited_object:
		return
	if ToolsManager.mouse_position_delta.length() > 0.0:
		var object_correction = edited_object.image.position-edited_object.size/2
		var stroke_end :Vector2 = ToolsManager.current_mouse_position-object_correction
		if last_stroke_pos == null:
			last_stroke_pos = stroke_end
#		cached_to_draw_mouse_moves.append(stroke_end)
		if stroke_end.distance_to(last_stroke_pos) < (brushsize * 0.5) and (ToolsManager.effect_scaling_factor == 0.25 or brushsize > 200.0):
			return
#		for v in cached_to_draw_mouse_moves:
		var draw_pos = last_stroke_pos.lerp(stroke_end,0.1) if ToolsManager.effect_scaling_factor == 0.25 and brushsize < 200.0 else stroke_end
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT != 0.0:
			stroke(last_stroke_pos, draw_pos, event.pressure)
		else:
			stroke(last_stroke_pos, draw_pos, 1.0)
		last_stroke_pos = draw_pos
#		cached_to_draw_mouse_moves.clear()

var cached_pixels : PackedVector2Array = []
var solid_color_rect : Rect2i 
var paint_mutex : Mutex = Mutex.new()
var last_stroke_pos : Vector2
var paint_threads : Array = []
func stroke(stroke_start:Vector2, stroke_end:Vector2, pressure):

	var unsolid_radius : float = (brushsize * 0.5) * (1.0 - hardness)
	var radius : float = (brushsize * 0.5) * (pressure if pen_pressure_usage == pen_flag.size else 1.0)
	var solid_radius : float = radius - unsolid_radius
	
	#Chunks
	var rect = Rect2i(stroke_start, Vector2.ZERO)\
		.expand(stroke_end)\
		.grow(brushsize * 0.5 + 1)
	
	rect = Rect2i(rect.position / chunk_size, rect.end / chunk_size)
	var key
	var keyf
	for i in rect.size.x + 1:
		for j in rect.size.y + 1:
			key = (rect.position + Vector2i(i, j)) * chunk_size
			keyf = Vector2(key)
			if !last_edits_chunks.has(key): continue
			TaskManager.create_task(
				paint.bind(
					last_edits_chunks[key],
					stroke_end - keyf,
					pressure,
					radius,
					solid_radius
				)
				,true
				,"Paint Process"
			)



func paint(on_image, stroke_end:Vector2, pressure:float , radius:float, solid_radius:float):
	paint_mutex.lock()
	
	get_all_brush_pixels(radius, solid_radius)
	
	
	var color : Color
	if brush_type == BRUSH_ERASE:
		color = Color.BLACK

	elif pen_pressure_usage == pen_flag.tint:
		color = lerp(drawing_color2, drawing_color1, pressure)

	else:
		color = drawing_color1

	color.a *= opacity
	if pen_pressure_usage == pen_flag.opacity:
		color.a *= pressure

	stroke_end = stroke_end.floor() #+ Vector2(0.5, 0.5)

#	var begin = Time.get_ticks_msec()
	var edited_image_size : Vector2i = EditedImage.get_size()
	if brush_type == BRUSH_DRAW or brush_type == BRUSH_ERASE:
		on_image.fill_rect(Rect2i(solid_color_rect.position-Vector2i(2,2)+Vector2i(stroke_end),solid_color_rect.size+Vector2i(4,4)), color)
	
	var worker = TaskManager.create_group_task(set_pixels.bind(on_image, color, stroke_end, radius, solid_radius, edited_image_size),cached_pixels.size(),-1 ,true)
	worker.wait()
#	for pixel in cached_pixels:
#		var cur_pos = stroke_end+pixel
#		if cur_pos.x < 0 or cur_pos.y < 0:
#			return
#		if cur_pos.x >= chunk_size.x or cur_pos.y >= chunk_size.y or cur_pos.x >= edited_image_size.x or cur_pos.y >= edited_image_size.y:
#			return
#
#		on_image.set_pixelv(cur_pos, get_new_pixel(
#			on_image, color,
#			stroke_end, cur_pos,
#			radius, solid_radius
#		))
	

	for k in last_edits_chunks:
		last_edits_textures[k].update(last_edits_chunks[k])
	
	paint_mutex.unlock()

#	print("OP Took ", Time.get_ticks_msec()-begin, "ms")
func set_pixels(index:int, on_image, color: Color, stroke_end:Vector2, radius:float, solid_radius:float, edited_image_size:Vector2i):
	var cur_pos = stroke_end+cached_pixels[index]
	if cur_pos.x < 0 or cur_pos.y < 0:
		return
	if cur_pos.x >= chunk_size.x or cur_pos.y >= chunk_size.y or cur_pos.x >= edited_image_size.x or cur_pos.y >= edited_image_size.y:
		return
	on_image.set_pixelv(cur_pos, get_new_pixel(
		on_image, color,
		stroke_end, cur_pos,
		radius, solid_radius
	))
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
	



func get_new_pixel(on_image, color:Color, stroke_end:Vector2, cur_pos, radius:float, solid_radius:float):
	var distance = stroke_end.distance_to(cur_pos)
	
	if distance <= solid_radius:
#		var blended = old_color.blend(color)
#		blended.a = max(old_color.a, color.a)
		return color
	var old_color = on_image.get_pixelv(cur_pos)
	if distance <= radius:
		var blended = old_color.blend(color)
		distance = (distance - solid_radius) / (radius - solid_radius)
#		Possible better handling of variable pressure,
#		but creates artifacts when zig-zagging
		blended.a = max(old_color.a, color.a * (1.0 - distance * distance))
#		This one also creates artifacts, but this is during normal brush usage.
#		blended.a = lerp(old_color.a, color.a, (1.0 - distance * distance))
		return blended
	else:
		return old_color


func draw_preview(image_view : CanvasItem, mouse_position : Vector2i):
	if edited_object and tool_active:
		for k in last_edits_chunks:
			image_view.draw_texture(last_edits_textures[k], (edited_object.position-edited_object.size/2)+Vector2(k))

	var circle_center = Vector2(mouse_position + Vector2i.ONE) - brush_offset
	image_view.draw_arc(circle_center, brushsize * 0.5 + 0.5, PI * 0.1, PI * 0.9, 32, crosshair_color, 1.0)
	image_view.draw_arc(circle_center, brushsize * 0.5 + 0.5, PI * 1.1, PI * 1.9, 32, crosshair_color, 1.0)
	
	if ToolsManager.effect_scaling_factor == 0.25:
		image_view.draw_line(last_stroke_pos, mouse_position, Color.RED)
	# With region set to (0, 0, 0, 0), hides the image.
	# image_view.region_enabled = drawing
