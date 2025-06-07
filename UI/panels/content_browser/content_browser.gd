extends VBoxContainer

# The layer object
var resources_container : resources_manager
@onready var group_option_button : OptionButton = $GroupOptionButton
@onready var flow_container : FlowContainer = $ScrollContainer/FlowContainer
var group_list : PackedStringArray = ["All"]
var has_focus

@export var button_group : ButtonGroup
func _ready():
	#tree.connect("selection_changed",_on_Tree_selection_changed)
	self.connect("mouse_entered",_on_mouse_entered)
	self.connect("mouse_exited",_on_mouse_exited)
	group_option_button.connect("item_selected", func(index:int): _refresh())
func _process(_delta):
	if !ProjectsManager.current_project:
		visible = false
		return
	visible = true
	if ProjectsManager.current_project:
		set_resources(ProjectsManager.current_project.resources_container)
	else:
		set_resources(null)
func set_resources(p_resources_manager: resources_manager) -> void:
	if resources_container == p_resources_manager:
		return
	resources_container = p_resources_manager
	if resources_container:
		resources_container.resources_changed.connect(_refresh)
		_refresh()
		group_option_button.select(0)

func _refresh():
	var selected_group = group_option_button.selected
	for child in flow_container.get_children():
		child.queue_free()
	for resource in resources_container.resources:
		if !group_list.has(resource.group_name):
			group_list.append(resource.group_name)
		if group_list[selected_group] != "All" and resource.group_name != group_list[selected_group]:
			continue
		flow_container.add_child(create_item_button(resource))
	group_option_button.clear()
	for group in group_list:
		group_option_button.add_item(group)
	group_option_button.selected = selected_group

func _on_Tree_selection_changed(new_selected) -> void:
	var empty_layers_array : Array[base_layer] = []
	ProjectsManager.current_project.layers_container.selected_layers = empty_layers_array
	for item in new_selected:
		ProjectsManager.current_project.layers_container.select_layer(item.get_meta("layer"))

func create_item_button(p_resource : base_resource) -> Button:
	var new_button : Button = Button.new()
	# data ref
	new_button.set_meta("resource_ref", p_resource)
	# defaults
	new_button.toggle_mode = true
	new_button.button_group = button_group
	new_button.text = p_resource.get_resource_name()
	#icon
	new_button.add_theme_constant_override("icon_max_width", 128)
	new_button.icon = p_resource.get_resource_icon()
	new_button.expand_icon = true
	new_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_BOTTOM
	# drag & drop
	new_button.set_drag_forwarding(_get_item_drag_data.bind(new_button), _item_can_drop_data, _item_drop_data)
	
	# connect changed
	p_resource.changed.connect(update_button.bind(new_button, p_resource))
	new_button.tree_exiting.connect(p_resource.disconnect.bind("changed", update_button))
	return new_button

func update_button(p_button: Button, p_resource: base_resource):
	p_button.icon = p_resource.get_resource_icon()
	p_button.text =  p_resource.get_resource_name()
	#_refresh()

func _get_item_drag_data(at_position: Vector2, p_button: Button) -> Variant:
	var drag_texture := TextureRect.new()
	drag_texture.texture = p_button.icon
	drag_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	drag_texture.size = Vector2(50, 50)
	var drag_label := Label.new()
	drag_label.text = p_button.text
	drag_label.position = Vector2(-25, -25)
	var preview := Control.new()
	preview.add_child(drag_label)
	preview.add_child(drag_texture)
	p_button.set_drag_preview(preview)
	return p_button.get_meta("resource_ref")

func _item_can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return false

func _item_drop_data(at_position: Vector2, data: Variant) -> void:
	pass

func _on_Add_pressed():
	mt_globals.main_window.create_add_resource_context_menu()

func _on_Duplicate_pressed():
	var current : base_resource = get_selected_content()
	if current != null:
		var new_resource : base_resource = resources_container.duplicate_resource(current)
		mt_globals.main_window.open_edit_resource_popup(new_resource)
func _on_Remove_pressed():
	pass


func _on_Config_pressed():
	if get_selected_content():
		mt_globals.main_window.open_edit_resource_popup(get_selected_content())

func _input(_event):
	if Input.is_action_just_pressed("delete"):
		_on_Remove_pressed()

func _on_mouse_entered():
	has_focus = true


func _on_mouse_exited():
	has_focus = false

func get_selected_content() -> base_resource:
	var resource : base_resource
	for button in flow_container.get_children():
		if button.button_pressed:
			resource = button.get_meta("resource_ref")
			break
	return resource
