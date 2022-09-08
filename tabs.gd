extends Panel

var current_tab = -1 :
	set(t):
		if t == current_tab or t < 0 or t >= $Tabs.get_tab_count():
			return
		var node
		if current_tab >= 0 && current_tab < $Tabs.get_tab_count():
			node = get_child(current_tab)
			node.visible = false
			node.layers.selected_layers.clear()
		current_tab = t
		node = get_child(current_tab)
		node.visible = true
		node.get_rect().position = Vector2(0, $Tabs.get_rect().size.y)
		node.get_rect().size = get_rect().size - node.get_rect().position
		
		$Tabs.current_tab = current_tab
		emit_signal("tab_changed", current_tab)
signal tab_changed
signal no_more_tabs

func add_child(control, legible_unique_name = false,i=0) -> void:
	super.add_child(control, legible_unique_name)
	if !(control is TabBar):
		$Tabs.add_tab(control.name)
		move_child(control, $Tabs.get_tab_count()-1)
	

func close_tab(tab = null) -> void:
	if tab == null:
		tab = $Tabs.get_current_tab()
	var result = await check_save_tab(tab)
	if result:
		do_close_tab(tab)

func get_tab_count() -> int:
	return $Tabs.get_tab_count()

func get_tab(i : int) -> Control:
	return $Tabs.get_child(i) as Control

func check_save_tabs() -> bool:
	for i in range($Tabs.get_tab_count()):
		var result = await check_save_tab(i)
		if !result:
			return false
	return true

func check_save_tab(tab) -> bool:
	var tab_control = get_child(tab)
	if tab_control.need_save and mt_globals.get_config("confirm_close_project"):
		var dialog = preload("res://windows/accept_dialog/accept_dialog.tscn").instantiate()
		var save_path = tab_control.save_path
		if save_path == null:
			save_path = "[unnamed]"
		else:
			save_path = save_path.get_file()
		dialog.dialog_text = "Save "+save_path+" before closing?"
		#dialog.dialog_autowrap = true
		dialog.get_ok_button().text = "Save and close"
		dialog.add_button("Discard changes", true, "discard")
		dialog.add_cancel_button("Cancel")
		get_parent().add_child(dialog)
		var result = await dialog.ask()
		match result:
			"ok":
				var status = await mt_globals.main_window.save_project(tab_control)
				if !status:
					return false
			"cancel":
				return false
	return true

func do_close_custom_action(_action : String, _tab : int, dialog : AcceptDialog) -> void:
	dialog.queue_free()


func do_close_tab(tab = 0) -> void:
	get_child(tab).queue_free()
	$Tabs.remove_tab(tab)
	var control = get_child(tab)
	remove_child(control)
	control.free()
	current_tab = -1
	if $Tabs.get_tab_count() == 0:
		emit_signal("no_more_tabs")
	else:
		current_tab = 0

func move_active_tab_to(idx_to) -> void:
	$Tabs.move_tab(current_tab, idx_to)
	move_child(get_child(current_tab), idx_to)
	current_tab = idx_to



func set_tab_title(index, title) -> void:
	$Tabs.set_tab_title(index, title)

func get_current_tab_control():
	if get_child_count() < 2:
		return null
	return get_child(current_tab)

func _on_Projects_resized() -> void:
	$Tabs.get_rect().size.x = get_rect().size.x


func _input(event: InputEvent) -> void:
	# Navigate between tabs using keyboard shortcuts.
	if event.is_action_pressed("ui_previous_tab"):
		current_tab = wrapi(current_tab - 1, 0, $Tabs.get_tab_count())
	elif event.is_action_pressed("ui_next_tab"):
		current_tab = wrapi(current_tab + 1, 0, $Tabs.get_tab_count())

func _gui_input(event: InputEvent) -> void:
	# Navigate between tabs by hovering tabs then using the mouse wheel.
	# Only take into account the mouse wheel scrolling on the tabs themselves,
	# not their content.
	var rect := get_global_rect()
	# Roughly matches the height of the tabs bar itself (with some additional tolerance for better usability).
	rect.size.y = 30
	if event is InputEventMouseButton and event.pressed and rect.has_point(get_global_mouse_position()):
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_tab = wrapi(current_tab - 1, 0, $Tabs.get_tab_count())
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_tab = wrapi(current_tab + 1, 0, $Tabs.get_tab_count())


func set_current_tab(tab):
	current_tab = tab


func _on_auto_save_timer_timeout():
	for i in range($Tabs.get_tab_count()):
		var tab_control = get_child(i)
		if tab_control.has_method("auto_save"):
			tab_control.auto_save()
