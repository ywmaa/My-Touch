extends base_layer
class_name text_layer


var default_icon = preload("res://icon.png")
@export var text_label : RichTextLabel = RichTextLabel.new()

func set_position(v):
	if !text_label:
		return
	text_label.position = v
	emit_changed()
func get_position():
	if !text_label:
		return Vector2.ZERO
	return text_label.position

func set_rotation(v):
	if !text_label:
		return
	text_label.rotation_degrees = v
	emit_changed()
func get_rotation():
	if !text_label:
		return 0.0
	return text_label.rotation_degrees

func set_size(v):
	return
func get_size():
	if !text_label:
		return Vector2.ZERO
	return text_label.get_rect().size

func set_scale(v):
	if !text_label:
		return
	text_label.scale = v
	emit_changed()
func get_scale():
	if !text_label:
		return Vector2.ZERO
	return text_label.scale
var text : String:
	set(v):
		text_label.text = v
	get:
		return text_label.text


func get_layer_inspector_properties() -> Array:
	var PropertiesView : Array = super.get_layer_inspector_properties()
	PropertiesView[0].append("Text Properties")
	var PropertiesToShow : Dictionary
	PropertiesToShow["text"] = "Text Properties"
	PropertiesView[1].merge(PropertiesToShow)
	return PropertiesView

# we don't need an image or texture so we will override everything 
# and reset all images and textures to free memory
func init(_name: String,_path: String,p_layer_type : layer_type,_parent : Node):
	name = _name
	type = p_layer_type
	parent = _parent
	main_object = text_label
	text_label.text = "Hello World" #Default Text
	text_label.fit_content = true
	text_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	text_label.bbcode_enabled = true
	refresh()

func _init():
	type = layer_type.text
	main_object = text_label
	affect_children_opacity = true
	image = null
	texture = null
	

func clear_image():
	if text_label.get_parent() != null:
		text_label.get_parent().remove_child(text_label)
	parent = null
#	extents.my_layer = null

func draw_image():
	if text_label.get_parent() != parent:
		if text_label.get_parent() != null:
			text_label.get_parent().remove_child(image)
		parent.add_child(text_label)
#		text_label.add_child(extents)
#	extents.offset = Vector2(text_label.get_content_width()/2,text_label.get_content_height()/2)
#	if extents.dragged_anchor.is_empty():
#		extents.size = Vector2(text_label.get_content_width(),text_label.get_content_height())
#	extents.my_layer = self
func refresh():
	main_object = text_label

func get_copy(_name: String = "copy"):
	var layer = text_layer.new()
	layer.init(_name,image_path,type,parent)
	return layer

func get_rect() -> Rect2:
	var text_size = Vector2(text_label.get_content_width(),text_label.get_content_height())
	var graph : MTGraph = mt_globals.main_window.get_current_graph_edit()
	var camera = graph.camera
	var canvas_position : Vector2 = graph.size/2-camera.offset*(camera.zoom)
	return Rect2(canvas_position+(main_object.position*camera.zoom),text_size*main_object.scale*camera.zoom)
