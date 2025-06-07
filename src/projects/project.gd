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
			var old_data_folder = save_path + folder_extension
			var new_data_folder = path + folder_extension
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
			save_path = path
			emit_signal("save_path_changed", self, path)
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

func save_project() -> bool:
	var error = ResourceSaver.save(self, save_path)
	if error == OK:
		project_saved.emit()
		need_save = false
		return true
	return false
	

static func project_exists(path:String) -> bool:
	return ResourceLoader.exists(path)

static func load_project(path:String) -> Project:
	if ResourceLoader.exists(path):
		var project : Project = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE) as Project
		for layer in project.layers_container.layers:
			layer.parent_project = project
		if project.resources_container: # check for compatibilty
			for resource in project.resources_container.resources:
				resource.parent_project = project
		else:
			project.resources_container = resources_manager.new()
		return project 
	return null
