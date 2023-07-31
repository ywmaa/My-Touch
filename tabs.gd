extends Panel

var current_tab = -1 :
	set(t):
		if t < 0 or t >= $Tabs.get_tab_count():
			return
		current_tab = t
		$Tabs.current_tab = current_tab
		ProjectsManager.project = ProjectsManager.projects[t]
		emit_signal("tab_changed")
signal tab_changed
signal no_more_tabs

func _process(_delta):
	for index in ProjectsManager.projects.size(): 
		var project = ProjectsManager.projects[index]
		var title : String = ("[unnamed]" if project.save_path == "" else project.save_path) + (" *" if project.need_save else "")
		set_tab_title(index, title)
	if current_tab != ProjectsManager.projects.find(ProjectsManager.project):
		create_tabs()
		current_tab = ProjectsManager.projects.find(ProjectsManager.project)
	if $Tabs.tab_count == ProjectsManager.projects.size():
		return
	create_tabs()



func create_tabs():
	$Tabs.clear_tabs()
	for project in ProjectsManager.projects:
		$Tabs.add_tab("[unnamed]" if project.save_path == "" else project.save_path + (" *" if project.need_save else "") )


func close_tab(tab = null) -> void:
	if tab == null:
		tab = $Tabs.get_current_tab()
	var result = await check_save_tab(tab)
	if result:
		ProjectsManager.close_project(tab)
		do_close_tab(tab)


func check_save_tabs() -> bool:
	for i in range($Tabs.get_tab_count()):
		var result = await check_save_tab(i)
		if !result:
			return false
	return true

func check_save_tab(tab) -> bool:
	var project = ProjectsManager.projects[tab]
	if project.need_save and mt_globals.get_config("confirm_close_project"):
		var dialog = preload("res://UI/windows/accept_dialog/accept_dialog.tscn").instantiate()
		var save_path = project.save_path
		if save_path == "":
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
				var status = await project.save_project()
				if !status:
					return false
			"cancel":
				return false
	return true

#func do_close_custom_action(_action : String, _tab : int, dialog : AcceptDialog) -> void:
#	dialog.queue_free()


func do_close_tab(tab = 0) -> void:
	$Tabs.remove_tab(tab)
	current_tab = -1
	if $Tabs.get_tab_count() == 0:
		emit_signal("no_more_tabs")
	else:
		current_tab = 0

func move_active_tab_to(idx_to) -> void:
	$Tabs.move_tab(current_tab, idx_to)
	var project = ProjectsManager.projects[current_tab]
	ProjectsManager.projects.remove_at(current_tab)
	ProjectsManager.projects.insert(idx_to if idx_to < current_tab else idx_to-1,project)
	current_tab = idx_to


func set_tab_title(index, title) -> void:
	if $Tabs.tab_count < index+1:
		return 
	$Tabs.set_tab_title(index, title)
	


func _on_Projects_resized() -> void:
	$Tabs.get_rect().size.x = get_rect().size.x


func _input(event: InputEvent) -> void:
	# Navigate between tabs using keyboard shortcuts.
	if event.is_action_pressed("ui_focus_prev"):
		current_tab = wrapi(current_tab - 1, 0, $Tabs.get_tab_count())
	elif event.is_action_pressed("ui_focus_next"):
		current_tab = wrapi(current_tab + 1, 0, $Tabs.get_tab_count())

#func _unhandled_input(event: InputEvent) -> void:
#	# Navigate between tabs by hovering tabs then using the mouse wheel.
#	# Only take into account the mouse wheel scrolling on the tabs themselves,
#	# not their content.
#	var rect := get_global_rect()
#	# Roughly matches the height of the tabs bar itself (with some additional tolerance for better usability).
#	rect.size.y = 30
#	if event is InputEventMouseButton and event.pressed and rect.has_point(get_global_mouse_position()):
#		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
#			current_tab = wrapi(current_tab - 1, 0, $Tabs.get_tab_count())
#		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
#			current_tab = wrapi(current_tab + 1, 0, $Tabs.get_tab_count())


func set_current_tab(tab):
	current_tab = tab


func _on_auto_save_timer_timeout():
	for i in range($Tabs.get_tab_count()):
		if ProjectsManager.has_method("auto_save"):
			ProjectsManager.auto_save()


#func _on_mouse_entered():
#	print("entered")
#	mt_globals.main_window.left_cursor.visible = mt_globals.show_left_tool_icon
#
#
#func _on_mouse_exited():
#	print("exited")
#	mt_globals.main_window.left_cursor.visible = false


