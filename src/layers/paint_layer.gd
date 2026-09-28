extends base_layer
class_name paint_layer

var canvas : CanvasGroup = CanvasGroup.new()
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
		if stroke.stroke_node and !stroke.stroke_node.get_parent():
			# we need to get it back
			main_object.add_child(stroke.stroke_node)
		if !stroke.need_redraw:
			continue
		if !stroke.stroke_node:
			stroke.stroke_node = stroke._create_stroke_node()
			main_object.add_child(stroke.stroke_node)
		stroke.update_line2D()
		stroke.need_redraw = false


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

## Area covered by the strokes (gradients cover the whole canvas).
func get_local_bounds() -> Rect2:
	var bounds := Rect2()
	var has_bounds := false
	for stroke in strokes:
		if stroke.type == Stroke.TYPE.GRADIANT:
			if parent_project:
				return Rect2(Vector2.ZERO, parent_project.canvas_size)
			continue
		if stroke.mode == Stroke.MODE.ERASE:
			continue
		var half := stroke.size * 0.5
		for point in stroke.points:
			var point_rect := Rect2(point - Vector2(half, half), Vector2(stroke.size, stroke.size))
			bounds = point_rect if !has_bounds else bounds.merge(point_rect)
			has_bounds = true
	return bounds
##	var graph : MTGraph = mt_globals.main_window.get_current_graph_edit()
#	var camera = graph.camera
#	var canvas_position : Vector2 = graph.size/2-camera.offset*(camera.zoom)
#	return Rect2(canvas_position+(main_object.position*camera.zoom)-(Vector2(10,10)*main_object.scale*camera.zoom/2),Vector2(10,10)*main_object.scale*camera.zoom)
