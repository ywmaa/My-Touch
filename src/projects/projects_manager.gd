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
		refresh()
var clipboard_file_path = "user://my_touch_clipboard.res"
var default_icon = "res://icon512.png"

func new_project(canvas_size: Vector2 = Vector2(mt_globals.default_width,mt_globals.default_height), add_default_layer: bool = true, project_name: String = "unnamed") -> void:
#	center_view()
	var new_project = Project.new()
	new_project.canvas_size = canvas_size
	new_project.layers_container = layers_manager.new()
	new_project.resources_container = resources_manager.new()
	projects.append(new_project)
	new_project.save_path = project_get_unused_save_path(project_name)
	#default layer
	#var new_layer : base_layer = base_layer.new()
	var new_image_path : String = new_project.project_folder_abs_path + "/" + default_icon.get_file()
	var texture : Texture2D = load(default_icon)
	texture.get_image().save_png(new_image_path)
	#DirAccess.copy_absolute(default_icon, new_image_path)
	if add_default_layer:
		image_layer.new().init(new_project.layers_container.get_unused_layer_name(), default_icon.get_file(), new_project)
	#new_layer.init(new_project.layers_container.get_unused_layer_name(), default_icon.get_file(), new_project ,base_layer.layer_type.image)
	brush_texture_resource.new().init("default brush texture", "default", default_icon.get_file(), new_project)
	current_project = new_project
	get_all_default_brushes()

func get_all_default_brushes():
	const main_brushes_path : String = "res://builtins/brushes"
	var brush_directories: PackedStringArray = DirAccess.get_directories_at(main_brushes_path)
	for folder in brush_directories:
		var files : PackedStringArray = DirAccess.get_files_at(main_brushes_path + "/" + folder)
		for file in files:
			if file.get_extension() == "png":
				var file_path : String = main_brushes_path + "/" + folder + "/" + file
				var new_brush_path : String = current_project.project_folder_abs_path + "/" + file
				# very costly in computation time
				#var texture : Texture2D = load(file_path)
				#texture.get_image().save_png(new_brush_path)
				
				#this works on both android and PC
				copy_png_raw(file_path, new_brush_path)
				
				# only works for pc
				#DirAccess.copy_absolute(file_path, new_brush_path)
				brush_texture_resource.new().init(file.get_file().get_basename(), "default/" + folder, file.get_file(), current_project)

func copy_png_raw(res_path: String, dest_path: String) -> bool:
	var input = FileAccess.open(res_path, FileAccess.READ)
	if not input:
		print("❌ Could not open source: ", res_path)
		return false
	var data = input.get_buffer(input.get_length())
	input.close()

	var output = FileAccess.open(dest_path, FileAccess.WRITE)
	if not output:
		print("❌ Could not open destination: ", dest_path)
		return false
	output.store_buffer(data)
	output.close()
	return true

## Creates a new project sized to the image, with the image filling the canvas.
func new_project_from_image(path: String) -> bool:
	var image := MTStorage.load_image(path)
	if image == null or image.is_empty():
		return false
	var file_name := MTStorage.image_file_name(path)
	new_project(Vector2(image.get_size()), false, MTStorage.sanitize_file_name(file_name.get_basename()))
	MTStorage.copy_file(path, current_project.project_folder_abs_path + "/" + file_name)
	var layer := image_layer.new()
	layer.init(file_name.get_basename(), file_name, current_project)
	layer.position = current_project.canvas_size / 2 # Sprites are centered
	return true

func project_get_unused_save_path(naming: String = "unnamed") -> String:
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
	var new_image_path : String = current_project.project_folder_abs_path + "/" + MTStorage.image_file_name(path)
	MTStorage.copy_file(path, new_image_path) # Copy Image to Project Folder
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
		if !MTStorage.file_exists(f):
			continue
		file_name = f
		var data = MTStorage.load_resource(file_name) as Project
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
	dialog.current_dir = get_last_project_dir()
	var files = await dialog.select_files()
	if files.size() == 1:
		if do_save_selection(files[0]):
			pass
#			main_window.add_recent(save_path)

func do_save_selection(filename) -> bool:
	var data : Project = Project.new()
	data.layers_container = layers_manager.new()
	data.resources_container = resources_manager.new()
	data.layers.layers = current_project.layers_container.selected_layers
	MTStorage.save_resource(data, filename)
	return true

func load_project_layer(filenames) -> void:
	if !current_project:
		return
	var file_name : String = ""
	for f in filenames:
		if !MTStorage.file_exists(f):
			continue
		file_name = f
		var data = MTStorage.load_resource(file_name, ResourceLoader.CACHE_MODE_IGNORE) as Project
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
	current_project.resources_container.refresh()
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
	# Unsaved projects live in a temporary user:// folder that is removed on close, ask where to save.
	if current_project.save_path != "" and !current_project.save_path.begins_with("user://"):
		status = current_project.save_project()
	else:
		status = await save_as()
	return status

## Folder the save/open dialogs start in.
func get_last_project_dir() -> String:
	var dir : String = mt_globals.config.get_value("path", "current_project", "")
	if dir == "" or MTStorage.is_saf(dir) or !DirAccess.dir_exists_absolute(dir):
		return MTStorage.projects_dir()
	return dir

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
	dialog.current_dir = get_last_project_dir()
	var project_name : String = MTStorage.display_name(current_project.save_path)
	if project_name != "":
		dialog.current_file = project_name
	var files = await dialog.select_files()
	if files.size() == 1:
		var old_file = current_project.save_path
		current_project.save_path = files[0]
		if current_project.save_project():
			if !MTStorage.is_saf(old_file) and old_file != current_project.save_path:
				old_file = ProjectSettings.globalize_path(old_file)
				var dir = DirAccess.open(old_file.get_base_dir())
				if dir and dir.file_exists(old_file.get_file()): # Remove Old MT File
					dir.remove(old_file.get_file())
			mt_globals.main_window.add_recent(current_project.save_path)
			if !MTStorage.is_saf(current_project.save_path):
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
	
