extends base_layer
class_name gradient_layer

## A layer holding one gradient, always editable: drag its handles with the Gradient tool,
## or change its properties in the Layer Inspector.

enum MODE { DRAW, ERASE }
enum SHAPE { LINEAR, RADIAL, REFLECTED }
## The gradient covers the whole layer, the canvas viewport clips it to the canvas size.
const EXTENT := 32768.0

const FILL_SHADER : Shader = preload("res://src/layers/shaders/gradient_fill.gdshader")
const ERASE_SHADER : Shader = preload("res://src/layers/shaders/gradient_erase.gdshader")

var polygon : Polygon2D = Polygon2D.new()

## Start and end in the layer's own space (canvas pixels when the layer isn't moved).
@export var start_point : Vector2 = Vector2.ZERO:
	set(v):
		start_point = v
		_update_gradient()
@export var end_point : Vector2 = Vector2(100, 0):
	set(v):
		end_point = v
		_update_gradient()
@export var start_color : Color = Color.BLACK:
	set(v):
		start_color = v
		_update_gradient()
@export var end_color : Color = Color.WHITE:
	set(v):
		end_color = v
		_update_gradient()
@export var shape : SHAPE = SHAPE.LINEAR:
	set(v):
		shape = v
		_update_gradient()
## Erase fades out the layers below it: fully at the start, not at all at the end
## (strength from the colors' alpha).
@export var mode : MODE = MODE.DRAW:
	set(v):
		mode = v
		_update_gradient()

func _init():
	type = LAYER_TYPE.GRADIENT
	polygon.polygon = PackedVector2Array([
		Vector2(-EXTENT, -EXTENT), Vector2(EXTENT, -EXTENT),
		Vector2(EXTENT, EXTENT), Vector2(-EXTENT, EXTENT),
	])
	polygon.material = ShaderMaterial.new()
	_update_gradient()

func init(_name: String, project: Project, parent_layer: base_layer = null):
	name = _name
	parent_project = project
	if project:
		# Default: across the canvas, left to right
		start_point = Vector2(0, project.canvas_size.y * 0.5)
		end_point = Vector2(project.canvas_size.x, project.canvas_size.y * 0.5)
	refresh()
	parent_project.layers_container.add_layer(self, parent_layer)

func _update_gradient():
	var material := polygon.material as ShaderMaterial
	if material == null:
		return
	material.shader = ERASE_SHADER if mode == MODE.ERASE else FILL_SHADER
	material.set_shader_parameter("start_point", start_point)
	material.set_shader_parameter("end_point", end_point)
	material.set_shader_parameter("start_color", start_color)
	material.set_shader_parameter("end_color", end_color)
	material.set_shader_parameter("shape", shape)
	emit_changed()

func get_inspector_properties() -> Array:
	var PropertiesView : Array = super.get_inspector_properties()
	PropertiesView[1].erase("size") # The gradient has no size of its own
	PropertiesView[0].append("Gradient")
	var PropertiesToShow : Dictionary = {}
	PropertiesToShow["shape,Linear,Radial,Reflected"] = "Gradient"
	PropertiesToShow["mode,Draw,Erase"] = "Gradient"
	PropertiesToShow["start_color"] = "Gradient"
	PropertiesToShow["end_color"] = "Gradient"
	PropertiesToShow["start_point"] = "Gradient"
	PropertiesToShow["end_point"] = "Gradient"
	PropertiesView[1].merge(PropertiesToShow)
	return PropertiesView

func get_canvas_node() -> Node:
	return polygon

func refresh():
	_update_gradient()

func get_size():
	return parent_project.canvas_size if parent_project else Vector2.ZERO

func get_rect() -> Rect2:
	return Rect2(position, get_size())

## The canvas area, where the gradient is visible.
func get_local_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, get_size())

func get_copy(_name: String = "copy"):
	var layer = gradient_layer.new()
	layer.init(_name, parent_project, parent)
	for k in get_inspector_properties()[1].keys(): # Copy Properties
		var property : String = k.get_slice(",", 0).get_slice(":", 0)
		layer.set(property, get(property))
	return layer

## The gradient's start/end in canvas pixels, following the layer's position/rotation/scale.
func point_to_canvas(point: Vector2) -> Vector2:
	if polygon.is_inside_tree():
		return polygon.get_global_transform_with_canvas() * point
	return point

func point_from_canvas(canvas_point: Vector2) -> Vector2:
	if polygon.is_inside_tree():
		return polygon.get_global_transform_with_canvas().affine_inverse() * canvas_point
	return canvas_point
