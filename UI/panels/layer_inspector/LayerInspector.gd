extends ScrollContainer

var current_project : Project 
var current_layer : base_layer

signal current_layer_changed
@export var properties_box : PropertiesBox 
# Called when the node enters the scene tree for the first time.
func _ready():
	properties_box.connect("value_changed", value_changed)
	current_layer_changed.connect(create_ui)


func _process(_delta):
	if !ProjectsManager.current_project:
		visible = false
		current_layer = null
		current_layer_changed.emit()
		return
	if !current_project or current_project != ProjectsManager.current_project:
		visible = false
		current_project = ProjectsManager.current_project
		return
	if current_project.layers_container.selected_layers.is_empty():
		current_layer = null
		current_layer_changed.emit()
		visible = false
		return
	
	if current_layer != current_project.layers_container.selected_layers.front():
		current_layer = current_project.layers_container.selected_layers.front()
		current_layer_changed.emit()
	if current_layer.main_object == null:
		return
	visible = true
	if !current_layer.changed.is_connected(create_ui):
		current_layer.connect("changed",create_ui)

func create_ui():
	properties_box.clear()
	
	if !current_layer:
		return
	var PropertiesView : Array = current_layer.get_layer_inspector_properties()
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
					
				
				var property_value = current_layer.get(property)
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
	current_layer.disconnect("changed",create_ui)
	
	if property.contains("X") or property.contains("Y"):
		var new_vector : Vector2 = current_layer.get(property.trim_suffix(" X").trim_suffix(" Y"))
		new_vector[0 if property.contains("X") else 1] = value 
		current_layer.set(property.trim_suffix(" X").trim_suffix(" Y"), new_vector)
		current_layer.connect("changed",create_ui)
		return
	
	current_layer.set(property, value)
	current_layer.connect("changed",create_ui)
