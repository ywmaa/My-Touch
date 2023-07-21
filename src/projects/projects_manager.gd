extends Node

var projects : Array[Project]

var project : Project:
	set(new_project):
		project = new_project
		if !project:
			return
		if !project.undo_redo:
			project.undo_redo = UndoRedo.new()
var clipboard_file_path = "user://my_touch_clipboard.res"
var default_icon = "res://icon.png"

func new_project() -> void:
#	center_view()
	project = Project.new()
	project.canvas_size = Vector2(mt_globals.default_width,mt_globals.default_height)
	project.layers = layers_manager.new()
	projects.append(project)
	#default layer
	var new_layer : base_layer = base_layer.new()
	new_layer.init(project.layers.get_unused_layer_name(),default_icon,base_layer.layer_type.image)
	project.layers.add_layer(new_layer)

func close_project(index:int):
	if projects.size() > 1:
		if projects[index] == project:
			if index-1 < 0:
				project = projects[index+1]
			else:
				project = projects[index-1]
		projects.remove_at(index)
	else:
		project = null
		projects.clear()




func on_import_image_file(path):
	if !project:
		return
	var new_layer : base_layer = base_layer.new()
	new_layer.init(project.layers.get_unused_layer_name(),path,base_layer.layer_type.image)
	project.layers.add_layer(new_layer)

# Cut / copy / paste / duplicate

func remove_selection() -> void:
	if !project:
		return
	project.need_save = true
	for selection in project.layers.selected_layers:
		project.layers.remove_layer(selection)
		
func cut() -> void:
	copy()
	remove_selection()

func copy() -> void:
	if !project:
		return
	var data : mt_clipboard = mt_clipboard.new()
	data.layers = project.layers.selected_layers
	ResourceSaver.save(data,clipboard_file_path)

func paste() -> void:
	if !project:
		return
	project.need_save = true
	var data = ResourceLoader.load(clipboard_file_path) as mt_clipboard
	select_none()
	for layer in data.layers:
		project.layers.duplicate_layer(layer)

func duplicate_selected() -> void:
	copy()
	paste()

func select_all():
	if !project:
		return
	project.layers.selected_layers = project.layers.layers
func select_none():
	if !project:
		return
	project.layers.selected_layers = []
func select_invert():
	if !project:
		return
	var inverted_selections : Array[base_layer] = []
	for layer in project.layers.layers:
		if layer in project.layers.selected_layers:
			continue
		inverted_selections.append(layer)
	project.layers.selected_layers = inverted_selections
func load_selection(filenames) -> void:
	if !project:
		return
	var file_name : String = ""
	for f in filenames:
		var file = FileAccess.open(f, FileAccess.READ)
		if file == null:
			continue
		file_name = file.get_path_absolute()
		var data = ResourceLoader.load(file_name) as Project
		if data != null:
			project.layers.layers.append_array(data.layers.layers)
			project.need_save = true
		else:
			var dialog : AcceptDialog = AcceptDialog.new()
			add_child(dialog)
			dialog.title = "Load failed!"
			dialog.dialog_text = "Failed to load "+file_name
			dialog.connect("popup_hide", dialog.queue_free)
			dialog.popup_centered()

func save_selection() -> void:
	if !project:
		return
	var dialog = preload("res://UI/windows/file_dialog/file_dialog.tscn").instantiate()
	add_child(dialog)
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.mt.tres;My Touch text files")
	if mt_globals.config.has_section_key("path", "project"):
		dialog.current_dir = mt_globals.config.get_value("path", "project")
	var files = await dialog.select_files()
	if files.size() == 1:
		if do_save_selection(files[0]):
			pass
#			main_window.add_recent(save_path)

func do_save_selection(filename) -> bool:
	var data : Project = Project.new()
	data.layers = layers_manager.new()
	data.layers.layers = project.layers.selected_layers
	ResourceSaver.save(data,filename)
	return true

func load_project_layer(filenames) -> void:
	if !project:
		return
	var file_name : String = ""
	for f in filenames:
		var file = FileAccess.open(f, FileAccess.READ)
		if file == null:
			continue
		file_name = file.get_path_absolute()
		var data = ResourceLoader.load(file_name,"",ResourceLoader.CACHE_MODE_IGNORE) as Project
		if data != null:
			var new_project_layer = project_layer.new()
			new_project_layer.init(file_name,default_icon,base_layer.layer_type.project)
			project.layers.add_layer(new_project_layer)
		else:
			var dialog : AcceptDialog = AcceptDialog.new()
			add_child(dialog)
			dialog.title = "Load failed!"
			dialog.dialog_text = "Failed to load "+file_name
			dialog.connect("popup_hide", dialog.queue_free)
			dialog.popup_centered()
func refresh():
	if !project:
		return
	for layer in project.layers.layers:
		layer.refresh()


func load_file(filename, name_used:bool) -> bool:
	
	var data : Project = Project.load_project(filename)
	if data != null:
		project = data
		project.name_used = name_used
		projects.append(project)
		return true
	else:
		var dialog : AcceptDialog = AcceptDialog.new()
		add_child(dialog)
		dialog.title = "Load failed!"
		dialog.dialog_text = "Failed to load "+filename
		dialog.connect("popup_hide", dialog.queue_free)
		dialog.popup_centered()
		return false

# Save

func save() -> bool:
	if !project:
		return false
	var status
	if project.save_path != "":
		status = project.save_project()
	else:
		status = await save_as()
	return status

func save_as() -> bool:
	if !project:
		return false
	#replace with preload
	var dialog = preload("res://UI/windows/file_dialog/file_dialog.tscn").instantiate()
	add_child(dialog)
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.mt.tres;My Touch text files")

	if mt_globals.config.has_section_key("path", "project"):
		dialog.current_dir = mt_globals.config.get_value("path", "project")
	var files = await dialog.select_files()
	if files.size() == 1:
		project.save_path = files[0]
		if project.save_project():
#			main_window.add_recent(save_path)
			mt_globals.config.set_value("path", "project", project.save_path.get_base_dir())
			return true
	return false



func auto_save():
	if !project:
		return
	if project.save_path != "" and project.need_save:
		project.save_project()
		get_node("/root/Editor/MessageLabel").show_message("auto saved")


func send_changed_signal() -> void:
	if !project:
		return
	project.need_save = true



func undo():
	if !project:
		return
	project.undo_redo.undo()
	get_node("/root/Editor/MessageLabel").show_message("Current Step : " + str(project.undo_redo.get_current_action() + 1))

func redo():
	if !project:
		return
	project.undo_redo.redo()
	get_node("/root/Editor/MessageLabel").show_message("Current Step : " + str(project.undo_redo.get_current_action() + 1))
	

