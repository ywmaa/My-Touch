extends ToolBase


func _init():
	tool_name = "Crop Tool"
	tool_button_shortcut = "Shift+V"
	tool_desc = ""
	tool_icon = get_icon_from_project_folder("crop")


func get_inspector_properties():
	pass


func shortcut_pressed():
	tool_active = (ToolsManager.current_tool == self or ToolsManager.shortcut_tool == self)
	if Input.is_action_just_pressed("crop") and not Input.is_key_pressed(KEY_SHIFT) and not Input.is_key_pressed(KEY_CTRL) and not Input.is_key_pressed(KEY_ALT):
		if ToolsManager.shortcut_tool == self:
			ToolsManager.shortcut_tool = null
			return
		ToolsManager.shortcut_tool = self
	if Input.is_action_just_pressed("cancel"):
		if ToolsManager.shortcut_tool == self:
			ToolsManager.shortcut_tool = null
		if ToolsManager.current_tool == self:
			ToolsManager.current_tool = null
		cancel_tool()

func mouse_pressed(
	_event : InputEventMouseButton,
	_image : base_layer,
):
	pass


func mouse_moved(_event : InputEventMouseMotion):
	pass

func draw_preview(_image_view : CanvasItem, _mouse_position : Vector2i):
	pass
