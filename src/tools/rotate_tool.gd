extends ToolBase

func _init():
	tool_name = "Rotate Tool"
	tool_button_shortcut = "Shift+R"
	tool_desc = ""
	tool_icon = get_icon_from_project_folder("rotate")


func get_tool_inspector_properties():
	printerr("Not implemented: get_tool_inspector_properties! (" + get_script().resource_path.get_file() + ")")



func shortcut_pressed():
	if Input.is_action_just_pressed("rotate"):
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

func mouse_pressed(
	event : InputEventMouseButton,
	image : base_layer,
	color1 : Color = Color.BLACK,
	color2 : Color = Color.WHITE,
):
	if event.button_index == MOUSE_BUTTON_RIGHT and tool_active:
		cancel_tool()


func get_affected_rect() -> Rect2i:
	printerr("Not implemented: get_affected_rect! (" + get_script().resource_path.get_file() + ")")
	return Rect2i()

var prev = Vector2.ZERO
func mouse_moved(event : InputEventMouseMotion):
	if !tool_active:
		return
	if !ToolsManager.current_project.layers.selected_layers:
		tool_active = false
	var canvas_position : Vector2 = ToolsManager.current_project.canvas_size/2-ToolsManager.camera.offset*(ToolsManager.camera.zoom)
	for selected in ToolsManager.current_project.layers.selected_layers:
		var object_pos = canvas_position+(selected.position*ToolsManager.camera.zoom)-(selected.main_object.get_rect().size*selected.scale*ToolsManager.camera.zoom/4)
		rotate(selected,75*(object_pos.angle_to_point(ToolsManager.current_mouse_position) - object_pos.angle_to_point(ToolsManager.current_mouse_position-event.relative)))
	prev = event.global_position
func draw_preview(image_view : CanvasItem, mouse_position : Vector2i):
	pass
	

func enable_tool(): # Save History and Enable Tool
	ToolsManager.current_project.undo_redo.create_action("Move Layers")
	for selected in ToolsManager.current_project.layers.selected_layers:
		ToolsManager.current_project.undo_redo.add_undo_property(selected,"rotation",selected.rotation)
	super.enable_tool()
func cancel_tool(): # Redo Actions
	if ToolsManager.current_project.layers.selected_layers:
		for selected in ToolsManager.current_project.layers.selected_layers:
			ToolsManager.current_project.undo_redo.add_do_property(selected, "rotation", selected.rotation)
		ToolsManager.current_project.undo_redo.commit_action()
		for selected in ToolsManager.current_project.layers.selected_layers:
			ToolsManager.current_project.undo_redo.undo()
	super.cancel_tool()
func confirm_tool(): # Confirm Actions
	if ToolsManager.current_project.layers.selected_layers:
		for selected in ToolsManager.current_project.layers.selected_layers:
			ToolsManager.current_project.undo_redo.add_do_property(selected, "rotation", selected.rotation)
		ToolsManager.current_project.undo_redo.commit_action()
	super.confirm_tool()


func rotate(object, rotation_amount:float):
	object.rotation += rotation_amount *ToolsManager.effect_scaling_factor


