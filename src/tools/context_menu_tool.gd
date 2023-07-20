extends ToolBase

func _init():
	tool_name = "add_layer"
	tool_button_shortcut = ""
	tool_desc = "Add Layer Object"
	tool_icon = get_icon_from_project_folder("add")


func get_tool_inspector_properties():
	printerr("Not implemented: get_tool_inspector_properties! (" + get_script().resource_path.get_file() + ")")



func shortcut_pressed():
	pass

func mouse_pressed(
	event : InputEventMouseButton,
	image : base_layer,
	color1 : Color = Color.BLACK,
	color2 : Color = Color.WHITE,
):
	pass


func get_affected_rect() -> Rect2i:
	pass
	return Rect2i()


func mouse_moved(event : InputEventMouseMotion):
	pass
func draw_preview(image_view : CanvasItem, mouse_position : Vector2i):
	pass
	

func enable_tool(): # Save History and Enable Tool
	mt_globals.main_window.create_add_context_menu()
func cancel_tool(): # Redo Actions
	pass
func confirm_tool(): # Confirm Actions
	pass


