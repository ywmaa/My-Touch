extends ToolBase

enum {
  BRUSH_DRAW,
  BRUSH_ERASE,
  BRUSH_CLONE,
  BRUSH_SHADING,
  BRUSH_NORMALMAP,
}

@export_enum("Draw", "Erase", "Clone", "Shading", "Normal Map") var brush_type := 0
@export var chunk_size := Vector2i(256, 256)
@export var crosshair_color := Color(1.0, 1.0, 1.0, 1.0)

var brushsize := 50.0:
	set(x):
		brushsize = x
		brush_offset = Vector2(0.5, 0.5) * float(int(x) % 2)

var brush_offset := Vector2(0.5, 0.5)
var hardness := 1.0
var hardness_property : float = 0.0:
	set(x):
		hardness = clampf(x/100.0,0.0,1.0)
	get:
		return hardness * 100.0
var opacity : float = 1.0
enum pen_flag{size,opacity,tint}
var pen_pressure_usage : pen_flag = pen_flag.size

#var drawing := false
var drawing_color1 := Color()
var drawing_color2 := Color()
var last_edits_chunks := {}
var last_edits_textures := {}
var last_affected_rect := Rect2i()

var edited_object
var EditedImage : Image

func _init():
	tool_name = "Brush Tool"
	tool_button_shortcut = "Shift+B"
	tool_desc = ""
	tool_icon = get_icon_from_project_folder("shading")
func get_tool_inspector_properties():
	var PropertiesView : Array = []
	var PropertiesGroups : Array[String] = []
	PropertiesGroups.append("Settings")
	PropertiesGroups.append("Color")
	var PropertiesToShow : Dictionary = {}
	PropertiesToShow["brushsize:minvalue:1.0:maxvalue:1024.0:step:1.0"] = "Settings"
	PropertiesToShow["hardness:minvalue:0.0:maxvalue:1.0:step:0.01"] = "Settings"
	PropertiesToShow["opacity:minvalue:0.0:maxvalue:1.0:step:0.01"] = "Settings"
	PropertiesToShow["pen_pressure_usage,size,opacity,tint"] = "Settings"
	PropertiesToShow["drawing_color1"] = "Color"
	PropertiesToShow["drawing_color2"] = "Color"
	PropertiesView.append(PropertiesGroups)
	PropertiesView.append(PropertiesToShow)
	return PropertiesView



func shortcut_pressed():
	if Input.is_action_just_pressed("brush"):
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
		if tool_active and ToolsManager.shortcut_tool == self:
			confirm_tool()
			return
	if Input.is_action_just_pressed("cancel"):
		cancel_tool()

func mouse_pressed(
	event : InputEventMouseButton,
	image : base_layer,
):
	if image.type != base_layer.layer_type.brush:
		print("please select a brush layer")
		return
	if event.button_index == MOUSE_BUTTON_RIGHT and tool_active:
		cancel_tool()
	if event.button_index == MOUSE_BUTTON_LEFT and tool_active and !event.pressed:
		confirm_tool()



func enable_tool(): # Save History and Enable Tool
	if ToolsManager.current_project.layers.selected_layers.is_empty():
		edited_object = null
		return
	if ToolsManager.current_project.layers.selected_layers[0].type != base_layer.layer_type.brush:
		print("please select a brush layer")
		return
	edited_object = ToolsManager.current_project.layers.selected_layers[0]
	EditedImage = edited_object.main_object.texture.get_image()
	start_drawing(EditedImage, ToolsManager.current_mouse_position)
#	ToolsManager.current_project.undo_redo.create_action("Move Layers")
#	for selected in ToolsManager.current_project.layers.selected_layers:
#		ToolsManager.current_project.undo_redo.add_undo_property(selected,"position",selected.position)
	super.enable_tool()
func cancel_tool(): # Redo Actions
#	if ToolsManager.current_project.layers.selected_layers:
#		for selected in ToolsManager.current_project.layers.selected_layers:
#			ToolsManager.current_project.undo_redo.add_do_property(selected, "position", selected.position)
#		ToolsManager.current_project.undo_redo.commit_action()
#		for selected in ToolsManager.current_project.layers.selected_layers:
#			ToolsManager.current_project.undo_redo.undo()
	super.cancel_tool()
func confirm_tool(): # Confirm Actions
	match brush_type:
		BRUSH_ERASE:
			apply_eraser(EditedImage)
		_:
			apply_brush(EditedImage)

	if edited_object:
		edited_object.main_object.texture.update(EditedImage) #= ImageTexture.create_from_image(EditedImage)
		edited_object.save_paint_image()
