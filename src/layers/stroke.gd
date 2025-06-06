extends Resource
class_name Stroke

enum TYPE {CIRCLE, LINE, TEXTURE}
enum COLOR_MODE {MONO, GRADIANT}
enum MODE {DRAW, ERASE}
@export var type : TYPE = TYPE.CIRCLE
@export var mode : MODE = MODE.DRAW
@export var points : PackedVector2Array = []
@export var size : PackedFloat32Array = []
@export var color : PackedColorArray = []# = Color.BLACK
@export var texture : Texture2D
@export var aliasing : bool
var stroke_node: Line2D = Line2D.new()
var size_curve: Curve = Curve.new()
var color_gradiant: Gradient = Gradient.new()
var need_redraw: bool = true
var erase_material : Material = preload("res://src/layers/shaders/erase_material.tres")

func add_point(p_point:Vector2, p_color:Color, p_size:float):
	if points.has(p_point):
		return
	match type:
		TYPE.CIRCLE:
			points.append(p_point)
			size.append(p_size*2)
			color.append(p_color)
		TYPE.LINE:
			points.append(p_point)
			size.append(p_size*2)
			color.append(p_color)

	update()
func remove_point(index:int):
	match type:
		TYPE.CIRCLE:
			points.remove_at(index)
			size.remove_at(index)
			color.remove_at(index)
		TYPE.LINE:
			points.remove_at(index)
			size.remove_at(index)
			color.remove_at(index)
			if index-1 == -1:
				return
	update()

func update():
	update_line2D()

func update_line2D():
	size_curve.clear_points()
	color_gradiant.offsets.clear()
	color_gradiant.colors = color
	size_curve.max_value = INF
	size_curve.max_domain = INF
	var max_size_length : int = size.size()-1
	
	for i in size.size():
		size_curve.add_point( Vector2( ( float(i) / float(max_size_length) ), size[i]) )
		color_gradiant.offsets.append( float(i) / float(max_size_length) )
	
	stroke_node.width = 1.0
	stroke_node.width_curve =  size_curve
	stroke_node.gradient =  color_gradiant
	match mode:
		MODE.DRAW:
			stroke_node.material = null
		MODE.ERASE:
			stroke_node.material = erase_material
			#stroke_node.self_modulate = color
	match type:
		TYPE.CIRCLE:
			stroke_node.points = points
			stroke_node.joint_mode = Line2D.LINE_JOINT_ROUND
			stroke_node.end_cap_mode = Line2D.LINE_CAP_ROUND
			stroke_node.begin_cap_mode = Line2D.LINE_CAP_ROUND
			stroke_node.round_precision = 32
		TYPE.LINE:
			stroke_node.points = points
			stroke_node.joint_mode = Line2D.LINE_JOINT_SHARP
			stroke_node.end_cap_mode = Line2D.LINE_CAP_BOX
			stroke_node.begin_cap_mode = Line2D.LINE_CAP_BOX

func draw(draw_node: CanvasItem, starting_index:int=0):
	pass
