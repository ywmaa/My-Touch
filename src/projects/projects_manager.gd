extends Node

var projects : Array[Project]

var current_project : Project:
	set(value):
		if current_project and mt_globals.get_config("save_inactive_project"):
			current_project.save_project()
		current_project = value
		if !current_project:
			return
		if !current_project.undo_redo:
			current_project.undo_redo = UndoRedo.new()
var clipboard_file_path = "user://my_touch_clipboard.res"
var default_icon = "res://icon.png"

func new_project() -> void:
#	center_view()
	current_project = Project.new()
	current_project.canvas_size = Vector2(mt_globals.default_width,mt_globals.default_height)
	current_project.layers_container = layers_manager.new()
	projects.append(current_project)
	current_project.save_path = project_get_unused_save_path()
	#default layer
	#var new_layer : base_layer = base_layer.new()
	var new_image_path : String = current_project.project_folder_abs_path + "/" + default_icon.get_file()
	DirAccess.copy_absolute(default_icon, new_image_path)
	image_layer.new().init(current_project.layers_container.get_unused_layer_name(), default_icon.get_file(), current_project)
	#new_layer.init(current_project.layers_container.get_unused_layer_name(), default_icon.get_file(), current_project ,base_layer.layer_type.image)
	
func project_get_unused_save_path() -> String:
	var naming = "unnamed"
	var return_name : String
	var count = 0
	return_name = naming
	for p in projects:
		if p.save_path.get_file().get_basename().get_basename() == return_name:
			count += 1
		if count > 0:
			return_name = naming + " " + str(count)
	return "user://" + return_name + ".mt.tres"

func close_project(index:int):
	if projects.size() > 1:
		if projects[index] == current_project:
			if index-1 < 0:
				current_project = projects[index+1]
			else:
				current_project = projects[index-1]
		projects.remove_at(index)
	else:
		current_project = null
		projects.clear()

func on_import_image_clipboard():
	if !current_project:
		return
	var new_image_path : String = current_project.project_folder_abs_path + "/" + current_project.layers_container.get_unused_layer_name() + ".png"
	DisplayServer.clipboard_get_image().save_png(new_image_path)
	image_layer.new().init(current_project.layers_container.get_unused_layer_name(), new_image_path.get_file(), current_project)



func on_import_image_file(path:String):
	if !current_project:
		return
	#var new_layer : base_layer = base_layer.new()
	var new_image_path : String = current_project.project_folder_abs_path + "/" + path.get_file()
	DirAccess.copy_absolute(path, new_image_path) # Move Image to Project Folder
	image_layer.new().init(current_project.layers_container.get_unused_layer_name(), new_image_path.get_file(), current_project)
	#new_layer.init(current_project.layers_container.get_unused_layer_name(), new_image_path.get_file(), current_project, base_layer.layer_type.image)

# Cut / copy / paste / duplicate

func remove_selection() -> void:
	if !current_project:
		return
	
	var undo_redo : UndoRedo = current_project.undo_redo
	current_project.need_save = true
	for selection in current_project.layers_container.selected_layers:
		undo_redo.create_action("Remove Selection")
		undo_redo.add_do_method(current_project.layers_container.remove_layer.bind(selection))
		
		undo_redo.add_undo_method(current_project.layers_container.add_layer.bind(selection))
		undo_redo.add_undo_method(current_project.layers_container.select_layer.bind(selection))
		
		undo_redo.commit_action(true)
		

func cut() -> void:
	copy()
	remove_selection()
	

func copy() -> void:
	if !current_project:
		return
	var clipboard_data : mt_clipboard = mt_clipboard.new()
	clipboard_data.layers = current_project.layers_container.selected_layers
	ResourceSaver.save(clipboard_data, clipboard_file_path)

func paste(duplicate:bool = false) -> void:
	if !current_project:
		return
	current_project.need_save = true
	var clipboard_data = ResourceLoader.load(clipboard_file_path) as mt_clipboard
	var paste_parent = current_project.layers_container.selected_layers.back().parent if duplicate else current_project.layers_container.selected_layers.back()
	
	for layer in clipboard_data.layers:
		current_project.layers_container.duplicate_layer(layer, paste_parent)

func duplicate_selected() -> void:
	copy()
	paste(true)

func select_all():
	if !current_project:
		return
	current_project.layers_container.selected_layers = current_project.layers_container.layers
func select_none():
	if !current_project:
		return
	current_project.layers_container.selected_layers = []
func select_invert():
	if !current_project:
		return
	var inverted_selections : Array[base_layer] = []
	for layer in current_project.layers_container.layers:
		if layer in current_project.layers_container.selected_layers:
			continue
		inverted_selections.append(layer)
	current_project.layers_container.selected_layers = inverted_selections
