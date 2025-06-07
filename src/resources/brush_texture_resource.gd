extends base_resource
class_name brush_texture_resource

@export var image_path : String:
	set(v):
		image_path = v.get_file()
		if !parent_project:
			return
		print(image_path)
		var load_image = Image.load_from_file(parent_project.project_folder_abs_path + "/" + image_path)
		texture = ImageTexture.new()
		texture.set_image(load_image)
		icon = texture
		emit_changed()
var texture = ImageTexture.new()

func init(_name: String, p_group_name:String, path: String, project:Project):
	name = _name
	group_name = p_group_name
	image_path = path
	parent_project = project
	parent_project.resources_container.add_resource(self)

func refresh():
	if !texture.get_image() and parent_project:
		var load_image = Image.load_from_file(parent_project.project_folder_abs_path + "/" + image_path)
		texture.set_image(load_image)
		icon = texture

func get_copy(_name: String = "copy"):
	var resource = brush_texture_resource.new()
	resource.init(_name, group_name, image_path, parent_project)
	for k in get_inspector_properties()[1].keys(): # Copy Properties
		resource.set(k, get(k))
	return resource

func get_inspector_properties() -> Array:
	var PropertiesView : Array = super.get_inspector_properties()
	#PropertiesView[0].append("New Category")
	var PropertiesToShow : Dictionary = {}
	PropertiesToShow["image_path"] = "Resource"
	PropertiesView[1].merge(PropertiesToShow)
	return PropertiesView
