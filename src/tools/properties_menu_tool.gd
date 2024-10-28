extends ToolBase

func _init():
	tool_name = "layer_properties"
	tool_button_shortcut = ""
	tool_desc = "Show Layer Properties"
	tool_icon = get_icon_from_project_folder("properties_settings_icon")



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
	

func enable_tool(): # Save History and Enable Tool
	mt_globals.main_window.create_temp_properties_panel()
func cancel_tool(): # Redo Actions
	pass
func confirm_tool(): # Confirm Actions
	pass
