extends Node


signal color_changed(color, button)
signal tool_changed(assigned_tool)

var pen_pressure := 1.0
var horizontal_mirror := false
var vertical_mirror := false
var pixel_perfect := false
var selected_tool_color := Color("0086cf")
var effect_scaling_factor : float = 1.0
var current_color1 : Color
var current_color2 : Color
var TOOLS : Array[ToolBase] = [
	preload("res://src/tools/move_tool.gd").new(),
	preload("res://src/tools/rotate_tool.gd").new(),
	preload("res://src/tools/scale_tool.gd").new(),
]
var current_tool : ToolBase
var shortcut_tool : ToolBase
var current_project : MTGraph
@export var smooth_mode : bool = false
var current_mouse_position : Vector2
var previous_mouse_position : Vector2
var mouse_position_delta : Vector2

func handle_image_input(event) -> bool:
	
	if event is InputEventKey: return false
	
	if !current_project:
		return false
	
	if current_project.project.layers.selected_layers.is_empty():
		return false
	
	event.position = event.global_position
	if event is InputEventMouseMotion:
#		current_tool.selection = selection  # Needed because Image Script tool does not normally use clicks
		# I better just fetch it from the Workspace but also ehhhh incapsulation
		if current_tool != null: current_tool.mouse_moved(event)
		if shortcut_tool != null: shortcut_tool.mouse_moved(event)

	elif event is InputEventMouseButton:
		if current_tool:
	#		current_tool.selection = selection
			current_tool.mouse_pressed(
				event,
				current_project.project.layers.selected_layers[0],
				current_color1 if event.button_index == MOUSE_BUTTON_LEFT else current_color2,
				current_color1 if event.button_index != MOUSE_BUTTON_LEFT else current_color2
			)
		if shortcut_tool:
			shortcut_tool.mouse_pressed(
				event,
				current_project.project.layers.selected_layers[0],
				current_color1 if event.button_index == MOUSE_BUTTON_LEFT else current_color2,
				current_color1 if event.button_index != MOUSE_BUTTON_LEFT else current_color2
			)
		if current_tool:
			if current_tool.image_hide_mode != 2:
				for layer in current_project.project.layers.selected_layers:
					layer.main_object.self_modulate.a = 1.0
		if current_tool:
			if event.pressed && current_tool.image_hide_mode == 1:
				for layer in current_project.project.layers.selected_layers:
					layer.main_object.self_modulate.a = 0.0

	return true
func _process(delta):
	current_project = mt_globals.main_window.get_current_graph_edit()
	for tool in TOOLS:
		tool.shortcut_pressed()
	
func _input(_event):
	if Input.is_key_pressed(KEY_SHIFT):
		effect_scaling_factor = 0.25
	else:
		effect_scaling_factor = 1.0


func add_context():
	mt_globals.main_window.get_current_graph_edit().create_add_context_menu()

func assign_tool(_p_name: String, button: int) -> void:
	current_tool = TOOLS[button]
	emit_signal("tool_changed",current_tool)
	update_tool_cursors()


func update_tool_cursors() -> void:
	var cursor_icon = current_tool.tool_icon
	mt_globals.main_window.left_cursor.texture = cursor_icon
	





