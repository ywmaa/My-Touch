extends VBoxContainer
class_name ResourceEdit

var group_list : PackedStringArray = ["All"]
var resources_list : Array[base_resource]
var current_resource: base_resource:
	set(v):
		current_resource = v


signal resource_changed(value:base_resource)

@export var option_button : OptionButton
@export var group_option_button : OptionButton

var filter
func init(value: base_resource) -> void:
	filter = value.get_script()
	current_resource = value
	get_resources_list()
	ToolsManager.current_project.resources_container.resources_changed.connect(get_resources_list)
	option_button.selected = resources_list.find(value)
	group_option_button.connect("item_selected", func(index:int): _refresh())
	option_button.connect("item_selected", func(index:int): current_resource = resources_list[option_button.get_selected_id()]; resource_changed.emit(current_resource))
	option_button.set_drag_forwarding(func(): pass, _can_drop_data, _drop_data)
	group_option_button.select(0)
	
func get_resources_list():
	resources_list.clear()
	for resource in ToolsManager.current_project.resources_container.resources:
		if resource.get_script() == filter: # check if they are the same custom resource
			resources_list.append(resource)
	_refresh()


func _refresh():
	var selected_group = group_option_button.selected
	option_button.clear()
	for resource in resources_list:
		if !group_list.has(resource.group_name):
			group_list.append(resource.group_name)
		if group_list[selected_group] != "All" and resource.group_name != group_list[selected_group]:
			continue
		option_button.add_icon_item(resource.get_resource_icon(), resource.get_resource_name(), resources_list.find(resource))
		resource.connect("changed", func():\
			option_button.set_item_icon(resources_list.find(resource), resource.get_resource_icon());\
			option_button.set_item_text(resources_list.find(resource), resource.get_resource_name())\
			#_refresh()
		)
	if current_resource and (current_resource.group_name == group_list[selected_group] or group_list[selected_group] == "All"):
		var current_resource_id : int = resources_list.find(current_resource)
		for i in option_button.item_count:
			if option_button.get_item_id(i) == current_resource_id:
				option_button.select(i)
				break
	else:
		option_button.select(0)
		option_button.item_selected.emit(0)
	
	# Update group options
	group_option_button.clear()
	for group in group_list:
		group_option_button.add_item(group)
	group_option_button.select(selected_group)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data.has_method("get_resource_name")

func _drop_data(at_position: Vector2, data: Variant) -> void:
	current_resource = data
	resource_changed.emit(current_resource)
	var selected_group = group_option_button.selected
	if group_list[selected_group] != "All" and current_resource.group_name != group_list[selected_group]:
		group_option_button.select(0)
	_refresh()
