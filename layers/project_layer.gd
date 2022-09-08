extends base_layer
class_name project_layer

@export var project_layers : Resource

func _init():
	type = layer_type.project

func clear_image():
	for layer in project_layers.layers:
		layer.clear_image()
