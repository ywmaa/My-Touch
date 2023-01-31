extends ScrollContainer


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if ToolManager.assigned_tool:
		if ToolManager.assigned_tool.has("settings_node"):
			var panel: Node = ToolManager.assigned_tool.settings_node
			if panel != $ToolPanelContainer.get_child(0):
				$ToolPanelContainer.get_child(0).queue_free()
				$ToolPanelContainer.add_child(panel)
