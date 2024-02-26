extends Resource
class_name base_layer

enum LAYER_TYPE {BRUSH, IMAGE, PROJECT, MASK, TEXT, LIGHT, POST_PROCESS, BASE}

var parent_project : Project:
	set(v):
		parent_project = v
		for child in children:
			child.parent_project = parent_project

var main_object : Node = null:
	set(_v):
		pass
	get: return get_canvas_node()

@export var position : Vector2:
	set(v):
		set_position(v)
	get:
		return get_position()
func set_position(v):
	if !main_object:
		return
	main_object.position = v
	emit_changed()

func get_position():
	if !main_object:
		return Vector2.ZERO
	return main_object.position

@export var rotation : float:
	set(v):
		set_rotation(v)
	get:
		return get_rotation()

func set_rotation(v):
	if !main_object:
		return
	main_object.rotation_degrees = v
	emit_changed()

func get_rotation():
	if !main_object:
		return 0.0
	return main_object.rotation_degrees


@export var size : Vector2:
	set(v):
		set_size(v)
	get:
		return get_size()
func set_size(_v):
	return
func get_size():
	if !main_object:
		return Vector2.ZERO
	return main_object.get_rect().size

@export var scale : Vector2:
	set(v):
		set_scale(v)
	get:
		return get_scale()
func set_scale(v):
	if !main_object:
		return
	main_object.scale = v
	emit_changed()
func get_scale():
	if !main_object:
		return Vector2.ZERO
	return main_object.scale


@export var name : String
@export var type : LAYER_TYPE = LAYER_TYPE.BASE
@export var hidden : bool :
	set(new_hidden):
		hidden = new_hidden
		emit_changed()
		if main_object:
			main_object.visible = !hidden
@export var parent: base_layer
@export var children : Array[base_layer]
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

## Init Functions used for creating a new layer out of this layer type
#func init(_name: String, project:Project):
	#name = _name
	#parent_project = project
	#type = LAYER_TYPE.BASE
	#refresh()
	#parent_project.layers_container.add_layer(self)


func get_canvas_node() -> Node:
	printerr("Not implemented: get_canvas_node! (" + get_script().resource_path.get_file() + ")")
	return null

func refresh():
	printerr("Not implemented: refresh! (" + get_script().resource_path.get_file() + ")")
	return null

func get_copy(_name: String = "copy"):
	var layer = base_layer.new()
	layer.init(_name, parent_project)
	return layer


func add_child(child:base_layer):
	if child == self:
		return
	#print("added child", child)
	children.append(child)
	child.parent = self

func remove_child(child:base_layer):
	var index = children.find(child)
	if index == -1:
		return
	remove_child_index(index)

func remove_child_index(index:int):
	children.remove_at(index)


func get_rect() -> Rect2:
	return Rect2(position-(size*scale)/2, size*scale)
