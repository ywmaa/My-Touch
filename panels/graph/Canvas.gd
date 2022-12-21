class_name Canvas
extends Node2D

const MOVE_ACTIONS := ["move_mouse_left", "move_mouse_right", "move_mouse_up", "move_mouse_down"]
const CURSOR_SPEED_RATE := 6.0

var current_pixel := Vector2.ZERO
var sprite_changed_this_frame := false  # For optimization purposes
var move_preview_location := Vector2.ZERO

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
		var modulate_color := Color(1, 1, 1, 1)
		if i.hidden == false:
			draw_texture_rect(i.image.texture,Rect2(i.image.position,i.image.get_rect().size*i.image.scale),false)
		
#
#	if Global.onion_skinning:
#		refresh_onion()
	draw_set_transform(position, rotation, scale)

func _process(delta):
	queue_redraw()
	get_parent().size = project.canvas_size

func _input(event: InputEvent) -> void:
	# Don't process anything below if the input isn't a mouse event, or Shift/Ctrl.
	# This decreases CPU/GPU usage slightly.
	var get_velocity := false
	if not event is InputEventMouseMotion:
		for action in MOVE_ACTIONS:
			if event.is_action(action):
				get_velocity = true
		if (
			!get_velocity
			and !(event.is_action("activate_left_tool") or event.is_action("activate_right_tool"))
		):
			return

	var tmp_position: Vector2 = project.get_local_mouse_position()
	if get_velocity:
		var velocity := Input.get_vector(
			"move_mouse_left", "move_mouse_right", "move_mouse_up", "move_mouse_down"
		)
		if velocity != Vector2.ZERO:
			tmp_position += velocity * CURSOR_SPEED_RATE
			project.warp_mouse(tmp_position)
	# Do not use self.get_local_mouse_position() because it return unexpected
	# value when shrink parameter is not equal to one. At godot version 3.2.3
	var tmp_transform = get_canvas_transform().affine_inverse()
	current_pixel = tmp_transform.basis_xform(tmp_position) + tmp_transform.origin


	sprite_changed_this_frame = false

#	Tools.handle_draw(current_pixel.floor(), event)

#	if sprite_changed_this_frame:
#		update_selected_cels_textures()


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


#func update_texture(layer_i: int, frame_i := -1, project: Project = Global.current_project) -> void:
#	if frame_i == -1:
#		frame_i = project.current_frame
#
#	if frame_i < project.frames.size() and layer_i < project.layers.size():
#		var current_cel: BaseCel = project.frames[frame_i].cels[layer_i]
#		current_cel.update_texture()
#
#
#func update_selected_cels_textures(project: Project = Global.current_project) -> void:
#	for cel_index in project.selected_cels:
#		var frame_index: int = cel_index[0]
#		var layer_index: int = cel_index[1]
#		if frame_index < project.frames.size() and layer_index < project.layers.size():
#			var current_cel: BaseCel = project.frames[frame_index].cels[layer_index]
#			current_cel.update_texture()
#

#func refresh_onion() -> void:
#	$OnionPast.update()
#	$OnionFuture.update()
