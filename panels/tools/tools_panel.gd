extends VBoxContainer
var tools_items : Array 
@onready var tree : Tree = $Tree
const TOOLS = [
	{ tool="Select", command="none", shortcut="Shift+F", tooltip="select tool" },
	{ tool="Move", command="move", shortcut="Shift+G", tooltip="move tool" },
	{ tool="Rotate", command="rotate", shortcut="Shift+R", tooltip="rotate tool" },
	{ tool="Scale", command="scale", shortcut="Shift+S", tooltip="scale tool" },
]

func _on_tree_item_activated():
	pass # Replace with function body.


func _on_tree_item_double_clicked():
	pass # Replace with function body.

func _ready():
	create_menu(TOOLS,self,tree)

func create_menu(menu_def : Array, object : Object, menu:Tree):
	menu.clear()
	if !menu.is_connected("item_selected", on_menu_id_pressed):
		menu.connect("item_selected", on_menu_id_pressed.bind(menu_def, object))
	for i in menu_def.size():
		if menu_def[i].has("standalone_only") and menu_def[i].standalone_only and Engine.is_editor_hint():
			continue
		if menu_def[i].has("editor_only") and menu_def[i].editor_only and !Engine.is_editor_hint():
			continue
		var menu_item_name = menu_def[i].tool
		var menu_item_tip = menu_def[i].tooltip
		var shortcut = 0
		if menu_def[i].has("shortcut"):
			for s in menu_def[i].shortcut.split("+"):
				if s == "Alt":
					shortcut |= KEY_MASK_ALT
				elif s == "Control":
					#replace with KEY_MASK_CMD_OR_CTRL
					shortcut |= KEY_MASK_CTRL
				elif s == "Shift":
					shortcut |= KEY_MASK_SHIFT
				else:
					shortcut |= OS.find_keycode_from_string(s)
		if menu.get_root() == null:
			menu.create_item()
		if menu_def[i].has("toggle") and menu_def[i].toggle:
			var item : TreeItem = menu.create_item()
			item.set_cell_mode(0,TreeItem.CELL_MODE_CHECK)
			item.set_text(0,menu_item_name)
			item.set_tooltip_text(0,menu_item_tip)
			tools_items.append(item)
		else:
			var item : TreeItem = menu.create_item()
			item.set_text(0,menu_item_name)
			item.set_editable(0,false)
			item.set_tooltip_text(0,menu_item_tip)
			tools_items.append(item)
			

func on_menu_id_pressed(menu_def, object) -> void:
	var id = tree.get_selected().get_index()
	if menu_def[id].has("command"):
		var command = menu_def[id].command
		if object.has_method(command):
			var parameters = []
			if menu_def[id].has("command_parameter"):
				parameters.append(menu_def[id].command_parameter)
			if menu_def[id].has("toggle") and menu_def[id].toggle:
				parameters.append(!object.callv(command, parameters))
			object.callv(command, parameters)

func _input(event):
	for tool in TOOLS:
		if tool.shortcut == event.as_text():
			tools_items[TOOLS.find(tool)].select(0)
func none():
	ToolManager.current_tool = ToolManager.tool_mode.none
	ToolManager.current_mode = ToolManager.tool_mode.none
func move():
	ToolManager.current_tool = ToolManager.tool_mode.move_image
	ToolManager.current_mode = ToolManager.tool_mode.none
func rotate():
	ToolManager.current_tool = ToolManager.tool_mode.rotate_image
	ToolManager.current_mode = ToolManager.tool_mode.none
func scale():
	ToolManager.current_tool = ToolManager.tool_mode.scale_image
	ToolManager.current_mode = ToolManager.tool_mode.none
