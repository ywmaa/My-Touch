extends image_layer
class_name selection_layer
var color : Color:
	set(v):
		image.color = v
		emit_changed()
	get:
		return image.color

var shape : shape_generator.shape_type:
	set(v):
		image.shape = v
		emit_changed()
	get:
		return image.shape

var shader : shape_generator.shader_type:
	set(v):
		image.shader = v
		emit_changed()
	get:
		return image.shader

func get_inspector_properties() -> Array:
	var PropertiesView : Array = super.get_inspector_properties()
	PropertiesView[0].append("Shape Properties")
	var PropertiesToShow : Dictionary = {}
	PropertiesToShow["color"] = "Shape Properties"
	PropertiesToShow["shape,square,circle,polygon"] = "Shape Properties"
	PropertiesToShow["shader,fill,border,image,mask,custom"] = "Shape Properties"
	PropertiesView[1].merge(PropertiesToShow)
	return PropertiesView

#func init(_name: String,_path: String, project:Project):
	#name = _name
	#parent_project = project
	#refresh()
	#parent_project.layers_container.add_layer(self)

func _init():
	type = LAYER_TYPE.MASK
	affect_children_opacity = true
	image = shape_generator.new()


func get_rect() -> Rect2:
	var graph : MTGraph = mt_globals.main_window.get_current_graph_edit()
	var camera = graph.camera
	var canvas_position : Vector2 = graph.size/2-camera.offset*(camera.zoom)
	return Rect2(canvas_position+(main_object.position*camera.zoom)-(Vector2(10,10)*main_object.scale*camera.zoom/2),Vector2(10,10)*main_object.scale*camera.zoom)
