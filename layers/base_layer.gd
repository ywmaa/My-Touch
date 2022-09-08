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
		



func clear_image():
	image.queue_free()
