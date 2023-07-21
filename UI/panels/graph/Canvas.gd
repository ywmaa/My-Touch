class_name Canvas
extends Node2D

@onready var pixel_grid = $PixelGrid
#@export var graph : MTGraph
var sprites : Array[Node]
var current_project : Project
func _ready() -> void:
	await get_tree().process_frame
#	camera_zoom()
func _draw() -> void:

	if current_project == null:
		return
	
	var position_tmp := position
	var scale_tmp := scale
	if mt_globals.mirror_view:
		position_tmp.x = position_tmp.x + ProjectsManager.project.canvas_size.x
		scale_tmp.x = -1
	draw_set_transform(position_tmp, rotation, scale_tmp)
	
	# Draw current frame layers


		
	draw_set_transform(position, rotation, scale)

func _process(_delta):
	if current_project != ProjectsManager.project:
		current_project = ProjectsManager.project
		for child in get_children():
			remove_child(child)
		if current_project == null:
			return
		render(self, current_project)
		
	queue_redraw()
	
	if !ProjectsManager.project:
		return
	get_parent().size = ProjectsManager.project.canvas_size
	if get_parent().msaa_2d != get_viewport().msaa_2d:
		get_parent().msaa_2d = get_viewport().msaa_2d

func render(p:Node, project:Project):
	if !project:
		return
	for layer in project.layers.layers:
		var instance
		instance = layer.get_image()
		if instance.get_parent():
			instance.get_parent().remove_child(instance)
		p.add_child(instance)
		if layer is project_layer:
			render(instance, layer.project)

#func camera_zoom() -> void:
#	# Set camera zoom based on the sprite size
#	if !ProjectsManager.project:
#		return
#	var canvas_size = ProjectsManager.project.canvas_size
#	var bigger_canvas_axis = max(canvas_size.x, canvas_size.y)
#	var zoom_max := Vector2(bigger_canvas_axis, bigger_canvas_axis) * 0.01
#
#	var camera = graph.camera
#	if zoom_max > Vector2.ONE:
#		camera.zoom_max = zoom_max
#	else:
#		camera.zoom_max = Vector2.ONE
#
#	camera.fit_to_frame(canvas_size)
##		camera.save_values_to_project()
#	graph.transparent_checker.update_rect()



