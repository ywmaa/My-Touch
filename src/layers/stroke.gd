extends Resource
class_name Stroke

enum TYPE {CIRCLE, LINE, RECTANGLE, TEXTURE, PIXEL}
@export var type : TYPE = TYPE.CIRCLE
@export var points : PackedVector2Array = []
@export var size : PackedFloat32Array #= 1.0
@export var color : PackedColorArray# = Color.BLACK
#@export var texture : Texture2D
@export var aliasing : bool
var stroke_node: Node2D = Node2D.new()
var need_redraw: bool = true

func add_point(p_point:Vector2, p_color:Color, p_size:float):
	if points.has(p_point):
		return
	match type:
		TYPE.CIRCLE:
			points.append(p_point)
			size.append(p_size)
			color.append(p_color)
		TYPE.LINE:
			points.append(p_point)
			size.append(p_size)
			color.append(p_color)
		TYPE.PIXEL:
			points.append(p_point)
			color.append(p_color)

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
			size[index-1] = 0
		TYPE.PIXEL:
			points.remove_at(index)
			color.remove_at(index)

func draw(draw_node: CanvasItem, starting_index:int=0):
	match type:
		TYPE.CIRCLE:
			for i in points.size():
				if i < starting_index:
					continue
				draw_node.draw_circle(points[i], size[i], color[i])
		TYPE.LINE:
			for i in points.size():
				if i < starting_index:
					continue
				var next_point = i+1 if i < points.size()-1 else i
				draw_node.draw_line(points[i], points[next_point], color[i], size[i], aliasing)
		TYPE.TEXTURE:
			for i in points.size():
				pass
				#draw_node.draw_texture_rect_region(texture, points[i], color[i])
		TYPE.PIXEL:
			for i in points.size():
				if i < starting_index:
					continue
				draw_node.draw_rect(Rect2(points[i], Vector2.ONE), color[i])
