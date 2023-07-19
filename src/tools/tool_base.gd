extends Resource
class_name ToolBase

@export var tool_name := "Box Selection"
@export var tool_button_shortcut := "Shift+B"
@export_multiline var tool_desc := ""
var tool_active : bool
@export var tool_icon : Texture2D
var selection : BitMap
@export var preview_shader : ShaderMaterial
@export_enum("None", "When Drawing", "When Active") var image_hide_mode := 0

func get_icon_from_project_folder(icon_name:String) -> ImageTexture:
	return load("res://UI/graphics/tools/%s.png" % icon_name.to_lower())

func is_out_of_bounds(pos : Vector2i, rect_size : Vector2i):
	return (
		pos.x < 0 || pos.y < 0
		|| pos.x >= rect_size.x || pos.y >= rect_size.y
	)

func is_selection_empty():
	return selection.get_true_bit_count() == selection.get_size().x * selection.get_size().y


func set_image_pixel(image : Image, x : int, y : int, color : Color):
	if !is_out_of_bounds(Vector2i(x, y), image.get_size()):
		if selection.get_bit(x, y):
			image.set_pixel(x, y, color)


func set_image_pixelv(image : Image, pos : Vector2i, color : Color):
	if !is_out_of_bounds(pos, image.get_size()):
		if selection.get_bitv(pos):
			image.set_pixelv(pos, color)

func get_tool_inspector_properties():
	printerr("Not implemented: get_tool_inspector_properties! (" + get_script().resource_path.get_file() + ")")

func shortcut_pressed():
	printerr("Not implemented: shortcut_pressed! (" + get_script().resource_path.get_file() + ")")

func mouse_pressed(
	event : InputEventMouseButton,
	image : base_layer,
	color1 : Color = Color.BLACK,
	color2 : Color = Color.WHITE,
):
	printerr("Not implemented: mouse_pressed! (" + get_script().resource_path.get_file() + ")")


func get_affected_rect() -> Rect2i:
	printerr("Not implemented: get_affected_rect! (" + get_script().resource_path.get_file() + ")")
	return Rect2i()


func mouse_moved(event : InputEventMouseMotion):
	printerr("Not implemented: mouse_moved! (" + get_script().resource_path.get_file() + ")")

func key_pressed(event : InputEventKey):
	printerr("Not implemented: key_pressed! (" + get_script().resource_path.get_file() + ")")

func enable_tool(): # Save History and Enable Tool
	tool_active = true
func cancel_tool(): # Redo Actions
	tool_active = false
func confirm_tool(): # Confirm Actions
	ToolsManager.current_project.send_changed_signal()
	ToolsManager.current_project.get_node("/root/Editor/MessageLabel").show_step(ToolsManager.current_project.project.undo_redo.get_history_count())
	tool_active = false
func draw_preview(image_view : CanvasItem, mouse_position : Vector2i):
	printerr("Not implemented: draw_preview! (" + get_script().resource_path.get_file() + ")")


func draw_shader_preview(image_view : CanvasItem, mouse_position : Vector2i):
	pass
