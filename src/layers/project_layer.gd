extends base_layer
class_name project_layer

var root_node : Node2D
@export var project_path : String
var project : Project# = layers_manager.new()

func init(p_name: String, p_path: String, p_project:Project):
	name = p_name
	project_path = p_path
	parent_project = p_project
	refresh()

func _init():
	type = LAYER_TYPE.PROJECT
	affect_children_opacity = true

func get_canvas_node() -> Node:
	if root_node == null:
		return null
	return root_node

func refresh():
	if project:
		return
	var data = ResourceLoader.load(name,"",ResourceLoader.CACHE_MODE_REUSE) as Project
	if data != null:
		project = data

func get_copy(_name: String = "copy"):
	var layer = project_layer.new()
	layer.init(name, project_path, project)
	for k in get_layer_inspector_properties()[1].keys(): # Copy Properties
		layer.set(k, get(k))
	return layer
