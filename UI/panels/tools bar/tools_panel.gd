extends ScrollContainer


@onready var tree : HFlowContainer = $PanelContainer/ToolButtons
var has_focus
var _tool_button_scene: PackedScene = preload("res://UI/panels/tools bar/ToolButton.tscn")
func _ready():
	create_menu(ToolsManager.TOOLS, ToolsManager, tree)
	ToolsManager.connect("tool_changed", selected_tool_changed)
	self.connect("mouse_entered",_on_mouse_entered)
	self.connect("mouse_exited",_on_mouse_exited)

func create_menu(menu_def : Array, object, menu:HFlowContainer):
	for child in menu.get_children():
		child.queue_free()
	for i in menu_def.size():
		var menu_item_name = menu_def[i].tool_name
		var menu_item_tip = menu_def[i].tool_desc
		var icon = menu_def[i].tool_icon
		var shortcut = 0
		if menu_def[i].tool_button_shortcut != "":
			for s in menu_def[i].tool_button_shortcut.split("+"):
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
		tool_button.get_node("Background").modulate = ToolsManager.selected_tool_color
		tool_button.get_node("Icon").texture = icon
		tool_button.tooltip_text = menu_item_tip
		menu.add_child(tool_button)
		tool_button.connect("pressed", on_menu_item_pressed.bind(menu_def, object, i))
		



func on_menu_item_pressed(menu_def, object, id) -> void:
	object.assign_tool(menu_def[id].tool_name, id)
	

func selected_tool_changed(_tool):
	update_tool_buttons()

func update_tool_buttons() -> void:
	for child in tree.get_children():
		var background: NinePatchRect = child.get_node("Background")
		background.visible = ToolsManager.current_tool.tool_name == child.name


func _on_mouse_entered():
	has_focus = true


func _on_mouse_exited():
	has_focus = false