func load_selection(filenames) -> void:
	if !current_project:
		return
	var file_name : String = ""
	for f in filenames:
		var file = FileAccess.open(f, FileAccess.READ)
		if file == null:
			continue
		file_name = file.get_path_absolute()
		var data = ResourceLoader.load(file_name) as Project
		if data != null:
			current_project.layers_container.layers.append_array(data.layers.layers)
			current_project.need_save = true
		else:
			var dialog : AcceptDialog = AcceptDialog.new()
			add_child(dialog)
			dialog.title = "Load failed!"
			dialog.dialog_text = "Failed to load "+file_name
			dialog.connect("popup_hide", dialog.queue_free)
			dialog.popup_centered()

func save_selection() -> void:
	if !current_project:
		return
	var dialog = preload("res://UI/windows/file_dialog/file_dialog.tscn").instantiate()
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.mt.tres;My Touch text files")
	add_child(dialog)
	if mt_globals.config.has_section_key("path", "current_project"):
		dialog.current_dir = mt_globals.config.get_value("path", "current_project")
	var files = await dialog.select_files()
	if files.size() == 1:
		if do_save_selection(files[0]):
			pass
#			main_window.add_recent(save_path)

func do_save_selection(filename) -> bool:
	var data : Project = Project.new()
	data.layers = layers_manager.new()
	data.layers.layers = current_project.layers_container.selected_layers
	ResourceSaver.save(data,filename)
	return true

func load_project_layer(filenames) -> void:
	if !current_project:
		return
	var file_name : String = ""
	for f in filenames:
		var file = FileAccess.open(f, FileAccess.READ)
		if file == null:
			continue
		file_name = file.get_path_absolute()
		var data = ResourceLoader.load(file_name,"",ResourceLoader.CACHE_MODE_IGNORE) as Project
		if data != null:
			project_layer.new().init(file_name, file_name, current_project)
			#var new_project_layer = project_layer.new()
			#new_project_layer.init(file_name, default_icon, current_project)
		else:
			var dialog : AcceptDialog = AcceptDialog.new()
			add_child(dialog)
			dialog.title = "Load failed!"
			dialog.dialog_text = "Failed to load "+file_name
			dialog.connect("popup_hide", dialog.queue_free)
			dialog.popup_centered()
func refresh():
	if !current_project:
		return
	mt_globals.main_window.get_node("AppRender/Canvas").rerender()


func load_file(filename, name_used:bool) -> bool:
	
	var data : Project = Project.load_project(filename)
	if data != null:
		current_project = data
		current_project.name_used = name_used
		projects.append(current_project)
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
	if !current_project:
		return false
	var status
	if current_project.save_path != "":
		status = current_project.save_project()
	else:
		status = await save_as()
	return status

func save_as() -> bool:
	if !current_project:
		return false
	#replace with preload
	var dialog = preload("res://UI/windows/file_dialog/file_dialog.tscn").instantiate()
	#add_child(dialog)
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.mt.tres;My Touch text files")
	add_child(dialog)
	if mt_globals.config.has_section_key("path", "current_project"):
		dialog.current_dir = mt_globals.config.get_value("path", "current_project")
	var files = await dialog.select_files()
	if files.size() == 1:
		var old_file = ProjectSettings.globalize_path(current_project.save_path)
		current_project.save_path = files[0]
		if current_project.save_project():
			var dir = DirAccess.open(old_file.get_base_dir())
			if dir.file_exists(old_file.get_file()): # Remove Old MT File
				dir.remove(old_file.get_file())
			mt_globals.main_window.add_recent(current_project.save_path)
			mt_globals.config.set_value("path", "current_project", current_project.save_path.get_base_dir())
			return true
	return false



func auto_save():
	if !current_project:
		return
	if current_project.save_path != "" and current_project.need_save:
		current_project.save_project()
		get_node("/root/Editor/MessageLabel").show_message("auto saved")


func send_changed_signal() -> void:
	if !current_project:
		return
	current_project.need_save = true


func can_undo() -> bool:
	if !current_project:
		return false
	return current_project.undo_redo.has_undo()
func can_redo() -> bool:
	if !current_project:
		return false
	return current_project.undo_redo.has_redo()

func undo():
	if !current_project:
		return
	current_project.undo_redo.undo()
	get_node("/root/Editor/MessageLabel").show_message("Current Step : " + str(current_project.undo_redo.get_current_action() + 1))

func redo():
	if !current_project:
		return
	current_project.undo_redo.redo()
	get_node("/root/Editor/MessageLabel").show_message("Current Step : " + str(current_project.undo_redo.get_current_action() + 1))
	
