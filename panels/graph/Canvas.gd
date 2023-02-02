class_name Canvas
extends Node2D

@onready var project = get_parent().get_parent().get_parent().get_parent()
@onready var pixel_grid = $PixelGrid


func _ready() -> void:
	await get_tree().process_frame
	camera_zoom()


func _draw() -> void:
#	var current_cels: Array = Global.current_project.frames[Global.current_project.current_frame].cels
#	var current_layer: int = Global.current_project.current_layer
	var position_tmp := position
	var scale_tmp := scale
	if mt_globals.mirror_view:
		position_tmp.x = position_tmp.x + project.canvas_size.x
		scale_tmp.x = -1
	draw_set_transform(position_tmp, rotation, scale_tmp)
	# Draw current frame layers
	for i in project.layers.layers:
		i.draw_image()
		
		
	draw_set_transform(position, rotation, scale)

func _process(delta):
	queue_redraw()
	get_parent().size = project.canvas_size



func camera_zoom() -> void:
	# Set camera zoom based on the sprite size
	var canvas_size = project.canvas_size
	var bigger_canvas_axis = max(canvas_size.x, canvas_size.y)
	var zoom_max := Vector2(bigger_canvas_axis, bigger_canvas_axis) * 0.01

	var camera = project.camera
	if zoom_max > Vector2.ONE:
		camera.zoom_max = zoom_max
	else:
		camera.zoom_max = Vector2.ONE

	camera.fit_to_frame(canvas_size)
#		camera.save_values_to_project()
	project.transparent_checker.update_rect()



