extends Node


signal color_changed(color, button)
signal tool_changed(assigned_tool)

var active_canvas : Dictionary
var pen_pressure := 1.0
var horizontal_mirror := false
var vertical_mirror := false
var pixel_perfect := false
var selected_tool_color := Color("0086cf")
var effect_scaling_factor : float = 1.0
var current_color1 : Color
var current_color2 : Color
var TOOLS : Array[ToolBase] = [
	preload("res://src/tools/select_tool.gd").new(),
	preload("res://src/tools/move_tool.gd").new(),
	preload("res://src/tools/rotate_tool.gd").new(),
	preload("res://src/tools/scale_tool.gd").new(),
	preload("res://src/tools/crop_tool.gd").new(),
	preload("res://src/tools/brush_tool.gd").new(),
	#preload("res://src/tools/brush_clone_tool.gd").new(),
	preload("res://src/tools/bucket_tool.gd").new(),
	preload("res://src/tools/context_menu_tool.gd").new(),
]
var current_tool : ToolBase
var shortcut_tool : ToolBase
var current_project : Project
var camera : Camera2D
@export var smooth_mode : bool = false
var current_mouse_position : Vector2
var previous_mouse_position : Vector2
var mouse_position_delta : Vector2

func draw_preview(image_view : CanvasItem, mouse_position : Vector2i):
	if shortcut_tool != null: shortcut_tool.draw_preview(image_view, mouse_position)
	if current_tool != null: current_tool.draw_preview(image_view, mouse_position)
	
	

func handle_image_input(event) -> bool:
	
	if event is InputEventKey: return false
	
	if !current_project:
		return false
	
	
	if current_project.layers_container.selected_layers.is_empty():
		return false
	
	
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
				current_project.layers_container.selected_layers[0],
			)
		if shortcut_tool:
			shortcut_tool.mouse_pressed(
				event,
				current_project.layers_container.selected_layers[0],
			)
		if current_tool:
			if current_tool.image_hide_mode != 2:
				for layer in current_project.layers_container.selected_layers:
					layer.main_object.self_modulate.a = 1.0
		if current_tool:
			if event.pressed && current_tool.image_hide_mode == 1:
				for layer in current_project.layers_container.selected_layers:
					layer.main_object.self_modulate.a = 0.0

	return true
func _process(_delta):
	current_project = ProjectsManager.current_project
	if !current_project:
		return
	var left_mouse_cursor_visible : bool = false
	for c in active_canvas.values():
		if c == true:
			left_mouse_cursor_visible = mt_globals.show_left_tool_icon
			for tool in TOOLS:
				tool.shortcut_pressed()
			break
	mt_globals.main_window.left_cursor.visible = left_mouse_cursor_visible
func _input(_event):
	if Input.is_key_pressed(KEY_SHIFT):
		effect_scaling_factor = 0.25
	else:
		effect_scaling_factor = 1.0


func assign_tool(_p_name: String, button: int) -> void:
	if TOOLS[button].tool_name == "add_layer":
		TOOLS[button].enable_tool()
		return
	current_tool = TOOLS[button]
	emit_signal("tool_changed",current_tool)
	update_tool_cursors()


func update_tool_cursors() -> void:
	var cursor_icon = current_tool.tool_icon
	mt_globals.main_window.left_cursor.texture = cursor_icon
	



func get_paint_layer() -> paint_layer:
	if ToolsManager.current_project.layers_container.selected_layers.is_empty():
		select_or_create_paint_layer()
		return ToolsManager.current_project.layers_container.selected_layers[0]
	if ToolsManager.current_project.layers_container.selected_layers[0].type != base_layer.LAYER_TYPE.BRUSH:
		select_or_create_paint_layer()
	return ToolsManager.current_project.layers_container.selected_layers[0]
	
func select_or_create_paint_layer():
	var selected_paint_layer : bool = false
	for layer in ToolsManager.current_project.layers_container.layers:
		if layer.type == base_layer.LAYER_TYPE.BRUSH:
			ToolsManager.current_project.layers_container.selected_layers.insert(0,layer)
			selected_paint_layer = true
			break
	if selected_paint_layer:
		return
	if !ProjectsManager.current_project:
		return
	var new_paint_layer = paint_layer.new()
	new_paint_layer.init(ProjectsManager.current_project.layers_container.get_unused_layer_name(), ProjectsManager.current_project)
	ToolsManager.current_project.layers_container.selected_layers.insert(0,new_paint_layer) 
