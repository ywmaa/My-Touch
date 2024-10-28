class_name Canvas
extends Node2D

@onready var animation_player = $AnimationPlayer
#@onready var pixel_grid = $PixelGrid
var sprites : Array[Node]
var current_project : Project
func _ready() -> void:
	pass
func _draw() -> void:

	if current_project == null:
		return
	
	var position_tmp := position
	var scale_tmp := scale
	if mt_globals.mirror_view:
		position_tmp.x = position_tmp.x + ProjectsManager.current_project.canvas_size.x
		scale_tmp.x = -1
	draw_set_transform(position_tmp, rotation, scale_tmp)
	
	# Draw current frame layers
		
	draw_set_transform(position, rotation, scale)

func rerender():
	for child in get_children():
		remove_child(child)
	if current_project == null:
		return
	render(self, current_project.layers_container.layers)


func _process(_delta):
#	if Input.is_action_just_pressed("mouse_left"):
#		for image in get_children():
#			if image.get_rect().has_point(image.to_local(get_global_mouse_position())):
#				pass
#				print("A click!")
	if current_project != ProjectsManager.current_project:
		current_project = ProjectsManager.current_project
		rerender()
	if current_project and current_project.layers_container.layers.size() != get_child_count():
		rerender()
		
	queue_redraw()
	
	if !ProjectsManager.current_project:
		return
	get_parent().size = ProjectsManager.current_project.canvas_size
	if get_parent().msaa_2d != get_viewport().msaa_2d:
		get_parent().msaa_2d = get_viewport().msaa_2d

func render(p:Node, layers_array:Array[base_layer], _parent_layer:base_layer=null):
	for layer in layers_array:
		var instance
		instance = layer.get_canvas_node()
		layer.refresh()
		if instance.get_parent():
			instance.get_parent().remove_child(instance)
		p.add_child(instance)
		#if parent_layer:
			#layer.parent = parent_layer
		render(instance, layer.children, layer) # Add Children
		instance.owner = self
		if layer is project_layer:
			render(instance, layer.project.layers_container.layers)
