extends Resource
class_name Project

@export var layers : layers_manager
@export var canvas_size : Vector2:
	set(value):
		emit_signal("canvas_size_changed", canvas_size, value)
		canvas_size = value
var undo_redo : UndoRedo

@export var save_path : String = "": 
	set(path):
		if path != save_path:
			save_path = path
			emit_signal("save_path_changed", self, path)
var need_save : bool = false: 
	set(new):
		if new != need_save:
			need_save = new
			emit_signal("need_save_changed")


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
		return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Project
	return null
