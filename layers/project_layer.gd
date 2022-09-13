extends base_layer
class_name project_layer
#replace with preload
var default_icon = load("res://icon.png")
@export var project_layers : Resource

func _init():
	type = layer_type.project

func clear_image():
	super.clear_image()
	for layer in project_layers.layers:
		layer.clear_image()

func refresh():
	image.texture = default_icon
	project_layers.canvas = image
	var data = ResourceLoader.load(name) as SaveProject
	if data != null:
		for layer in project_layers.layers:
			project_layers.remove_layer(layer)
		for layer in data.layers.layers:
			project_layers.add_layer(layer)
		project_layers.load_layers()
