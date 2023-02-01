extends Node


signal color_changed(color, button)
signal tool_changed(assigned_tool)

var pen_pressure := 1.0
var horizontal_mirror := false
var vertical_mirror := false
var pixel_perfect := false
var selected_tool_color := Color("0086cf")
var effect_scaling_factor : float = 1.0

const TOOLS = [
	{ tool="Select", command="tool_none", shortcut="Shift+F", tooltip="select tool",settings_node=null },
	{ tool="Move", command="tool_move", shortcut="Shift+G", tooltip="move tool" },
	{ tool="Rotate", command="tool_rotate", shortcut="Shift+R", tooltip="rotate tool" },
	{ tool="Scale", command="tool_scale", shortcut="Shift+S", tooltip="scale tool" },
	{ tool="Add", command="add_context", shortcut="", tooltip="Add Context" },
]
var assigned_tool
enum coordinates {xy,x,y}

var direction : coordinates = coordinates.xy

enum tool_mode {none,move_image,rotate_image,scale_image,selection_tools,text}
var current_tool : tool_mode = tool_mode.none



var last_mode : tool_mode = tool_mode.none
var current_mode : tool_mode = tool_mode.none:
	get: return current_mode
	set(new_mode):
		last_mode = current_mode
		current_mode = new_mode


func _input(event):
	if Input.is_key_pressed(KEY_SHIFT):
		effect_scaling_factor = 0.25
	else:
		effect_scaling_factor = 1.0

func tool_none():
	ToolManager.current_tool = ToolManager.tool_mode.none
	ToolManager.current_mode = ToolManager.tool_mode.none
func tool_move():
	ToolManager.current_tool = ToolManager.tool_mode.move_image
	ToolManager.current_mode = ToolManager.tool_mode.none
func tool_rotate():
	ToolManager.current_tool = ToolManager.tool_mode.rotate_image
	ToolManager.current_mode = ToolManager.tool_mode.none
func tool_scale():
	ToolManager.current_tool = ToolManager.tool_mode.scale_image
	ToolManager.current_mode = ToolManager.tool_mode.none

func add_context():
	mt_globals.main_window.get_current_graph_edit().create_add_context_menu()

func assign_tool(name: String, button: int) -> void:
	assigned_tool = TOOLS[button]

	
	call(assigned_tool.command)
	if assigned_tool.tool == "Add":
		return
	emit_signal("tool_changed",assigned_tool)
	update_tool_cursors()



func update_tool_cursors() -> void:
	var cursor_icon = load("res://graphics/tools/%s.png" % assigned_tool.tool.to_lower())
	mt_globals.main_window.left_cursor.texture = cursor_icon
	

func rotate(object, rotation_amount:float):
	object.rotation += rotation_amount *effect_scaling_factor


func scale(object,amount:Vector2):
	match direction:
		coordinates.xy:
			object.scale += amount *effect_scaling_factor
		coordinates.x:
			object.scale.x += amount.x *effect_scaling_factor
		coordinates.y:
			object.scale.y += amount.y *effect_scaling_factor


func move(object,amount:Vector2):
	
	match direction:
		coordinates.xy:
			object.position += amount *effect_scaling_factor
		coordinates.x:
			object.position.x += amount.x *effect_scaling_factor
		coordinates.y:
			object.position.y += amount.y *effect_scaling_factor

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
