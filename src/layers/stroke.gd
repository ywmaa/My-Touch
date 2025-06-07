extends Resource
class_name Stroke

enum TYPE {CIRCLE, LINE, TEXTURE, GRADIANT}
enum MODE {DRAW, ERASE}
@export var type : TYPE = TYPE.CIRCLE
@export var mode : MODE = MODE.DRAW
@export var points : PackedVector2Array = []
@export var size : float
@export var size_pressure : PackedFloat32Array = []
@export var color : PackedColorArray = []# = Color.BLACK
@export var custom_texture : brush_texture_resource
@export var aliasing : bool
var stroke_node: Line2D = Line2D.new()
var size_curve: Curve = Curve.new()
var color_gradiant: Gradient = Gradient.new()
var need_redraw: bool = true
var erase_material : Material = preload("res://src/layers/shaders/erase_material.tres")
var texture_material : Material = preload("res://src/layers/shaders/texture_material.tres")
var texture_erase_material : Material = preload("res://src/layers/shaders/texture_erase_material.tres")

func add_point(p_point:Vector2, p_color:Color, p_brush_size:float, size_relative: float):
	if points.has(p_point):
		return
	match type:
		TYPE.CIRCLE:
			points.append(p_point)
			size = p_brush_size*2
			size_pressure.append(size_relative)
			color.append(p_color)
		TYPE.LINE:
			size = p_brush_size*2
			points.append(p_point)
			size_pressure.append(size_relative)
			color.append(p_color)
		TYPE.TEXTURE:
			size = p_brush_size*2
			points.append(p_point)
			size_pressure.append(size_relative)
			color.append(p_color)

	update()
func remove_point(index:int):
	match type:
		TYPE.CIRCLE:
			points.remove_at(index)
			size_pressure.remove_at(index)
			color.remove_at(index)
		TYPE.LINE:
			points.remove_at(index)
			size_pressure.remove_at(index)
			color.remove_at(index)
			if index-1 == -1:
				return
		TYPE.TEXTURE:
			points.remove_at(index)
			size_pressure.remove_at(index)
			color.remove_at(index)
	update()

func update():
	update_line2D()

func update_line2D():
	size_curve.clear_points()
	color_gradiant.offsets.clear()
	color_gradiant.colors = color
	size_curve.max_value = 1.0
	size_curve.max_domain = 1.0
	var max_size_length : int = size_pressure.size()-1
	size
	for i in size_pressure.size():
		size_curve.add_point( Vector2( ( float(i) / float(max_size_length) ), size_pressure[i]) )
		color_gradiant.offsets.append( float(i) / float(max_size_length) )
	
	stroke_node.width = size
	stroke_node.width_curve =  size_curve
	stroke_node.gradient =  color_gradiant
	match mode:
		MODE.DRAW:
			if type == TYPE.TEXTURE:
				stroke_node.material = texture_material.duplicate()
			else:
				stroke_node.material = null
		MODE.ERASE:
			if type == TYPE.TEXTURE:
				stroke_node.material = texture_erase_material.duplicate()
			else:
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
		TYPE.TEXTURE:
			stroke_node.points = points
			stroke_node.texture = custom_texture.texture
			stroke_node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			stroke_node.texture_mode = Line2D.LINE_TEXTURE_TILE
			if !color.is_empty() and mode != MODE.ERASE:
				stroke_node.material.set_shader_parameter("texture_color", color[0])
			#stroke_node.round_precision = 32

func draw(draw_node: CanvasItem, starting_index:int=0):
	pass
