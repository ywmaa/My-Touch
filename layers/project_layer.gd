extends base_layer
class_name project_layer
var default_icon = preload("res://icon.png")
@export var project_layers : Resource

func _init():
	type = layer_type.project

func clear_image():
	for layer in project_layers.layers:
		project_layers.layers.erase(layer)
		layer.clear_image()

func refresh():
	image.texture = default_icon
	project_layers.canvas = image
	var data = ResourceLoader.load(name) as SaveProject
	if data != null:
		project_layers.layers = data.layers.layers
		project_layers.load_layers()
