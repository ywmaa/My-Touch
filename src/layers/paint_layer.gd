extends base_layer
class_name paint_layer

var canvas : Node2D = Node2D.new()
@export var strokes: Array[Stroke]
func set_position(_v):
	pass

func set_rotation(_v):
	pass

func set_size(_v):
	pass
func get_size():
	return Vector2.ZERO
func set_scale(_v):
	pass

func init(_name: String, project:Project, parent_layer:base_layer=null):
	name = _name
	parent_project = project
	refresh()
	parent_project.layers_container.add_layer(self, parent_layer)


func _init():
	type = LAYER_TYPE.BRUSH
	affect_children_opacity = true
	main_object.draw.connect(draw)
	main_object.queue_redraw()
	main_object.process_thread_group = Node.PROCESS_THREAD_GROUP_SUB_THREAD
	main_object.process_thread_messages = Node.FLAG_PROCESS_THREAD_MESSAGES_ALL


func draw():
	for stroke in strokes:
		if !stroke.need_redraw:
			continue
		if !stroke.stroke_node:
			stroke.stroke_node = Node2D.new()
		main_object.add_child(stroke.stroke_node)
		stroke.stroke_node.draw.connect(func(): stroke.draw(stroke.stroke_node))
		stroke.stroke_node.queue_redraw()
		stroke.need_redraw = false
		#print("stroke id ", strokes.find(stroke), " redraw")


func get_canvas_node() -> Node:
	if canvas == null:
		return null
	return canvas

func refresh():
	main_object.queue_redraw()

func get_copy(_name: String = "copy"):
	var layer = paint_layer.new()
	layer.init(_name, parent_project, parent)
	for k in get_inspector_properties()[1].keys(): # Copy Properties
		layer.set(k, get(k))
	layer.strokes = strokes.duplicate(true)
	return layer
func get_rect() -> Rect2:
	return Rect2()
##	var graph : MTGraph = mt_globals.main_window.get_current_graph_edit()
#	var camera = graph.camera
#	var canvas_position : Vector2 = graph.size/2-camera.offset*(camera.zoom)
#	return Rect2(canvas_position+(main_object.position*camera.zoom)-(Vector2(10,10)*main_object.scale*camera.zoom/2),Vector2(10,10)*main_object.scale*camera.zoom)
