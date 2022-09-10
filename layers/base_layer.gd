extends Resource
class_name base_layer

enum layer_type {image,project}

@export var image : Sprite2D = Sprite2D.new():
	set(new_image):
		image = new_image
		icon.texture = new_image.texture
		
@export var icon : Sprite2D = Sprite2D.new()
@export var name : String : 
	set(new_name):
		name = new_name
		image.name = name
@export var type : layer_type = layer_type.image
@export var hidden : bool :
	set(new_hidden):
		hidden = new_hidden
		image.visible = !hidden
		
@export var image_path : String


var texture = ImageTexture.new()

func init(image_name: String,path: String,layer_type : layer_type):
	name = image_name
	image_path = path
	type = layer_type

func clear_image():
	if image.get_parent() != null:
		image.get_parent().remove_child(image)

func refresh():
	if !texture.get_image():
		var load_image = Image.load_from_file(image_path)
		texture.set_image(load_image)
		if image:
			image.texture = texture
