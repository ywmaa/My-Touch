extends Resource
class_name base_layer

enum layer_type {brush,image,project,mask}


@export var image : Sprite2D = Sprite2D.new()
		
@export var icon : Sprite2D = Sprite2D.new()

@export var name : String
		
@export var type : layer_type = layer_type.image
@export var hidden : bool :
	set(new_hidden):
		hidden = new_hidden
		if image:
			image.visible = !hidden
		
@export var image_path : String

@export var parent : Node

var texture = ImageTexture.new()

func init(image_name: String,path: String,layer_type : layer_type,_parent : Node):
	name = image_name
	image_path = path
	type = layer_type
	parent = _parent
	refresh()

func clear_image():
	if image.get_parent() != null:
		image.get_parent().remove_child(image)
	parent = null
func draw_image():
	if image.get_parent() != parent:
		if image.get_parent() != null:
			image.get_parent().remove_child(image)
		parent.add_child(image)
func refresh():
	if !texture.get_image():
		var load_image = Image.load_from_file(image_path)
		texture.set_image(load_image)
		if image:
			image.texture = texture
			image.name = name
			icon.texture = texture
