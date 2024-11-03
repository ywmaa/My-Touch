extends Resource
class_name Stroke

enum TYPE {CIRCLE, LINE, TEXTURE}
enum COLOR_MODE {MONO, GRADIANT}
enum MODE {DRAW, ERASE}
@export var type : TYPE = TYPE.CIRCLE
@export var mode : MODE = MODE.DRAW
@export var points : PackedVector2Array = []
@export var size : float
@export var color : Color# = Color.BLACK
#@export var texture : Texture2D
@export var aliasing : bool
var stroke_node: Line2D = Line2D.new()
var need_redraw: bool = true
var erase_material : Material = preload("res://src/layers/shaders/erase_material.tres")

func add_point(p_point:Vector2, p_color:Color, p_size:float):
	if points.has(p_point):
		return
	color = p_color
	size = p_size*2
	match type:
		TYPE.CIRCLE:
			points.append(p_point)
		TYPE.LINE:
			points.append(p_point)
	update()
func remove_point(index:int):
	match type:
		TYPE.CIRCLE:
			points.remove_at(index)
		TYPE.LINE:
			points.remove_at(index)
			if index-1 == -1:
				return
	update()

func update():
	update_line2D()

func update_line2D():
	match mode:
		MODE.DRAW:
			stroke_node.material = null
		MODE.ERASE:
			stroke_node.material = erase_material
			stroke_node.self_modulate = color
	match type:
		TYPE.CIRCLE:
			stroke_node.points = points
			stroke_node.width = size
			stroke_node.default_color = color
			stroke_node.joint_mode = Line2D.LINE_JOINT_ROUND
			stroke_node.end_cap_mode = Line2D.LINE_CAP_ROUND
			stroke_node.begin_cap_mode = Line2D.LINE_CAP_ROUND
			stroke_node.round_precision = 32
		TYPE.LINE:
			stroke_node.points = points
			stroke_node.width = size
			stroke_node.default_color = color
			stroke_node.joint_mode = Line2D.LINE_JOINT_SHARP
			stroke_node.end_cap_mode = Line2D.LINE_CAP_BOX
			stroke_node.begin_cap_mode = Line2D.LINE_CAP_BOX

func draw(draw_node: CanvasItem, starting_index:int=0):
	pass
