extends base_layer
class_name text_layer

var text_label : RichTextLabel = RichTextLabel.new()

@export var text : String:
	set(v):
		text_label.text = v
		emit_changed()
	get:
		return text_label.text


func get_layer_inspector_properties() -> Array:
	var PropertiesView : Array = super.get_layer_inspector_properties()
	PropertiesView[0].append("Text Properties")
	var PropertiesToShow : Dictionary = {}
	PropertiesToShow["text"] = "Text Properties"
	PropertiesView[1].merge(PropertiesToShow)
	return PropertiesView

func init(_name: String, project:Project, parent_layer:base_layer=null):
	name = _name
	parent_project = project
	text_label.text = "Hello World" #Default Text
	refresh()
	parent_project.layers_container.add_layer(self, parent_layer)

func _init():
	type = LAYER_TYPE.TEXT
	affect_children_opacity = true
	text_label.fit_content = true
	text_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	text_label.bbcode_enabled = true
	

func get_canvas_node() -> Node:
	if text_label == null:
		return null
	return text_label

func refresh():
	pass

func get_copy(_name: String = "copy"):
	var layer = text_layer.new()
	layer.init(_name, parent_project, parent)
	for k in get_layer_inspector_properties()[1].keys(): # Copy Properties
		layer.set(k, get(k))
	return layer

func get_rect() -> Rect2:
	var text_size = Vector2(text_label.get_content_width(),text_label.get_content_height())
	var graph : MTGraph = mt_globals.main_window.get_current_graph_edit()
	var camera = graph.camera
	var canvas_position : Vector2 = graph.size/2-camera.offset*(camera.zoom)
	return Rect2(canvas_position+(main_object.position*camera.zoom),text_size*main_object.scale*camera.zoom)
