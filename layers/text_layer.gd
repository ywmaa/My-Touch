extends base_layer
class_name text_layer


var default_icon = preload("res://icon.png")
@export var text_label : RichTextLabel = RichTextLabel.new()


# we don't need an image or texture so we will override everything 
# and reset all images and textures to free memory
func init(_name: String,path: String,layer_type : layer_type,_parent : Node):
	name = _name
	type = layer_type
	parent = _parent
	main_object = text_label
	text_label.text = "Hello World" #Default Text
	text_label.fit_content = true
	text_label.autowrap_mode = 0
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

func draw_image():
	if text_label.get_parent() != parent:
		if text_label.get_parent() != null:
			text_label.get_parent().remove_child(image)
		parent.add_child(text_label)
func refresh():
	main_object = text_label

func get_copy(_name: String = "copy"):
	var layer = text_layer.new()
	layer.init(_name,image_path,type,parent)
	return layer
