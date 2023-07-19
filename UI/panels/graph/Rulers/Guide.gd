class_name Guide
extends Line2D

enum Types { HORIZONTAL, VERTICAL }

const INPUT_WIDTH := 4

var font := preload("res://UI/theme/font.tres")
var has_focus := true
var mouse_pos := Vector2.ZERO
var type: int = Types.HORIZONTAL
var project = mt_globals.main_window.get_current_graph_edit()


func _ready() -> void:
	width = mt_globals.main_window.get_current_graph_edit().camera.zoom.x * 2
	default_color = mt_globals.guide_color
#	project.guides.append(self)
	if outside_canvas():
		modulate.a = 0.5


func _input(_event: InputEvent) -> void:
	if !visible:
		return
	var tmp_transform = get_canvas_transform().affine_inverse()
	var tmp_position = mt_globals.main_window.get_current_graph_edit().viewport.get_local_mouse_position()
	mouse_pos = tmp_transform.basis_xform(tmp_position) + tmp_transform.origin

	var point0 := points[0]
	var point1 := points[1]
	if type == Types.HORIZONTAL:
		point0.y -= width * INPUT_WIDTH
		point1.y += width * INPUT_WIDTH
	else:
		point0.x -= width * INPUT_WIDTH
		point1.x += width * INPUT_WIDTH
	if (
		mt_globals.can_draw
		and mt_globals.main_window.get_current_graph_edit().has_focus
		and point_in_rectangle(mouse_pos, point0, point1)
		and Input.is_action_just_pressed("left_mouse")
	):
		if (
			!point_in_rectangle(mt_globals.mt_globals.main_window.get_current_graph_edit().current_pixel, Vector2.ZERO, mt_globals.mt_globals.main_window.get_current_graph_edit().canvas_size)
			or mt_globals.move_guides_on_canvas
		):
			has_focus = true
			mt_globals.main_window.get_current_graph_edit().has_focus = false
			queue_redraw()
	if has_focus:
		if Input.is_action_pressed("left_mouse"):
			if type == Types.HORIZONTAL:
				var yy = snapped(mouse_pos.y, 0.5)
				points[0].y = yy
				points[1].y = yy
			else:
				var xx = snapped(mouse_pos.x, 0.5)
				points[0].x = xx
				points[1].x = xx
			if outside_canvas():
				modulate.a = 0.5
			else:
				modulate.a = 1
		if Input.is_action_just_released("left_mouse"):
			mt_globals.main_window.get_current_graph_edit().has_focus = true
			has_focus = false
			if outside_canvas():
				project.guides.erase(self)
				queue_free()
			else:
				queue_redraw()


func _draw() -> void:
	if !has_focus:
		return
	var viewport_size: Vector2 = mt_globals.main_window.get_current_graph_edit().canvas_size
	var zoom: Vector2 = mt_globals.main_window.get_current_graph_edit().camera.zoom

	# viewport_poly is an array of the points that make up the corners of the viewport
	var viewport_poly := [
		Vector2.ZERO, Vector2(viewport_size.x, 0), viewport_size, Vector2(0, viewport_size.y)
	]
	# Adjusting viewport_poly to take into account the camera offset, zoom, and rotation
	for p in range(viewport_poly.size()):
		viewport_poly[p] = (
			viewport_poly[p].rotated(mt_globals.main_window.get_current_graph_edit().camera.rotation) * zoom
			+ Vector2(
				(
					mt_globals.main_window.get_current_graph_edit().camera.offset.x
					- (viewport_size.rotated(mt_globals.main_window.get_current_graph_edit().camera.rotation).x / 2) * zoom.x
				),
				(
					mt_globals.main_window.get_current_graph_edit().camera.offset.y
					- (viewport_size.rotated(mt_globals.main_window.get_current_graph_edit().camera.rotation).y / 2) * zoom.y
				)
			)
		)

	var string := (
		"%spx"
		% str(snapped(mouse_pos.y if type == Types.HORIZONTAL else mouse_pos.x, 0.5))
	)
	var color: Color = mt_globals.main_window.get_current_graph_edit().theme.get_color("font_color", "Label")
	# X and Y offsets for nicer looking spacing
	var x_offset := 5
	var y_offset := -7  # Only used where the string is above the guide

	var font_string_size := font.get_string_size(string)
	var font_height := font.get_height()
	# Draw the string where the guide intersects with the viewport poly
	# Priority is top edge, then left, then right
	var intersection = Geometry2D.segment_intersects_segment(
		points[0], points[1], viewport_poly[0], viewport_poly[1]
	)

	if intersection:
		draw_set_transform(intersection, mt_globals.main_window.get_current_graph_edit().camera.rotation, zoom * 2)
		if (
			intersection.distance_squared_to(viewport_poly[0])
			< intersection.distance_squared_to(viewport_poly[1])
		):
			draw_string(font, Vector2(x_offset, font_height), string,0,-1,16,color)
		else:
			draw_string(font, Vector2(-font_string_size.x - x_offset, font_height), string,0,-1,16, color)
		return

	intersection = Geometry2D.segment_intersects_segment(
		points[0], points[1], viewport_poly[3], viewport_poly[0]
	)
	if intersection:
		draw_set_transform(intersection, mt_globals.main_window.get_current_graph_edit().camera.rotation, zoom * 2)
		if (
			intersection.distance_squared_to(viewport_poly[3])
			< intersection.distance_squared_to(viewport_poly[0])
		):
			draw_string(font, Vector2(x_offset, y_offset), string,0,-1,16, color)
		else:
			draw_string(font, Vector2(x_offset, font_height), string,0,-1,16, color)
		return

	intersection = Geometry2D.segment_intersects_segment(
		points[0], points[1], viewport_poly[1], viewport_poly[2]
	)

	if intersection:
		draw_set_transform(intersection, mt_globals.main_window.get_current_graph_edit().camera.rotation, zoom * 2)
		if (
			intersection.distance_squared_to(viewport_poly[1])
			< intersection.distance_squared_to(viewport_poly[2])
		):
			draw_string(font, Vector2(-font_string_size.x - x_offset, font_height), string,0,-1,16, color)
		else:
			draw_string(font, Vector2(-font_string_size.x - x_offset, y_offset), string,0,-1,16, color)
		return

	# If there's no intersection with a viewport edge, show string in top left corner
	draw_set_transform(viewport_poly[0], mt_globals.main_window.get_current_graph_edit().camera.rotation, zoom * 2)
	draw_string(font, Vector2(x_offset, font_height), string,0,-1,16, color)


func outside_canvas() -> bool:
	if type == Types.HORIZONTAL:
		return points[0].y < 0 || points[0].y > project.size.y
	else:
		return points[0].x < 0 || points[0].x > project.size.x


func point_in_rectangle(p: Vector2, coord1: Vector2, coord2: Vector2) -> bool:
	return p.x > coord1.x && p.y > coord1.y && p.x < coord2.x && p.y < coord2.y
