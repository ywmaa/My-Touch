extends SubViewportContainer
class_name MTGraph


var tiles: Tiles
var has_focus

func on_canvas_size_changed(value):
	if !tiles:
		return
	if ProjectsManager.project.canvas_size.x != 0:
		tiles.x_basis = (tiles.x_basis * value.x / ProjectsManager.project.canvas_size.x).round()
	else:
		tiles.x_basis = Vector2(value.x, 0)
	if ProjectsManager.project.canvas_size.y != 0:
		tiles.y_basis = (tiles.y_basis * value.y / ProjectsManager.project.canvas_size.y).round()
	else:
		tiles.y_basis = Vector2(0, value.y)
	tiles.tile_size = value
	tiles.reset_mask()
	transparent_checker.update_rect()

@onready var transparent_checker = $Viewport/TransparentChecker
@onready var camera: Camera2D = get_node("Viewport/Camera2D")
@export var tool_bar : Node 

func _ready() -> void:
	self.connect("mouse_entered",_on_mouse_entered)
	self.connect("mouse_exited",_on_mouse_exited)
	mt_globals.main_window.connect("signal_view_center",center_view)
	mt_globals.main_window.connect("signal_view_reset_zoom",camera.zoom_100)
	OS.low_processor_usage_mode = true

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
#			for layer in ProjectsManager.project.layers.layers:
#
#				if drag_end.y - drag_start.y < 0.0:
#					mouse_rect = Rect2(drag_end,abs(drag_end-drag_start))
#				else:
#					mouse_rect = Rect2(drag_start,abs(drag_end-drag_start))
#				mouse_rect.position.x = drag_start.x if drag_start.x < drag_end.x else drag_end.x
				
#				if mouse_rect.intersects(layer.get_rect(),true):
#					ProjectsManager.project.layers.select_layer(layer)


	
func _process(_delta):
	if !ProjectsManager.project:
		visible = false
		return
	visible = true
	if !tiles:
		tiles = Tiles.new(Vector2.ONE)
		center_view()
	if ProjectsManager.project.canvas_size != tiles.tile_size:
		on_canvas_size_changed(ProjectsManager.project.canvas_size)
	if $Viewport.msaa_2d != get_viewport().msaa_2d:
		$Viewport.msaa_2d = get_viewport().msaa_2d
	if has_focus == false:
		return
	if Input.is_action_just_pressed("show_tool_bar"):
		tool_bar.visible = !tool_bar.visible
	ToolsManager.camera = camera



# Center view

func center_view() -> void:
	if !ProjectsManager.project:
		return
	camera.fit_to_frame(ProjectsManager.project.canvas_size)


func _on_mouse_entered():
	has_focus = true
	ToolsManager.active_canvas[self] = has_focus


func _on_mouse_exited():
	has_focus = false
	ToolsManager.active_canvas[self] = has_focus

func _exit_tree():
	ToolsManager.active_canvas.erase(self)
