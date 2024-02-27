extends InspectorBase

var current_project : Project 


func _process(_delta):
#	return
	if !ProjectsManager.current_project:
		visible = false
		current_object = null
		current_object_changed.emit()
		return
	if !current_project or current_project != ProjectsManager.current_project:
		visible = false
		current_project = ProjectsManager.current_project
		return
	
	## Assign Current Tool
	if current_object != ToolsManager.current_tool:
		current_object = ToolsManager.current_tool
		current_object_changed.emit()
	if current_object == null: return
	
	visible = true
	if !current_object.changed.is_connected(create_ui):
		current_object.changed.connect(create_ui)



## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta):
#	if ToolsManager.assigned_tool:
#		if ToolsManager.assigned_tool.has("settings_node"):
#			var panel: Node = ToolsManager.assigned_tool.settings_node
#			if panel != $ToolPanelContainer.get_child(0):
#				$ToolPanelContainer.get_child(0).queue_free()
#				$ToolPanelContainer.add_child(panel)
