extends ToolBase

func _init():
	tool_name = "undo"
	tool_button_shortcut = ""
	tool_desc = "Undo"
	tool_icon = get_icon_from_project_folder("undo")


func get_inspector_properties():
	printerr("Not implemented: get_inspector_properties! (" + get_script().resource_path.get_file() + ")")



func shortcut_pressed():
	pass

func mouse_pressed(
	_event : InputEventMouseButton,
	_image : base_layer,
	_color1 : Color = Color.BLACK,
	_color2 : Color = Color.WHITE,
):
	pass


func get_affected_rect() -> Rect2i:
	pass
	return Rect2i()


func mouse_moved(_event : InputEventMouseMotion):
	pass
func draw_preview(_image_view : CanvasItem, _mouse_position : Vector2i):
	pass
	
func is_tool_disabled() -> bool:
	return mt_globals.main_window.edit_undo_is_disabled()
func enable_tool(): # Save History and Enable Tool
	mt_globals.main_window.edit_undo()
func cancel_tool(): # Redo Actions
	pass
func confirm_tool(): # Confirm Actions
	pass
