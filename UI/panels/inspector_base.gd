extends Control
class_name InspectorBase

var current_object : Resource

signal current_object_changed
@export var properties_box : PropertiesBox 
# Called when the node enters the scene tree for the first time.
func _ready():
	properties_box.connect("value_changed", value_changed)
	current_object_changed.connect(create_ui)


func create_ui():
	#print("(" + get_script().resource_path.get_file() + ") UI Refresh")
	properties_box.clear()
	
	if !current_object:
		return
	if !current_object.get_inspector_properties():
		return
	var PropertiesView : Array = current_object.get_inspector_properties()
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
					
				
				var property_value = current_object.get(property.split(":")[0] if property.contains(":") else property)
				if property_value is Callable:
					properties_box.add_button(property, property_value)
				if property_value is int:
					if property.contains(":"): # hardness_property:min:1.0:max:100.0
						var property_info : PackedStringArray = property.split(":")
						var property_key = property_info[0]
						property_info.remove_at(0)
						var minvalue : float = -99999900000.0
						var maxvalue : float = 99999900000.0
						for i in property_info.size()-1:
							if property_info[i] == "minvalue":
								minvalue = float(property_info[i+1])
							if property_info[i] == "maxvalue":
								maxvalue = float(property_info[i+1])
						
						properties_box.add_int(property_key, property_value, minvalue, maxvalue)
					else:
						properties_box.add_int(property, property_value)
					continue
				if property_value is float:
					if property.contains(":"): # hardness_property:min:1.0:max:100.0
						var property_info : PackedStringArray = property.split(":")
						var property_key = property_info[0]
						property_info.remove_at(0)
						var minvalue : float = 0.0
						var maxvalue : float = 100.0
						var step : float = 0.1
						for i in property_info.size()-1:
							if property_info[i] == "minvalue":
								minvalue = float(property_info[i+1])
							if property_info[i] == "maxvalue":
								maxvalue = float(property_info[i+1])
							if property_info[i] == "step":
								step = float(property_info[i+1])
						
						properties_box.add_float(property_key, property_value, minvalue, maxvalue, step)
					else:
						properties_box.add_float(property, property_value)
					continue
				if property_value is String:
					properties_box.add_string(property, property_value)
					continue
				if property_value is bool:
					properties_box.add_bool(property, property_value)
					continue
				if property_value is Vector2:
					if property.contains(":"): # vector_property:lock_aspect(bool)
						var property_info : PackedStringArray = property.split(":")
						var property_key = property_info[0]
						property_info.remove_at(0)
						var lock_aspect_key : String = property_info[0]
						var lock_aspect : bool = current_object.get(lock_aspect_key)
						properties_box.add_vector2(property_key, property_value, lock_aspect_key, lock_aspect)
					else:
						properties_box.add_vector2(property, property_value)
					continue
				if property_value is Color:
					properties_box.add_color(property, property_value)
					continue
		properties_box.end_group()
	
func update():
	for k in properties_box._keys:
		
		properties_box._keys[k] = current_object.get(k)
	properties_box.update()

func value_changed(property:String, value):
	current_object.disconnect("changed",update)
	current_object.set(property, value)
	current_object.connect("changed",update)
