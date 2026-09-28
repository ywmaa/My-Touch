extends Resource
class_name Project

@export var animations : Array[Animation]
@export var layers_container : layers_manager
@export var resources_container : resources_manager
@export var canvas_size : Vector2:
	set(value):
		emit_signal("canvas_size_changed", canvas_size, value)
		canvas_size = value
var undo_redo : UndoRedo
var folder_extension: String = " Project Data"
var project_folder_abs_path : String:
	set(_v):
		pass
	get:
		return save_path + folder_extension

@export var save_path : String = "": 
	set(path):
		if path != save_path:
			if move_data_on_path_change:
				_move_data_folder(save_path, path)
			save_path = path
			emit_signal("save_path_changed", self, path)
## When false, changing save_path doesn't touch the data folder (used after loading).
var move_data_on_path_change : bool = true
var need_save : bool = false: 
	set(new):
		if new != need_save:
			need_save = new
			emit_signal("need_save_changed")
var name_used : bool = false

signal canvas_size_changed(prev_canvas_size,new_canvas_size)
signal save_path_changed
signal need_save_changed
signal project_saved

func _move_data_folder(old_path: String, new_path: String) -> void:
	var old_data_folder = old_path + folder_extension
	var new_data_folder = new_path + folder_extension
	if MTStorage.is_saf(old_path) or MTStorage.is_saf(new_path):
		# Folders shared through the system picker can't be listed or renamed, copy file by file.
		var files : PackedStringArray
		if MTStorage.dir_exists(old_data_folder):
			files = DirAccess.get_files_at(old_data_folder)
		else:
			files = get_data_files()
		MTStorage.make_dir(new_data_folder)
		for file in files:
			if MTStorage.file_exists(old_data_folder+"/"+file):
				MTStorage.copy_file(old_data_folder+"/"+file, new_data_folder+"/"+file)
		if old_data_folder.contains("user://") and DirAccess.dir_exists_absolute(old_data_folder):
			for file in DirAccess.get_files_at(old_data_folder):
				DirAccess.remove_absolute(old_data_folder+"/"+file)
			DirAccess.remove_absolute(old_data_folder)
		return
	if DirAccess.dir_exists_absolute(old_data_folder):
		if old_data_folder.contains("user://"):  # Can't delete a user folder without deleting the files first
			DirAccess.make_dir_absolute(new_data_folder)
			for file in DirAccess.get_files_at(old_data_folder):
				DirAccess.copy_absolute(old_data_folder+"/"+file, new_data_folder+"/"+file)
				DirAccess.remove_absolute(old_data_folder+"/"+file)
			DirAccess.remove_absolute(old_data_folder)
		else:
			DirAccess.rename_absolute(old_data_folder, new_data_folder) # Moves the folder
	else:
		if new_data_folder.contains("user://"):
			if DirAccess.dir_exists_absolute(new_data_folder):
				for file in DirAccess.get_files_at(new_data_folder):
					DirAccess.remove_absolute(new_data_folder+"/"+file)
		DirAccess.make_dir_absolute(new_data_folder)

## Names of the files this project uses from its data folder.
func get_data_files() -> PackedStringArray:
	var files : PackedStringArray = []
	var items : Array = []
	if layers_container:
		items.append_array(layers_container.layers)
	if resources_container:
		items.append_array(resources_container.resources)
	for item in items:
		if "image_path" in item and item.image_path != "":
			var file : String = String(item.image_path).get_file()
			if !files.has(file):
				files.append(file)
	return files

func save_project() -> bool:
	var error = MTStorage.save_resource(self, save_path)
	if error == OK:
		project_saved.emit()
		need_save = false
		return true
	return false


static func project_exists(path:String) -> bool:
	return MTStorage.resource_exists(path)

static func load_project(path:String) -> Project:
	if MTStorage.resource_exists(path):
		var project : Project = MTStorage.load_resource(path, ResourceLoader.CACHE_MODE_REUSE) as Project
		if project == null:
			return null
		# The file may have been moved or copied since it was saved, its data folder is next to it.
		project.move_data_on_path_change = false
		project.save_path = path
		project.move_data_on_path_change = true
		for layer in project.layers_container.layers:
			layer.parent_project = project
		if project.resources_container: # check for compatibilty
			for resource in project.resources_container.resources:
				resource.parent_project = project
		else:
			project.resources_container = resources_manager.new()
		return project 
	return null
