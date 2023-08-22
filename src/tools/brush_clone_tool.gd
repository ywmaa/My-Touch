extends "res://src/tools/brush_tool.gd"

@export var clone_preview_color := Color(1.0, 1.0, 1.0, 0.75)

var replace_alpha := false

var clone_offset := Vector2.ZERO
var clone_offset_editing := false
var copy_from_whole_canvas: bool = true
var image_to_copy : Image
func _init():
	tool_name = "Clone Tool"
	tool_button_shortcut = ""
	tool_desc = ""
	tool_icon = get_icon_from_project_folder("colorselect")
	brush_type = BRUSH_CLONE

func shortcut_pressed():
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
	image : base_layer,
):
	if event.button_index == MOUSE_BUTTON_RIGHT:
		clone_offset_editing = event.pressed
		clone_offset = clone_offset.floor()
	else:
		super.mouse_pressed(event, image)

func enable_tool():
	if copy_from_whole_canvas:
		image_to_copy = mt_globals.main_window.get_node("AppRender").get_texture().get_image()
	super.enable_tool()
	if !copy_from_whole_canvas:
		image_to_copy = EditedImage
	

func mouse_moved(event : InputEventMouseMotion):
	if clone_offset_editing:
		clone_offset -= event.relative

	super.mouse_moved(event)


func get_new_pixel(on_image, _color:Color, stroke_end:Vector2, cur_pos, radius:float, solid_radius:float):
	var old_color = on_image.get_pixelv(cur_pos)
	
	var cloned_color = image_to_copy.get_pixelv(
		(Vector2(last_edits_chunks.find_key(on_image)) + cur_pos + clone_offset)
		)
	var distance = Vector2(stroke_end).distance_to(cur_pos)

	if distance <= solid_radius:
		var blended = old_color.blend(cloned_color)
		blended.a = max(old_color.a, cloned_color.a)
		return blended

	elif distance <= radius:
		var blended = old_color.blend(cloned_color)
		distance = (distance - solid_radius) / (radius - solid_radius)
#		blended.a = max(old_color.a, cloned_color.a * (1.0 - distance * distance))
		blended.a = lerp(old_color.a, cloned_color.a, (1.0 - distance * distance))
		return blended

	else:
		return old_color


func draw_preview(image_view : CanvasItem, mouse_position : Vector2i):
	super.draw_preview(image_view, mouse_position)

	if clone_offset == Vector2.ZERO:
		image_view.draw_string(
			preload("res://UI/theme/font.tres"),
			mouse_position,
			"Hold Right Mouse and drag to change offset.",
			HORIZONTAL_ALIGNMENT_CENTER
		)

	var circle_center = Vector2(mouse_position + Vector2i.ONE + Vector2i(clone_offset)) - brush_offset
	image_view.draw_arc(circle_center, brushsize * 0.5 + 0.5, PI * 0.6, PI * 1.4, 32, clone_preview_color, 1.0)
	image_view.draw_arc(circle_center, brushsize * 0.5 + 0.5, PI * 1.6, PI * 2.4, 32, clone_preview_color, 1.0)
