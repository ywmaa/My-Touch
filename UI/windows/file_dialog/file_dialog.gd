extends FileDialog


var left_panel = null
var volume_option = null

## On Android, skip the in-app dialog and use the system picker directly (e.g. for photos).
var android_native : bool = false

signal return_paths(path_list)

func _enter_tree() -> void:
	if MTStorage.is_android():
		# Only the app's own storage is browsable in-app, anything else goes through the system picker.
		root_subfolder = MTStorage.app_root_dir()

func _ready() -> void:
	if MTStorage.is_android():
		if file_mode != FILE_MODE_OPEN_DIR:
			add_button("Other Folder…", false, "other_folder")
			custom_action.connect(_on_custom_action)
		return
	if OS.get_name() == "iOS":
		return
	
	var vbox = get_vbox()
	var hbox = HSplitContainer.new()
	add_child(hbox)
	remove_child(vbox)
	left_panel = preload("res://UI/windows/file_dialog/left_panel.tscn").instantiate()
	hbox.add_child(left_panel)
	left_panel.connect("open_directory", set_current_dir)
	hbox.add_child(vbox)
	vbox.size_flags_horizontal = VBoxContainer.SIZE_EXPAND_FILL

	var fav_button = preload("res://UI/windows/file_dialog/fav_button.tscn").instantiate()
	vbox.get_child(0).add_child(fav_button)
	fav_button.connect("pressed", add_favorite)
	if OS.get_name() == "Windows":
		volume_option = vbox.get_child(0).get_child(3)
		if ! volume_option is OptionButton:
			volume_option = null


func get_full_current_dir() -> String:
	var prefix = ""
	if volume_option != null and volume_option.visible:
		prefix = volume_option.get_item_text(volume_option.selected)
	return prefix+get_current_dir()

func _on_FileDialog_file_selected(path) -> void:
	if !left_panel:
		emit_signal("return_paths", [ path ])
		return
	left_panel.add_recent(get_full_current_dir())
	emit_signal("return_paths", [ path ])

func _on_FileDialog_files_selected(paths) -> void:
	if !left_panel:
		emit_signal("return_paths", paths)
		return
	left_panel.add_recent(get_full_current_dir())
	emit_signal("return_paths", paths)

func _on_FileDialog_dir_selected(dir) -> void:
	emit_signal("return_paths", [ dir ])

func _on_FileDialog_popup_hide() -> void:
	emit_signal("return_paths", [ ])

func select_files() -> Array:
	if MTStorage.is_android() and android_native:
		var files := await MTStorage.pick_files(filters, file_mode == FILE_MODE_OPEN_FILES)
		queue_free()
		return Array(files)
	popup_centered()
	var result = await return_paths
	queue_free()
	return result

func add_favorite():
	if !left_panel:
		return
	left_panel.add_favorite(get_full_current_dir())

# Saving or opening outside the app folder (Android), only the chosen folder/files get shared.
func _on_custom_action(action: StringName) -> void:
	if action != "other_folder":
		return
	hide()
	match file_mode:
		FILE_MODE_SAVE_FILE:
			var file_name := MTStorage.sanitize_file_name(get_line_edit().text)
			if file_name == "":
				file_name = "unnamed"
			var ext := _first_filter_extension()
			if ext != "" and !file_name.to_lower().ends_with(ext):
				file_name += ext
			var folder := await MTStorage.pick_folder()
			if folder == "":
				emit_signal("return_paths", [ ])
				return
			emit_signal("return_paths", [ MTStorage.join(folder, file_name) ])
		_:
			var files : PackedStringArray
			if _is_project_dialog():
				files = await MTStorage.pick_project_files(file_mode == FILE_MODE_OPEN_FILES)
			else:
				files = await MTStorage.pick_files(filters, file_mode == FILE_MODE_OPEN_FILES)
			emit_signal("return_paths", Array(files))

# ".mt.tres" from "*.mt.tres;My Touch text files"
func _first_filter_extension() -> String:
	if filters.is_empty():
		return ""
	var pattern : String = filters[0].get_slice(";", 0).get_slice(",", 0).strip_edges()
	return pattern.trim_prefix("*")

# Projects need their data folder next to them, so they can't be opened as a single shared file.
func _is_project_dialog() -> bool:
	for f in filters:
		if f.contains(".mt.tres"):
			return true
	return false
