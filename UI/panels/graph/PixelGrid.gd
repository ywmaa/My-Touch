extends Node2D

@export var graph : MTGraph
func _draw() -> void:
	
	if not mt_globals.draw_pixel_grid:
		return

	var zoom_percentage = 100.0 / graph.camera.zoom.x
	if zoom_percentage < mt_globals.pixel_grid_show_at_zoom:
		return

	var target_rect: Rect2 = graph.tiles.get_bounding_rect()
	if !target_rect.has_area():
		return

	# Using Array instead of PoolVector2Array to avoid kinda
	# random "resize: Can't resize PoolVector if locked" errors.
	#  See: https://github.com/Orama-Interactive/Pixelorama/issues/331
	# It will be converted to PoolVector2Array before being sent to be rendered.
	var grid_multiline_points := []

	for x in range(ceil(target_rect.position.x), floor(target_rect.end.x) + 1):
		grid_multiline_points.push_back(Vector2(x, target_rect.position.y))
		grid_multiline_points.push_back(Vector2(x, target_rect.end.y))

	for y in range(ceil(target_rect.position.y), floor(target_rect.end.y) + 1):
		grid_multiline_points.push_back(Vector2(target_rect.position.x, y))
		grid_multiline_points.push_back(Vector2(target_rect.end.x, y))

	if not grid_multiline_points.is_empty():
		draw_multiline(grid_multiline_points, mt_globals.pixel_grid_color)
