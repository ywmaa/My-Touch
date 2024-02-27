extends InspectorBase

var current_project : Project 

func _process(_delta):
	if !ProjectsManager.current_project:
		visible = false
		current_object = null
		current_object_changed.emit()
		return
	if !current_project or current_project != ProjectsManager.current_project:
		visible = false
		current_project = ProjectsManager.current_project
		return
	if current_project.layers_container.selected_layers.is_empty():
		current_object = null
		current_object_changed.emit()
		visible = false
		return
	
	if current_object != current_project.layers_container.selected_layers.front():
		current_object = current_project.layers_container.selected_layers.front()
		current_object_changed.emit()
	if current_object.main_object == null:
		return
	visible = true
	if !current_object.changed.is_connected(update):
		current_object.connect("changed",update)
