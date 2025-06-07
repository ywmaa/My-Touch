extends Resource
class_name base_resource
enum RESOURCE_TYPE {BRUSH_TEXTURE, BASE}
@export var name : String:
	set(v):
		name = v
		emit_changed()
@export var group_name : String:
	set(v):
		group_name = v
		emit_changed()
var icon : Texture2D

var parent_project : Project:
	set(v):
		parent_project = v

func get_resource_icon() -> Texture2D:
	return icon

func get_resource_name() -> String:
	return name

func get_inspector_properties() -> Array:
	var PropertiesView : Array = []
	var PropertiesGroups : Array[String] = []
	PropertiesGroups.append("Resource")
	var PropertiesToShow : Dictionary = {}
	PropertiesToShow["name"] = "Resource"
	PropertiesToShow["group_name"] = "Resource"
	
	PropertiesView.append(PropertiesGroups)
	PropertiesView.append(PropertiesToShow)
	return PropertiesView

func get_copy(_name: String = "copy"):
	printerr("Not implemented: get_copy! (" + get_script().resource_path.get_file() + ")")
	return null
