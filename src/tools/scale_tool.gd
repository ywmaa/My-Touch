extends ToolBase

enum coordinates {xy,x,y}
var direction : coordinates = coordinates.xy
var axis_position : Vector2 = Vector2.ZERO

func _init():
	tool_name = "Scale Tool"
	tool_button_shortcut = "Shift+S"
	tool_desc = ""
	tool_icon = get_icon_from_project_folder("scale")


func get_tool_inspector_properties():
	printerr("Not implemented: get_tool_inspector_properties! (" + get_script().resource_path.get_file() + ")")



func shortcut_pressed():
	if Input.is_action_just_pressed("scale"):
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
	if Input.is_action_just_pressed("lock_x") and tool_active:
		lock_x()
	if Input.is_action_just_pressed("lock_y") and tool_active:
		lock_y()

func mouse_pressed(
	event : InputEventMouseButton,
	_image : base_layer,
	_color1 : Color = Color.BLACK,
	_color2 : Color = Color.WHITE,
):
	if event.button_index == MOUSE_BUTTON_RIGHT and tool_active:
		cancel_tool()


func get_affected_rect() -> Rect2i:
	printerr("Not implemented: get_affected_rect! (" + get_script().resource_path.get_file() + ")")
	return Rect2i()


func mouse_moved(_event : InputEventMouseMotion):
	if !tool_active:
		return
	if !ToolsManager.current_project.layers.selected_layers:
		tool_active = false
	for selected in ToolsManager.current_project.layers.selected_layers:
		scale(selected,ToolsManager.mouse_position_delta*ToolsManager.get_process_delta_time(),selected.lock_aspect) 

func draw_preview(image_view : CanvasItem, _mouse_position : Vector2i):
	if !tool_active:
		return
	if ToolsManager.current_project.layers.selected_layers.is_empty():
		return
	axis_position = ToolsManager.current_project.layers.selected_layers[0].main_object.position
	# Draw Axis
	if direction == coordinates.x or direction == coordinates.xy:
		image_view.draw_line(ToolsManager.axis_position * Vector2(-100000,1), ToolsManager.axis_position * Vector2(100000,1), Color(1,0,0), -1, true)
		image_view.queue_redraw()
	if direction == coordinates.y or direction == coordinates.xy:
		image_view.draw_line(ToolsManager.axis_position * Vector2(1,-100000), ToolsManager.axis_position * Vector2(1,100000), Color(0,1,0), -1, true)
		image_view.queue_redraw()
	

func enable_tool(): # Save History and Enable Tool
	ToolsManager.current_project.undo_redo.create_action("Scale Layers")
	for selected in ToolsManager.current_project.layers.selected_layers:
		ToolsManager.current_project.undo_redo.add_undo_property(selected,"scale",selected.scale)
	direction = coordinates.xy
	super.enable_tool()
func cancel_tool(): # Redo Actions
	if ToolsManager.current_project.layers.selected_layers:
		for selected in ToolsManager.current_project.layers.selected_layers:
			ToolsManager.current_project.undo_redo.add_do_property(selected, "scale", selected.scale)
		ToolsManager.current_project.undo_redo.commit_action()
		for selected in ToolsManager.current_project.layers.selected_layers:
			ToolsManager.current_project.undo_redo.undo()
	super.cancel_tool()
func confirm_tool(): # Confirm Actions
	if ToolsManager.current_project.layers.selected_layers:
		for selected in ToolsManager.current_project.layers.selected_layers:
			ToolsManager.current_project.undo_redo.add_do_property(selected, "scale", selected.scale)
		ToolsManager.current_project.undo_redo.commit_action()
	super.confirm_tool()


func scale(object,amount:Vector2,lock_aspect:bool):
	match direction:
		coordinates.xy:
			object.scale += amount *ToolsManager.effect_scaling_factor
			if lock_aspect:
				object.scale.y = object.scale.x
		coordinates.x:
			object.scale.x += amount.x *ToolsManager.effect_scaling_factor
			if lock_aspect:
				object.scale.y = object.scale.x
		coordinates.y:
			object.scale.y += amount.y *ToolsManager.effect_scaling_factor
			if lock_aspect:
				object.scale.x = object.scale.y

func lock_x():
	if direction == coordinates.x:
		direction = coordinates.xy
	else:
		direction = coordinates.x

func lock_y():
	if direction == coordinates.y:
		direction = coordinates.xy
	else:
		direction = coordinates.y

