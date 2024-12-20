extends SubViewportContainer
class_name MTGraph


var tiles: Tiles
var has_focus

func on_canvas_size_changed(value):
	if !tiles:
		return
	if ProjectsManager.current_project.canvas_size.x != 0:
		tiles.x_basis = (tiles.x_basis * value.x / ProjectsManager.current_project.canvas_size.x).round()
	else:
		tiles.x_basis = Vector2(value.x, 0)
	if ProjectsManager.current_project.canvas_size.y != 0:
		tiles.y_basis = (tiles.y_basis * value.y / ProjectsManager.current_project.canvas_size.y).round()
	else:
		tiles.y_basis = Vector2(0, value.y)
	tiles.tile_size = value
	tiles.reset_mask()
	transparent_checker.update_rect()

@onready var transparent_checker = $Viewport/TransparentChecker
@onready var camera: Camera2D = get_node("Viewport/Camera2D")
@export var tool_bar : Node 
@export var resize_tool : Control
func _ready() -> void:
	self.connect("mouse_entered",_on_mouse_entered)
	self.connect("mouse_exited",_on_mouse_exited)
	mt_globals.main_window.connect("signal_view_center",center_view)
	mt_globals.main_window.connect("signal_view_reset_zoom",camera.zoom_100)
	OS.low_processor_usage_mode = true
	resize_tool.connect("value_changed",resize_canvas)
	
func resize_canvas(delta, expand_direction):
	ProjectsManager.current_project.canvas_size += delta.round()
	if expand_direction < Vector2i.ZERO:
		mt_globals.main_window.get_node("AppRender/Canvas").position += delta.round()
var dragging : bool = false
var drag_start : Vector2 = Vector2.ZERO

func _draw():
	if dragging:
		draw_rect(Rect2(drag_start,get_local_mouse_position()-drag_start),Color(0.75,0.75,0.75),false)

var mouse_rect : Rect2

func pass_event_to_tool(event) -> bool:
	return ToolsManager.handle_image_input(event)

#func _input(event):
#	if !visible or has_focus == false:
#		return
#
##	pass_event_to_tool(event)
#	if event is InputEventMouseMotion and dragging:
#		queue_redraw()
#	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
#		if event.pressed:
#			pass
##					layers.selected_layers = []
#			dragging = true
#			drag_start = get_local_mouse_position()
#
#
#		elif dragging:
#			dragging = false
#			queue_redraw()
#			var drag_end = get_local_mouse_position()
#
#			for layer in ProjectsManager.current_project.layers_container.layers:
#
#				if drag_end.y - drag_start.y < 0.0:
#					mouse_rect = Rect2(drag_end,abs(drag_end-drag_start))
#				else:
#					mouse_rect = Rect2(drag_start,abs(drag_end-drag_start))
#				mouse_rect.position.x = drag_start.x if drag_start.x < drag_end.x else drag_end.x
				
#				if mouse_rect.intersects(layer.get_rect(),true):
#					ProjectsManager.current_project.layers_container.select_layer(layer)


	
func _process(_delta):
	if !ProjectsManager.current_project:
		visible = false
		return
	visible = true
	if !tiles:
		tiles = Tiles.new(Vector2.ONE)
		center_view()
	if ProjectsManager.current_project.canvas_size != tiles.tile_size:
		on_canvas_size_changed(ProjectsManager.current_project.canvas_size)
	if $Viewport.msaa_2d != get_viewport().msaa_2d:
		$Viewport.msaa_2d = get_viewport().msaa_2d
	if has_focus == false:
		return
	if Input.is_action_just_pressed("show_tool_bar"):
		tool_bar.visible = !tool_bar.visible
	ToolsManager.camera = camera
	if Input.is_action_just_pressed("focus"):
		if ProjectsManager.current_project.layers_container.selected_layers.is_empty():
			return
		var camera_position = Vector2.ZERO
		for layer in ProjectsManager.current_project.layers_container.selected_layers:
			camera_position += layer.main_object.global_position
		camera_position = camera_position/ProjectsManager.current_project.layers_container.selected_layers.size()
		
#		var margin = Vector2(100, 100)
		var r = Rect2(Vector2.ZERO, Vector2.ZERO)
		for i in ProjectsManager.current_project.layers_container.selected_layers.size():
			var layer = ProjectsManager.current_project.layers_container.selected_layers[i]
			if i == 0:
				r = Rect2(layer.main_object.global_position, layer.size*layer.scale)
				continue
			r = r.expand(layer.main_object.global_position)
#		r = r.grow_individual(margin.x, margin.y, margin.x, margin.y)

		camera.fit_to_frame(r.size)
		camera.offset = camera_position

# Center view

func center_view() -> void:
	if !ProjectsManager.current_project:
		return
	camera.fit_to_frame(ProjectsManager.current_project.canvas_size)


func _on_mouse_entered():
	has_focus = true
	ToolsManager.active_canvas[self] = has_focus


func _on_mouse_exited():
	has_focus = false
	ToolsManager.active_canvas[self] = has_focus

func _exit_tree():
	ToolsManager.active_canvas.erase(self)
