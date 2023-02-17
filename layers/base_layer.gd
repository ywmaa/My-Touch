extends Resource
class_name base_layer

enum layer_type {brush, image, project, mask, text, light, postprocess, primitive_shape}

var main_object : Node = null
@export var image : Sprite2D = Sprite2D.new()

@export var icon : Sprite2D = Sprite2D.new()

@export var name : String

@export var type : layer_type = layer_type.image
@export var hidden : bool :
	set(new_hidden):
		hidden = new_hidden
		if main_object:
			main_object.visible = !hidden
		
@export_global_dir var image_path : String

var parent : Node


@export var opacity : float:
	set(new_opacity):
		new_opacity = clamp(new_opacity,0.0,1.0)
		if main_object:
			if affect_children_opacity:
				main_object.modulate.a = new_opacity
			main_object.self_modulate.a = new_opacity
		opacity = new_opacity
	get:
		if main_object:
			if affect_children_opacity:
				return main_object.modulate.a
			return main_object.self_modulate.a
		
		return opacity

@export var lock_aspect : bool = false
@export var affect_children_opacity :bool = false

var texture = ImageTexture.new()

func init(_name: String,path: String,layer_type : layer_type,_parent : Node):
	name = _name
	image_path = path
	type = layer_type
	parent = _parent
	main_object = image
	refresh()

func clear_image():
	if image == null:
		return
	if image.get_parent() != null:
		image.get_parent().remove_child(image)
	parent = null
func draw_image():
	if image == null:
		return
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
			main_object = image

func get_copy(_name: String = "copy"):
	var layer = base_layer.new()
	layer.init(_name,image_path,type,parent)
	return layer
