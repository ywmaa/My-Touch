extends TextureRect


func _process(delta):
	if !texture.viewport_path:
		texture.viewport_path = mt_globals.main_window.find_child("AppRender").get_path()
	queue_redraw()
	if !get_parent().get_parent().get_parent().visible or get_parent().get_parent().get_parent().has_focus == false:
		return
	ToolsManager.current_mouse_position = get_local_mouse_position()
	ToolsManager.mouse_position_delta = ToolsManager.current_mouse_position - ToolsManager.previous_mouse_position if ToolsManager.smooth_mode == false else Input.get_last_mouse_velocity() * delta
	ToolsManager.previous_mouse_position = get_local_mouse_position()
	
func _draw():
	ToolsManager.call("draw_preview", self, get_local_mouse_position())

func pass_event_to_tool(event) -> bool:
	return ToolsManager.handle_image_input(event)

func _input(event):
	if !get_parent().get_parent().get_parent().visible or get_parent().get_parent().get_parent().has_focus == false:
		return
	pass_event_to_tool(event)
