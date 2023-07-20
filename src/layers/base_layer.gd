extends Resource
class_name base_layer

enum layer_type {brush, image, project, mask, text, light, postprocess}

var main_object : Node = null
@export var image : Sprite2D = Sprite2D.new()
var position : Vector2:
	set(v):
		set_position(v)
	get:
		return get_position()
func set_position(v):
	if !image:
		return
	image.position = v
	emit_changed()
func get_position():
	if !image:
		return Vector2.ZERO
	return image.position

var rotation : float:
	set(v):
		set_rotation(v)
	get:
		return get_rotation()
func set_rotation(v):
	if !image:
		return
	image.rotation_degrees = v
	emit_changed()
func get_rotation():
	if !image:
		return 0.0
	return image.rotation_degrees


var size : Vector2:
	set(v):
		set_size(v)
	get:
		return get_size()
func set_size(v):
	return
func get_size():
	if !image:
		return Vector2.ZERO
	return image.get_rect().size

var scale : Vector2:
	set(v):
		set_scale(v)
	get:
		return get_scale()
func set_scale(v):
	if !image:
		return
	image.scale = v
	emit_changed()
func get_scale():
	if !image:
		return Vector2.ZERO
	return image.scale


@export var name : String

@export var type : layer_type = layer_type.image
@export var hidden : bool :
	set(new_hidden):
		hidden = new_hidden
		emit_changed()
		if main_object:
			main_object.visible = !hidden
		
@export_global_dir var image_path : String

#@export var extents : RectExtents = RectExtents.new()

#var parent : Node


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

func get_layer_inspector_properties() -> Array:
	var PropertiesView : Array = []
	var PropertiesGroups : Array[String] = []
	PropertiesGroups.append("Transform")
	PropertiesGroups.append("Visibility")
	var PropertiesToShow : Dictionary = {}
	PropertiesToShow["position"] = "Transform"
	PropertiesToShow["rotation"] = "Transform"
	PropertiesToShow["size"] = "Transform"
	PropertiesToShow["scale"] = "Transform"
	PropertiesToShow["lock_aspect"] = "Transform"
	
	PropertiesToShow["opacity"] = "Visibility"
	PropertiesToShow["affect_children_opacity"] = "Visibility"
	
	
	PropertiesView.append(PropertiesGroups)
	PropertiesView.append(PropertiesToShow)
	return PropertiesView

func init(_name: String, path: String, p_layer_type : layer_type):
	name = _name
	image_path = path
	type = p_layer_type
	main_object = image
	refresh()


func get_image() -> Node:
	refresh()
	if main_object == null:
		return null
	return main_object
func refresh():
	if !texture.get_image():
		var load_image = Image.load_from_file(image_path)
		texture.set_image(load_image)
		if image:
			image.texture = texture
			image.name = name
			main_object = image

func get_copy(_name: String = "copy"):
	var layer = base_layer.new()
	layer.init(_name,image_path,type)
	return layer

#Used to get rect relative to the real viewport
#func get_rect() -> Rect2:
#	var graph : MTGraph = mt_globals.main_window.get_current_graph_edit()
#	var camera = graph.camera
#	var canvas_position : Vector2 = graph.size/2-camera.offset*(camera.zoom)
#	return Rect2(canvas_position+(main_object.position*camera.zoom)-(main_object.get_rect().size*main_object.scale*camera.zoom/2),main_object.get_rect().size*main_object.scale*camera.zoom)
