extends Resource
class_name resources_manager

@export var resources : Array[base_resource]

signal resources_changed
func add_resource(new_resource:base_resource):
	if !resources.has(new_resource):
		resources.append(new_resource)
		_on_resources_changed()

func remove_resource(resource : base_resource) -> void:
	var resources_array = find_parent_array(resource)
	if resources_array:
		resources_array.erase(resource)
		_on_resources_changed()

func find_resource(name:String):
	for l in resources:
		if l.name == name:
			return l
	return null

func _on_resources_changed() -> void:
	emit_signal("resources_changed")
	ProjectsManager.refresh()

func refresh():
	for resource in resources:
		resource.refresh()

func duplicate_resource(source_resource) -> base_resource:
	source_resource.parent_project = ToolsManager.current_project
	var resource : base_resource = source_resource.get_copy(get_unused_resource_name())
	var undo_redo : UndoRedo = ToolsManager.current_project.undo_redo
	undo_redo.create_action("resource duplication/paste action")
	undo_redo.add_do_method(add_resource.bind(resource))
	
	undo_redo.add_undo_method(remove_resource.bind(resource))
	undo_redo.commit_action(true)
	return resource


func find_parent_array(resource : base_resource, resource_array : Array = resources):
	if resource_array.has(resource):
		return resource_array
	return null

func get_unused_resource_name() -> String:
	var naming = "new_resource"
	var return_name : String
	var count = 0
	return_name = naming
	for resource in resources:
		if resource.name == return_name:
			count += 1
		if count > 0:
			return_name = naming + " " + str(count)
	return return_name
