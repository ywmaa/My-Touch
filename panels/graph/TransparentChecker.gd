extends ColorRect


func _ready() -> void:
	update_rect()
	self.connect("resized", _on_resized)


func update_rect() -> void:
	if !mt_globals.main_window.get_current_graph_edit():
		visible = false
		return
	visible = true
	size = mt_globals.main_window.get_current_graph_edit().canvas_size
	fit_rect(mt_globals.main_window.get_current_graph_edit().tiles.get_bounding_rect())
	material.set_shader_parameter("size", mt_globals.checker_size)
	material.set_shader_parameter("color1", mt_globals.checker_color_1)
	material.set_shader_parameter("color2", mt_globals.checker_color_2)
	material.set_shader_parameter("follow_movement", mt_globals.checker_follow_movement)
	material.set_shader_parameter("follow_scale", mt_globals.checker_follow_scale)


func update_offset(offset: Vector2, p_scale: Vector2) -> void:
	material.set_shader_parameter("offset", offset)
	material.set_shader_parameter("scale", p_scale)




func fit_rect(rect: Rect2) -> void:
	position = rect.position
	size = rect.size


func update_transparency(value: float) -> void:
	# Change the transparency status of the parent viewport and the root viewport
	if value == 1.0:
		get_parent().transparent_bg = false
		get_tree().get_root().transparent_bg = false
	else:
		get_parent().transparent_bg = true
		get_tree().get_root().transparent_bg = true

	# Set a minimum amount for the fade so the canvas won't disappear
	material.set("shader_param/alpha", clamp(value, 0.1, 1))


func _on_resized():
	material.set_shader_parameter("rect_size", size)
