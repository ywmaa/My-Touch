class_name Canvas
extends Node2D

@onready var pixel_grid = $PixelGrid
@export var graph : MTGraph
var sprites : Array[Node]
var current_project : Project
func _ready() -> void:
	await get_tree().process_frame
	camera_zoom()

func _draw() -> void:
	if current_project != ProjectsManager.project:
		current_project = ProjectsManager.project

	if current_project == null:
		return
	
	var position_tmp := position
	var scale_tmp := scale
	if mt_globals.mirror_view:
		position_tmp.x = position_tmp.x + ProjectsManager.project.canvas_size.x
		scale_tmp.x = -1
	draw_set_transform(position_tmp, rotation, scale_tmp)
	
	# Draw current frame layers
	for child in get_children():
		remove_child(child)
	render(self, current_project)

		
	draw_set_transform(position, rotation, scale)

func _process(_delta):
	queue_redraw()
	if !ProjectsManager.project:
		return
	get_parent().size = ProjectsManager.project.canvas_size

func render(p:Node, project:Project):
	for layer in project.layers.layers:
		var instance
		if layer is selection_layer:
			instance = layer.get_image().duplicate(4)
		else:
			instance = layer.get_image().duplicate(8)
		p.add_child(instance)
		if layer is project_layer:
#			print("project layer")
#			layer.refresh()
			render(instance, layer.project)

func camera_zoom() -> void:
	# Set camera zoom based on the sprite size
	var canvas_size = ProjectsManager.project.canvas_size
	var bigger_canvas_axis = max(canvas_size.x, canvas_size.y)
	var zoom_max := Vector2(bigger_canvas_axis, bigger_canvas_axis) * 0.01

	var camera = graph.camera
	if zoom_max > Vector2.ONE:
		camera.zoom_max = zoom_max
	else:
		camera.zoom_max = Vector2.ONE

	camera.fit_to_frame(canvas_size)
#		camera.save_values_to_project()
	graph.transparent_checker.update_rect()



