extends TextureRect


func _process(delta):
	if !texture.viewport_path:
		texture.viewport_path = mt_globals.main_window.app_render.get_path()
	queue_redraw()
	if !get_parent().get_parent().get_parent().visible or get_parent().get_parent().get_parent().has_focus == false:
		return
	ToolsManager.current_mouse_position = get_local_mouse_position()
	ToolsManager.mouse_position_delta = ToolsManager.current_mouse_position - ToolsManager.previous_mouse_position if ToolsManager.smooth_mode == false else Input.get_last_mouse_velocity() * delta
	ToolsManager.previous_mouse_position = get_local_mouse_position()
	
func _draw():
	ToolsManager.call_thread_safe("draw_preview", self, get_local_mouse_position())

func pass_event_to_tool(event) -> bool:
	# Touch jumps the pointer on press, update the position now instead of waiting for _process.
	if event is InputEventMouse:
		ToolsManager.current_mouse_position = make_input_local(event).position
	# Only on the press itself, while a tool is active the click belongs to that tool.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Ctrl (Cmd on macOS) + click selects only the top visible layer under the mouse
		mouse_selection_check(event.is_command_or_control_pressed())
	return ToolsManager.handle_image_input(event)

func mouse_selection_check(only_top_layer: bool = false):
	if ToolsManager.current_tool:
		if ToolsManager.current_tool.tool_active:
			return
	if ToolsManager.shortcut_tool:
		if ToolsManager.shortcut_tool.tool_active:
			return
	#print("pic mouse pos: ", preview.get_local_mouse_position())
	var selected_layers : Array[base_layer] = layers_mouse_overlap_check(ProjectsManager.current_project.layers_container.layers, get_local_mouse_position())
	if only_top_layer:
		selected_layers = get_top_visible_layer(selected_layers)
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

## Layers are found in drawing order (later siblings and children draw on top),
## so the top one is the last that isn't hidden.
func get_top_visible_layer(layers: Array[base_layer]) -> Array[base_layer]:
	var result : Array[base_layer] = []
	for i in range(layers.size() - 1, -1, -1):
		if is_layer_visible(layers[i]):
			result.append(layers[i])
			break
	return result

func is_layer_visible(layer: base_layer) -> bool:
	while layer:
		if layer.hidden:
			return false
		layer = layer.parent
	return true

func _input(event):
	if !get_parent().get_parent().get_parent().visible or get_parent().get_parent().get_parent().has_focus == false:
		return
	pass_event_to_tool(event)
