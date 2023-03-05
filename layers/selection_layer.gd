extends base_layer
class_name selection_layer


func init(_name: String,_path: String,p_layer_type : layer_type,_parent : Node):
	name = _name
	type = p_layer_type
	parent = _parent
	refresh()

func _init():
	type = layer_type.mask
	affect_children_opacity = true
	image = shape_generator.new()

func clear_image():
	super.clear_image()

func draw_image():
	super.draw_image()

func refresh():
	super.refresh()

func get_rect() -> Rect2:
	var graph : MTGraph = mt_globals.main_window.get_current_graph_edit()
	var camera = graph.camera
	var canvas_position : Vector2 = graph.size/2-camera.offset*(camera.zoom)
	return Rect2(canvas_position+(main_object.position*camera.zoom)-(Vector2(10,10)*main_object.scale*camera.zoom/2),Vector2(10,10)*main_object.scale*camera.zoom)
