extends base_layer
class_name project_layer


var project : Project# = layers_manager.new()


func _init():
	type = layer_type.project
	affect_children_opacity = true
	refresh()


func refresh():
	super.refresh()
	if project:
		return
	var data = ResourceLoader.load(name,"",ResourceLoader.CACHE_MODE_REUSE) as Project
	if data != null:
		project = data
		main_object = image

func get_copy(_name: String = "copy"):
	var layer = project_layer.new()
	layer.init(name,image_path,type)
	return layer
