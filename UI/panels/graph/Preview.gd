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
	if Input.is_action_just_pressed("mouse_left"):
		mouse_selection_check()
	return ToolsManager.handle_image_input(event)

func mouse_selection_check():
	if ToolsManager.current_tool:
		if ToolsManager.current_tool.tool_active:
			return
	if ToolsManager.shortcut_tool:
		if ToolsManager.shortcut_tool.tool_active:
			return
	#print("pic mouse pos: ", preview.get_local_mouse_position())
	var selected_layers : Array[base_layer] = layers_mouse_overlap_check(ProjectsManager.current_project.layers_container.layers, get_local_mouse_position())
	var empty_layers_array : Array[base_layer] = []
	ProjectsManager.current_project.layers_container.selected_layers = empty_layers_array
	for layer in selected_layers:
		ProjectsManager.current_project.layers_container.select_layer(layer)

func layers_mouse_overlap_check(layers:Array[base_layer], mouse_pos:Vector2) -> Array[base_layer]:
	var overlap_layers: Array[base_layer] = []
	for layer in layers:
		#print(layer.get_rect())
		if layer.get_rect().has_point(mouse_pos):
			overlap_layers.append(layer)
		overlap_layers.append_array(layers_mouse_overlap_check(layer.children, mouse_pos))
	return overlap_layers

func _input(event):
	if !get_parent().get_parent().get_parent().visible or get_parent().get_parent().get_parent().has_focus == false:
		return
	pass_event_to_tool(event)
