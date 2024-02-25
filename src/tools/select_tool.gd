extends ToolBase

enum {
	DRAG_LEAVE_TRANSPARENT,
	DRAG_LEAVE_SECONDARY,
	DRAG_SELECTION_ONLY,
	DRAG_NONE,
}

var operation := 0
var dragging_mode := DRAG_LEAVE_TRANSPARENT
var deselect_function : Callable = deselect
var erase_function : Callable = erase
var invert_function : Callable = invert


var mouse_down := false
var selection_dragging := false
var image : Image
var draw_start := Vector2i()
var draw_end := Vector2i()
var image_size := Vector2i()

func _init():
	tool_name = "Select Tool"
	tool_button_shortcut = ""
	tool_desc = ""
	tool_icon = get_icon_from_project_folder("select")

func deselect():
	print("test")
func erase():
	print("test")
func invert():
	print("test")

func get_tool_inspector_properties():
	var PropertiesView : Array = []
	var PropertiesGroups : Array[String] = []
	PropertiesGroups.append("Settings")
	var PropertiesToShow : Dictionary = {}
	PropertiesToShow["operation,Replace,Add (Ctrl),Subtract (Right-click),Intersection,Invert"] = "Settings"
	PropertiesToShow["dragging_mode,Transparent BG,Secondary Color BG,Move Selection Only,Never Drag"] = "Settings"
	PropertiesToShow["deselect_function"] = "Settings"
	PropertiesToShow["erase_function"] = "Settings"
	PropertiesToShow["invert_function"] = "Settings"
	PropertiesView.append(PropertiesGroups)
	PropertiesView.append(PropertiesToShow)
	return PropertiesView



func shortcut_pressed():
	if Input.is_action_just_pressed("move") and not Input.is_key_pressed(KEY_SHIFT) and not Input.is_key_pressed(KEY_CTRL) and not Input.is_key_pressed(KEY_ALT):
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
		if tool_active:
			confirm_tool()
			return
	if Input.is_action_just_pressed("cancel"):
		cancel_tool()

func mouse_pressed(
	event : InputEventMouseButton,
	_image : base_layer,
):
	if event.button_index == MOUSE_BUTTON_RIGHT and tool_active:
		cancel_tool()


func get_affected_rect() -> Rect2i:
	if selection_dragging:
		# Can be anything!
		return Rect2i(Vector2i.ZERO, image_size)

	else:
		return Rect2()


func mouse_moved(_event : InputEventMouseMotion):
	if !tool_active:
		return
	if !ToolsManager.current_project.layers_container.selected_layers:
		tool_active = false
	

func draw_preview(_image_view : CanvasItem, _mouse_position : Vector2i):
	if !tool_active:
		return
	if !ToolsManager.current_project:
		return
	if ToolsManager.current_project.layers_container.selected_layers.is_empty():
		return
	
func enable_tool(): # Save History and Enable Tool
	ToolsManager.current_project.undo_redo.create_action("Move Layers")
	for selected in ToolsManager.current_project.layers_container.selected_layers:
		ToolsManager.current_project.undo_redo.add_undo_property(selected,"position",selected.position)
	super.enable_tool()
func cancel_tool(): # Redo Actions
	if ToolsManager.current_project.layers_container.selected_layers:
		for selected in ToolsManager.current_project.layers_container.selected_layers:
			ToolsManager.current_project.undo_redo.add_do_property(selected, "position", selected.position)
		ToolsManager.current_project.undo_redo.commit_action()
		for selected in ToolsManager.current_project.layers_container.selected_layers:
			ToolsManager.current_project.undo_redo.undo()
	super.cancel_tool()
func confirm_tool(): # Confirm Actions
	if ToolsManager.current_project.layers_container.selected_layers:
		for selected in ToolsManager.current_project.layers_container.selected_layers:
			ToolsManager.current_project.undo_redo.add_do_property(selected, "position", selected.position)
		ToolsManager.current_project.undo_redo.commit_action()
	super.confirm_tool()



