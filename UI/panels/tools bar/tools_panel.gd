extends ScrollContainer


@onready var tree : HFlowContainer = $PanelContainer/ToolButtons
var has_focus
var _tool_button_scene: PackedScene = preload("res://UI/panels/tools bar/ToolButton.tscn")
func _ready():
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		custom_minimum_size.x = 75
	else:
		custom_minimum_size.x = 35
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
		var _shortcut = 0
		if menu_def[i].tool_button_shortcut != "":
			for s in menu_def[i].tool_button_shortcut.split("+"):
				if s == "Alt":
					_shortcut |= KEY_MASK_ALT
				elif s == "Control":
					#replace with KEY_MASK_CMD_OR_CTRL
					_shortcut |= KEY_MASK_CTRL
				elif s == "Shift":
					_shortcut |= KEY_MASK_SHIFT
				else:
					_shortcut |= OS.find_keycode_from_string(s)

		var tool_button : BaseButton = _tool_button_scene.instantiate()
		tool_button.name = menu_item_name
		tool_button.get_node("Background").modulate = ToolsManager.selected_tool_color
		tool_button.get_node("Icon").texture = icon
		tool_button.tooltip_text = menu_item_tip
		menu.add_child(tool_button)
		tool_button.connect("pressed", on_menu_item_pressed.bind(menu_def, object, i))
var popup : PopupPanel = PopupPanel.new()

func create_temp_tool_settings_panel(p_position:Vector2):
	if mt_globals.get_config("use_drawer"):
		mt_globals.main_window.collapsible.open_tween_toggle.call_deferred()
	else:
		add_child(popup)
		for child in popup.get_children():
			popup.remove_child(child)
			child.queue_free()
		var tool_settings = preload("res://UI/panels/tools bar/tool_settings.tscn").instantiate()
		tool_settings.custom_minimum_size = Vector2(300,300)
		popup.add_child(tool_settings)
		popup.position = p_position
		popup.visible = true





func on_menu_item_pressed(menu_def, object, id) -> void:
	if ToolsManager.current_tool == ToolsManager.TOOLS[id]:
		create_temp_tool_settings_panel(get_global_mouse_position())
	else:
		object.assign_tool(menu_def[id].tool_name, id)
	

func selected_tool_changed(_tool):
	update_tool_buttons()

func update_tool_buttons() -> void:
	for child in tree.get_children():
		var background: NinePatchRect = child.get_node("Background")
		background.visible = ToolsManager.current_tool.tool_name == child.name

func _process(delta: float) -> void:
	for child in tree.get_children():
		if child is BaseButton:
			child.disabled = ToolsManager.TOOLS[tree.get_children().find(child)].is_tool_disabled()

func _on_mouse_entered():
	has_focus = true


func _on_mouse_exited():
	has_focus = false