#	if EditedImage:
#		EditedImage.save_png(ToolsManager.current_project.layers.selected_layers[0].image_path)
#	ToolsManager.current_project.layers.selected_layers[0].texture = ImageTexture.create_from_image(EditedImage)
#	ToolsManager.current_project.layers.selected_layers[0].image.texture = ToolsManager.current_project.layers.selected_layers[0].texture
#	if ToolsManager.current_project.layers.selected_layers:
#		for selected in ToolsManager.current_project.layers.selected_layers:
#			ToolsManager.current_project.undo_redo.add_do_property(selected, "position", selected.position)
#		ToolsManager.current_project.undo_redo.commit_action()
	super.confirm_tool()

func start_drawing(image, start_pos):
	# Break the image up into tiles - small images are faster to edit.
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

	last_affected_rect = Rect2i(start_pos, Vector2i.ZERO)


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
#	var new_image = Image.create(last_affected_rect.size.x + 1, last_affected_rect.size.y + 1, false, image.get_format())
#	new_image.blit_rect(new_image, last_affected_rect, Vector2i.ZERO)
	var pos
	for k in last_edits_chunks:
		var chunk = last_edits_chunks[k]
		var height = mini(image.get_height() - k.y, chunk.get_height())
		for i in mini(image.get_width() - k.x, chunk.get_width()):
			for j in height:
#				pos = k - last_affected_rect.position + Vector2i(i, j)
				pos = Vector2i(i + k.x, j + k.y)
				chunk.set_pixel(
					i, j,
					image.get_pixelv(pos) - chunk.get_pixel(i, j)
				)
		image.blit_rect(last_edits_chunks[k], Rect2i(Vector2i.ZERO, chunk_size), k)


func get_affected_rect():
	return last_affected_rect.grow_individual(0, 0, 1, 1)


func mouse_moved(event : InputEventMouseMotion):
	if !tool_active:
		return
	if !edited_object:
		return
	if ToolsManager.mouse_position_delta.length() > 0.0:
		var object_correction = edited_object.main_object.position-edited_object.size/2
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT != 0.0:
			stroke(ToolsManager.previous_mouse_position-object_correction, ToolsManager.current_mouse_position-object_correction, event.pressure)

		else:
			stroke(ToolsManager.previous_mouse_position-object_correction, ToolsManager.current_mouse_position-object_correction, 1.0)


func stroke(stroke_start, stroke_end, pressure):
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

			paint(
				last_edits_chunks[key],
				stroke_end - keyf,
				stroke_start - keyf,
				key,
				pressure
			)


func paint(on_image, stroke_start, stroke_end, chunk_position, pressure):
	var unsolid_radius = (brushsize * 0.5) * (1.0 - hardness)
	var radius = (brushsize * 0.5) * (pressure if pen_pressure_usage == pen_flag.size else 1.0)
	var solid_radius = radius - unsolid_radius

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

	var new_rect = Rect2i(stroke_start, Vector2i.ZERO)\
		.expand(stroke_end)\
		.grow(radius + 2)\
		.intersection(Rect2i(Vector2i.ZERO, on_image.get_size()))

	if new_rect.size == Vector2i.ZERO:
		return
	
	last_affected_rect = last_affected_rect\
		.expand(Vector2i(new_rect.position) + chunk_position)\
		.expand(Vector2i(new_rect.end) + chunk_position)

	stroke_start = stroke_start.floor() + Vector2(0.5, 0.5)
	stroke_end = stroke_end.floor() + Vector2(0.5, 0.5)
	var cur_pos

	for i in new_rect.size.x:
		for j in new_rect.size.y:
			cur_pos = new_rect.position + Vector2i(i, j)
#			if is_out_of_bounds(cur_pos + chunk_position, selection.get_size()):
#				continue
#
#			if !selection.get_bitv(cur_pos + chunk_position):
#				continue

			on_image.set_pixelv(cur_pos, get_new_pixel(
				on_image, color,
				stroke_start, stroke_end, Vector2(cur_pos) + brush_offset,
				radius, solid_radius
			))


func get_new_pixel(on_image, color, _stroke_start, stroke_end, cur_pos, radius, solid_radius):
	var old_color = on_image.get_pixelv(cur_pos)
	var distance = Vector2(stroke_end).distance_to(cur_pos)
	if distance <= solid_radius:
		var blended = old_color.blend(color)
		blended.a = max(old_color.a, color.a)
		return blended

	elif distance <= radius:
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
			last_edits_textures[k].update(last_edits_chunks[k])
			image_view.draw_texture(last_edits_textures[k], (edited_object.position-edited_object.size/2)+Vector2(k))

	var circle_center = Vector2(mouse_position + Vector2i.ONE) - brush_offset
	image_view.draw_arc(circle_center, brushsize * 0.5 + 0.5, PI * 0.1, PI * 0.9, 32, crosshair_color, 1.0)
	image_view.draw_arc(circle_center, brushsize * 0.5 + 0.5, PI * 1.1, PI * 1.9, 32, crosshair_color, 1.0)
	# With region set to (0, 0, 0, 0), hides the image.
	# image_view.region_enabled = drawing