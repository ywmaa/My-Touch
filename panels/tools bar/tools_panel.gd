extends ScrollContainer


@onready var tree : HFlowContainer = $PanelContainer/ToolButtons

var _tool_button_scene: PackedScene = preload("res://panels/tools bar/ToolButton.tscn")
func _ready():
	create_menu(ToolManager.TOOLS, ToolManager, tree)
	ToolManager.connect("tool_changed", selected_tool_changed)

func create_menu(menu_def : Array, object, menu:HFlowContainer):
	for child in menu.get_children():
		child.queue_free()
	for i in menu_def.size():
		if menu_def[i].has("standalone_only") and menu_def[i].standalone_only and Engine.is_editor_hint():
			continue
		if menu_def[i].has("editor_only") and menu_def[i].editor_only and !Engine.is_editor_hint():
			continue
		var menu_item_name = menu_def[i].tool
		var menu_item_tip = menu_def[i].tooltip
		var icon = load("res://graphics/tools/%s.png" % menu_item_name.to_lower())
		var cursor_icon = load("res://graphics/tools/%s.png" % menu_item_name.to_lower())
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

		var tool_button : BaseButton = _tool_button_scene.instantiate()
		tool_button.name = menu_item_name
		tool_button.get_node("Background").modulate = ToolManager.selected_tool_color
		tool_button.get_node("Icon").texture = icon
		tool_button.tooltip_text = menu_item_tip
		menu.add_child(tool_button)
		tool_button.connect("pressed", on_menu_item_pressed.bind(menu_def, object, i))
		



func on_menu_item_pressed(menu_def, object, id) -> void:
	object.assign_tool(menu_def[id].tool, id)
	

func selected_tool_changed(tool):
	update_tool_buttons()

func update_tool_buttons() -> void:
	for child in tree.get_children():
		var background: NinePatchRect = child.get_node("Background")
		background.visible = ToolManager.assigned_tool.tool == child.name
