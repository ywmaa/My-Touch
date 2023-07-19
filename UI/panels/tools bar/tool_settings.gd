extends ScrollContainer

var current_graph : MTGraph 
var current_tool : ToolBase

signal current_tool_changed
@export var properties_box : PropertiesBox 
# Called when the node enters the scene tree for the first time.
func _ready():
	properties_box.connect("value_changed", value_changed)
	current_tool_changed.connect(create_ui)


func _process(_delta):
	return
	if !mt_globals.main_window.get_current_graph_edit():
		visible = false
		current_tool = null
		current_tool_changed.emit()
		return
	if !current_graph or current_graph != mt_globals.main_window.get_current_graph_edit():
		visible = false
		current_graph = mt_globals.main_window.get_current_graph_edit()
		return
	if current_graph.layers.selected_layers.is_empty():
		current_tool = null
		current_tool_changed.emit()
		visible = false
		return
	
	## Assign Current Tool
#	if current_layer != current_graph.layers.selected_layers.front():
#		current_layer = current_graph.layers.selected_layers.front()
#		current_tool_changed.emit()
	visible = true
	if !current_tool.changed.is_connected(create_ui):
		current_tool.connect("changed",create_ui)

func create_ui():
	properties_box.clear()
	
	if !current_tool:
		return
	var PropertiesView : Array = current_tool.get_tool_inspector_properties()
	var PropertiesGroups : Array[String] = PropertiesView[0]
	var PropertiesToShow : Dictionary = PropertiesView[1]
	
	for group in PropertiesGroups:
		properties_box.add_group(group)
		for property in PropertiesToShow:
			if PropertiesToShow[property] == group:
				
				if property.contains(","): # An Enum
					var property_info : PackedStringArray = property.split(",")
					var property_key = property_info[0]
					property_info.remove_at(0)
					properties_box.add_options(property_key, property_info)
					continue
					
				
				var property_value = current_tool.get(property)
				if property_value is int:
					properties_box.add_int(property, property_value)
					continue
				if property_value is float:
					properties_box.add_float(property, property_value)
					continue
				if property_value is String:
					properties_box.add_string(property, property_value)
					continue
				if property_value is bool:
					properties_box.add_bool(property, property_value)
					continue
				if property_value is Vector2:
					properties_box.add_vector2(property, property_value)
					continue
				if property_value is Color:
					properties_box.add_color(property, property_value)
					continue
		properties_box.end_group()
	


func value_changed(property:String, value):
	current_tool.disconnect("changed",create_ui)
	
	if property.contains("X") or property.contains("Y"):
		var new_vector : Vector2 = current_tool.get(property.trim_suffix(" X").trim_suffix(" Y"))
		new_vector[0 if property.contains("X") else 1] = value 
		current_tool.set(property.trim_suffix(" X").trim_suffix(" Y"), new_vector)
		current_tool.connect("changed",create_ui)
		return
	
	current_tool.set(property, value)
	current_tool.connect("changed",create_ui)


## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta):
#	if ToolsManager.assigned_tool:
#		if ToolsManager.assigned_tool.has("settings_node"):
#			var panel: Node = ToolsManager.assigned_tool.settings_node
#			if panel != $ToolPanelContainer.get_child(0):
#				$ToolPanelContainer.get_child(0).queue_free()
#				$ToolPanelContainer.add_child(panel)
