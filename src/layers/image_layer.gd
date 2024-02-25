extends base_layer
class_name image_layer

var image : Sprite2D = Sprite2D.new()
@export var image_path : String
var texture = ImageTexture.new()

func init(_name: String, path: String, project:Project, parent_layer:base_layer=null):
	name = _name
	image_path = path
	parent_project = project
	refresh()
	parent_project.layers_container.add_layer(self, parent_layer)

func _init():
	type = LAYER_TYPE.IMAGE

func get_canvas_node() -> Node:
	if image == null:
		return null
	return image

func refresh():
	if !texture.get_image() and parent_project:
		var load_image = Image.load_from_file(parent_project.project_folder_abs_path + "/" + image_path)
		texture.set_image(load_image)
		if image:
			image.texture = texture
			image.name = name

func get_copy(_name: String = "copy"):
	var layer = image_layer.new()
	layer.init(_name, image_path, parent_project, parent)
	for k in get_layer_inspector_properties()[1].keys(): # Copy Properties
		layer.set(k, get(k))
	return layer
