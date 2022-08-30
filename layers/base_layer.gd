extends Resource
class_name base_layer

enum layer_type {image}

var image : Sprite2D = Sprite2D.new():
	set(new_image):
		image = new_image
		icon.texture = new_image.texture
		
var icon : Sprite2D = Sprite2D.new()
var name : String : 
	set(new_name):
		name = new_name
		image.name = name
var type : layer_type = layer_type.image
var hidden : bool :
	set(new_hidden):
		hidden = new_hidden
		image.visible = !hidden
		
