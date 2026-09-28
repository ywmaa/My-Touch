extends Resource
class_name Stroke

enum TYPE {CIRCLE, LINE, TEXTURE, GRADIANT}
enum MODE {DRAW, ERASE}
enum GRADIENT_SHAPE {LINEAR, RADIAL, REFLECTED}
## Gradients cover the whole layer, the canvas viewport clips them to the canvas size.
const GRADIENT_EXTENT := 32768.0
@export var type : TYPE = TYPE.CIRCLE:
	set(v):
		type = v
		# Gradients are drawn by a polygon with a shader instead of a line
		if (type == TYPE.GRADIANT) != (stroke_node is Polygon2D):
			_replace_stroke_node(_create_stroke_node())
@export var mode : MODE = MODE.DRAW
## Only used by gradients, points[0] is the start and points[1] the end.
@export var gradient_shape : GRADIENT_SHAPE = GRADIENT_SHAPE.LINEAR
@export var points : PackedVector2Array = []
@export var size : float
@export var size_pressure : PackedFloat32Array = []
@export var color : PackedColorArray = []# = Color.BLACK
@export var custom_texture : brush_texture_resource
@export var aliasing : bool
var stroke_node: Node2D = Line2D.new()
var size_curve: Curve = Curve.new()
var color_gradiant: Gradient = Gradient.new()
var need_redraw: bool = true
var erase_material : Material = preload("res://src/layers/shaders/erase_material.tres")
var texture_material : Material = preload("res://src/layers/shaders/texture_material.tres")
var texture_erase_material : Material = preload("res://src/layers/shaders/texture_erase_material.tres")
const gradient_fill_shader : Shader = preload("res://src/layers/shaders/gradient_fill.gdshader")
const gradient_erase_shader : Shader = preload("res://src/layers/shaders/gradient_erase.gdshader")

func _create_stroke_node() -> Node2D:
	if type == TYPE.GRADIANT:
		var polygon := Polygon2D.new()
		polygon.polygon = PackedVector2Array([
			Vector2(-GRADIENT_EXTENT, -GRADIENT_EXTENT), Vector2(GRADIENT_EXTENT, -GRADIENT_EXTENT),
			Vector2(GRADIENT_EXTENT, GRADIENT_EXTENT), Vector2(-GRADIENT_EXTENT, GRADIENT_EXTENT),
		])
		polygon.material = ShaderMaterial.new()
		return polygon
	return Line2D.new()

## Swaps the node, keeping its place in the layer if it was already added.
func _replace_stroke_node(new_node: Node2D) -> void:
	var old_node := stroke_node
	stroke_node = new_node
	if old_node == null:
		return
	var parent := old_node.get_parent()
	if parent:
		var index := old_node.get_index()
		parent.remove_child(old_node)
		parent.add_child(new_node)
		parent.move_child(new_node, index)
	old_node.queue_free()

func set_gradient(p_start: Vector2, p_end: Vector2, p_start_color: Color, p_end_color: Color):
	points = PackedVector2Array([p_start, p_end])
	color = PackedColorArray([p_start_color, p_end_color])
	update()

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

func update_gradient():
	if points.size() < 2 or color.size() < 2:
		stroke_node.visible = false
		return
	stroke_node.visible = true
	var material := stroke_node.material as ShaderMaterial
	material.shader = gradient_erase_shader if mode == MODE.ERASE else gradient_fill_shader
	material.set_shader_parameter("start_point", points[0])
	material.set_shader_parameter("end_point", points[1])
	material.set_shader_parameter("start_color", color[0])
	material.set_shader_parameter("end_color", color[1])
	material.set_shader_parameter("shape", gradient_shape)

func update_line2D():
	if type == TYPE.GRADIANT:
		update_gradient()
		return
	var line := stroke_node as Line2D
	size_curve.clear_points()
	size_curve.max_value = 1.0
	size_curve.max_domain = 1.0
	var max_size_length : int = max(size_pressure.size()-1, 1)
	# offsets is returned by value, so build it and assign it once.
	var offsets : PackedFloat32Array = []
	for i in size_pressure.size():
		size_curve.add_point( Vector2( ( float(i) / float(max_size_length) ), size_pressure[i]) )
		offsets.append( float(i) / float(max_size_length) )
	color_gradiant.colors = color
	color_gradiant.offsets = offsets

	line.width = size
	line.width_curve =  size_curve
	line.gradient = color_gradiant
	match mode:
		MODE.DRAW:
			if type == TYPE.TEXTURE:
				line.material = texture_material.duplicate()
			else:
				line.material = null
		MODE.ERASE:
			if type == TYPE.TEXTURE:
				line.material = texture_erase_material.duplicate()
			else:
				line.material = erase_material
			#line.self_modulate = color
	match type:
		TYPE.CIRCLE:
			line.points = points
			line.joint_mode = Line2D.LINE_JOINT_ROUND
			line.end_cap_mode = Line2D.LINE_CAP_ROUND
			line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			line.round_precision = 32
		TYPE.LINE:
			line.points = points
			line.joint_mode = Line2D.LINE_JOINT_SHARP
			line.end_cap_mode = Line2D.LINE_CAP_BOX
			line.begin_cap_mode = Line2D.LINE_CAP_BOX
		TYPE.TEXTURE:
			line.points = points
			line.texture = custom_texture.texture
			line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			line.texture_mode = Line2D.LINE_TEXTURE_TILE
			if !color.is_empty() and mode != MODE.ERASE:
				line.material.set_shader_parameter("texture_color", color[0])
			#line.round_precision = 32

func draw(draw_node: CanvasItem, starting_index:int=0):
	pass
