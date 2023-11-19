extends Sprite2D
class_name shape_generator

enum shader_type {fill,border,image,mask,custom}
enum shape_type {square,circle,polygon}
@export var shader : shader_type = shader_type.fill
@export var shape : shape_type = shape_type.square
@export var color : Color = Color.WHITE:
	get: return color
	set(new_color):
		color = new_color
		if material:
			material.set_shader_parameter("Color",color)
@export var polygon : Polygon2D = Polygon2D.new()
var fill_shader = preload("res://src/layers/shaders/Fill.tres")


func _ready():
	material = ShaderMaterial.new()
	material.set_shader_parameter("Color",color)
	polygon.polygon.append(Vector2(0,0))
	polygon.polygon.append(Vector2(50,100))
	polygon.polygon.append(Vector2(300,400))
	polygon.polygon.append(Vector2(900,500))
	
	
func _process(_delta):
	queue_redraw()


func _draw():
	match shader:
		shader_type.fill:
			material.shader = fill_shader
		shader_type.border:
			material.shader = fill_shader
		shader_type.image:
			material.shader = null
		shader_type.custom:
			pass
	match shape:
		shape_type.square:
			draw_rect(Rect2(Vector2(-5.0,-5.0),Vector2(10,10)),color,shader == shader_type.fill)
		shape_type.circle:
			if shader == shader_type.fill:
				draw_circle(Vector2(0.0,0.0),10,color)
			if shader == shader_type.border:
				draw_arc(Vector2(0.0,0.0),10,0,PI*2,1000,color)
		shape_type.polygon:
			if !polygon:
				return
			if polygon.get_parent() == null:
				add_child(polygon)
			



