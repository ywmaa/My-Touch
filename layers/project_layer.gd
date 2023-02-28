extends base_layer
class_name project_layer


var project_layers : layers_object = layers_object.new()


func _init():
	type = layer_type.project
	affect_children_opacity = true

func clear_image():
	super.clear_image()
	for layer in project_layers.layers:
		layer.clear_image()

func draw_image():
	super.draw_image()
	for layer in project_layers.layers:
		layer.parent = image
		layer.draw_image()

func refresh():
	super.refresh()
	project_layers.canvas = image
	var data = ResourceLoader.load(name,"",ResourceLoader.CACHE_MODE_REUSE) as SaveProject
	if data != null:
		if project_layers.layers != data.layers.layers:
			project_layers.unload_layers()
			project_layers.layers = data.layers.layers
			project_layers.load_layers()
		main_object = image

func get_copy(_name: String = "copy"):
	var layer = project_layer.new()
	layer.init(name,image_path,type,parent)
	return layer
