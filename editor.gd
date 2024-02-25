extends Panel
class_name MainWindow
var quitting : bool = false

var recent_files = []

var current_tab = null

var updating : bool = false
var need_update : bool = false

#@onready var projects = $VBoxContainer/ProjectTabs

@onready var layout : DockableContainer = $VBoxContainer/Layout
const SAVED_LAYOUT_PATH := "user://layout.tres"
var library
var brushes

const FPS_LIMIT_MIN = 20
const FPS_LIMIT_MAX = 500
const IDLE_FPS_LIMIT_MIN = 1
const IDLE_FPS_LIMIT_MAX = 100

const RECENT_FILES_COUNT = 15

const THEMES = [ "Dark", "Blue", "Light" ]
const EXPORT_TYPES = [ "png", "jpeg"]

const MENU = [
	{ menu="File/New Layer", command="create_add_context_menu", shortcut="Shift+A" },
	{ menu="File/New Canvas", command="new_project", shortcut="Control+N" },
	{ menu="File/Load", command="load_project", shortcut="Control+O" },
	{ menu="File/Load recent", submenu="load_recent", standalone_only=true },
	{ menu="File/-" },
	{ menu="File/Save", command="save_project", shortcut="Control+S" },
	{ menu="File/Save as...", command="save_project_as", shortcut="Control+Shift+S" },
	{ menu="File/Save all...", command="save_all_projects" },
	{ menu="File/-" },
	{ menu="File/Export", submenu="export" },
	{ menu="File/-" },
	{ menu="File/Refresh", command="refresh", shortcut="Control+R" },
	{ menu="File/Open File Location", command="open_file_location" },
	{ menu="File/-" },
	{ menu="File/Close", command="close_project", shortcut="Control+Shift+Q" },
	{ menu="File/Quit", command="quit", shortcut="Control+Q" },

	{ menu="Edit/Undo", command="edit_undo", shortcut="Control+Z" },
	{ menu="Edit/Redo", command="edit_redo", shortcut="Control+Shift+Z" },
	{ menu="Edit/-" },
	{ menu="Edit/Cut", command="edit_cut", shortcut="Control+X" },
	{ menu="Edit/Copy", command="edit_copy", shortcut="Control+C" },
	{ menu="Edit/Paste", command="edit_paste", shortcut="Control+V" },
	{ menu="Edit/Duplicate", command="edit_duplicate", shortcut="Control+D" },
	{ menu="Edit/-" },
	{ menu="Edit/Select All", command="edit_select_all", shortcut="A" },
	{ menu="Edit/Select None", command="edit_select_none", shortcut="Alt+A" },
	{ menu="Edit/Invert Selection", command="edit_select_invert", shortcut="Control+I" },
	{ menu="Edit/Parent Layer", command="parent_layer", shortcut="Control+P" },
	{ menu="Edit/-" },
	{ menu="Edit/Load Selection", command="edit_load_selection" },
	{ menu="Edit/Save Selection", command="edit_save_selection" },
	{ menu="Edit/-" },
	{ menu="Edit/Set theme", submenu="set_theme" },
	{ menu="Edit/Preferences", command="edit_preferences" },

	{ menu="View/Center view", command="view_center", shortcut="C" },
	{ menu="View/Reset zoom", command="view_reset_zoom", shortcut="Control+0" },
	{ menu="View/-" },
	{ menu="View/Touch Friendly Layout", command="touch_mode_switch", shortcut="Control+Space" },
	{ menu="View/Default Layout", command="default_mode_switch", shortcut="" },
	{ menu="View/User Layout", command="user_mode_switch", shortcut="" },
	{ menu="View/-" },
	{ menu="View/New floating window", command="new_window" },
	{ menu="View/New dockable window", command="new_dock_window" },
	{ menu="View/Fullscreen", command="fullscreen", shortcut="F11"},

	{ menu="Help/User manual", command="show_doc", shortcut="F1" },
	{ menu="Help/Report a bug", command="bug_report" },
	{ menu="Help/" },
	{ menu="Help/About", command="about" }
]

@onready var left_cursor: Sprite2D = $LeftCursor

func _input(event: InputEvent) -> void:
	left_cursor.position = get_global_mouse_position() + Vector2(-32, 32)
	for tool in ToolsManager.TOOLS:
		if tool.tool_button_shortcut == event.as_text():
			ToolsManager.assign_tool(tool.tool_name,ToolsManager.TOOLS.find(tool))

func _enter_tree():
	mt_globals.main_window = self


#func _process(_delta):
#	layout._update_layout_with_children()
#	print(layout.get_tab_count())
func _ready() -> void:
	set_physics_process(false)
	get_tree().set_auto_accept_quit(false)
	
	if mt_globals.get_config("locale") == "":
		mt_globals.set_config("locale", TranslationServer.get_locale())

	on_config_changed()
	get_screen_position()
	
	

	# Restore the window position/size if values are present in the configuration cache
	if mt_globals.config.has_section_key("window", "screen"):
		DisplayServer.window_set_current_screen(mt_globals.config.get_value("window", "screen"))
	if mt_globals.config.has_section_key("window", "maximized"):
		DisplayServer.window_set_mode(mt_globals.config.get_value("window", "maximized"))
	if DisplayServer.window_get_mode() != DisplayServer.WindowMode.WINDOW_MODE_MAXIMIZED:
		if mt_globals.config.has_section_key("window", "position"):
			DisplayServer.window_set_position(mt_globals.config.get_value("window", "position"))
		if mt_globals.config.has_section_key("window", "size"):
			DisplayServer.window_set_size(mt_globals.config.get_value("window", "size"))

	# Restore the theme
	var theme_name : String = "dark"
	if mt_globals.config.has_section_key("window", "theme"):
		theme_name = mt_globals.config.get_value("window", "theme")
	set_app_theme(theme_name)

	
	# Set a minimum window size to prevent UI elements from collapsing on each other.
	DisplayServer.window_set_min_size(Vector2i(1024, 600))
	# Set window title
	DisplayServer.window_set_title(str(ProjectSettings.get_setting("application/config/name")+" v"+ProjectSettings.get_setting("application/config/actual_release")))


#	# Load recent projects
	load_recents()
#
	# Create menus
	mt_globals.menu_manager.create_menus(MENU, self, $VBoxContainer/TopBar/Menu)

	new_project()

	do_load_projects(OS.get_cmdline_args())
	
	get_viewport().connect("files_dropped", on_files_dropped)
	
	add_child(context_menu)
	
	var saved_layout : DockableLayout = ResourceLoader.load(SAVED_LAYOUT_PATH)
	if saved_layout:
		layout.set_layout(saved_layout.clone())
	else:
		print("Warning: Can't User Load Layout")
		default_mode_switch()
		

var context_menu : PopupMenu = PopupMenu.new()

func create_add_context_menu(pos: Vector2 = get_global_mouse_position()):
	context_menu.clear()
	context_menu.add_item("Import Image")
	context_menu.add_item("Load Project As Image")
	context_menu.add_separator()
	context_menu.add_item("Brush Layer")
	context_menu.add_separator()
	context_menu.add_item("Text Layer")
	context_menu.add_item("Selection Layer")
	
	
	context_menu.connect("id_pressed",add_context_menu_item_pressed)
	context_menu.position = pos
	context_menu.visible = true

func add_context_menu_item_pressed(id: int):
	match id:
		0: #import image
			if !ProjectsManager.current_project:
				return
			import_image()
		1: #project layer
			if !ProjectsManager.current_project:
				return
			edit_load_project_as_image()
		3: #project layer
			if !ProjectsManager.current_project:
				return
			#var new_paint_layer = paint_layer.new()
			#new_paint_layer.init(ProjectsManager.current_project.layers_container.get_unused_layer_name(),"", ProjectsManager.current_project,base_layer.layer_type.brush)
			paint_layer.new().init(ProjectsManager.current_project.layers_container.get_unused_layer_name(),"", ProjectsManager.current_project)
		5: #text layer
			if !ProjectsManager.current_project:
				return
			text_layer.new().init(ProjectsManager.current_project.layers_container.get_unused_layer_name(), ProjectsManager.current_project)
			#var new_text_layer = text_layer.new()
			#new_text_layer.init(ProjectsManager.current_project.layers_container.get_unused_layer_name(),ProjectsManager.default_icon, ProjectsManager.current_project, base_layer.layer_type.text)
		6: #selection layer
			if !ProjectsManager.current_project:
				return
			selection_layer.new().init(ProjectsManager.current_project.layers_container.get_unused_layer_name(),ProjectsManager.default_icon, ProjectsManager.current_project)
			#var new_selection_layer = selection_layer.new()
			#new_selection_layer.init(ProjectsManager.current_project.layers_container.get_unused_layer_name(),ProjectsManager.default_icon, ProjectsManager.current_project, base_layer.layer_type.mask)

	
func on_config_changed() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if mt_globals.get_config("vsync") else DisplayServer.VSYNC_DISABLED)
	# Convert FPS to microseconds per frame.
	# Clamp the FPS to reasonable values to avoid locking up the UI.
# warning-ignore:narrowing_conversion
	OS.low_processor_usage_mode_sleep_usec = (1.0 / clamp(mt_globals.get_config("fps_limit"), FPS_LIMIT_MIN, FPS_LIMIT_MAX)) * 1_000_000
	# locale
	var locale = mt_globals.get_config("locale")
	if locale != "" and locale != TranslationServer.get_locale():
		TranslationServer.set_locale(locale)
		get_tree().call_group("updated_from_locale", "update_from_locale")
	
	
	var ui_scale = mt_globals.get_config("ui_scale")
	if ui_scale <= 0:
		# If scale is set to 0 (auto), scale everything if the display requires it (crude hiDPI support).
		# This prevents UI elements from being too small on hiDPI displays.
		ui_scale = 2 if DisplayServer.screen_get_dpi() >= 192 and DisplayServer.window_get_size().x >= 2048 else 1
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	get_tree().root.content_scale_size = Vector2i()
	get_tree().root.content_scale_factor = ui_scale
	

	
#func get_current_graph_edit() -> MTGraph:
#	var graph_edit = projects.get_current_tab_control()
#	if graph_edit != null and graph_edit.has_method("get_graph_edit"):
#		return graph_edit.get_graph_edit()
#	return null

func _notification(what : int) -> void:
	match what:
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
			# Limit FPS to decrease CPU/GPU usage while the window is unfocused.
# warning-ignore:narrowing_conversion
			OS.low_processor_usage_mode_sleep_usec = (1.0 / clamp(mt_globals.get_config("idle_fps_limit"), IDLE_FPS_LIMIT_MIN, IDLE_FPS_LIMIT_MAX)) * 1_000_000
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
			# Return to the normal FPS limit when the window is focused.
# warning-ignore:narrowing_conversion
			OS.low_processor_usage_mode_sleep_usec = (1.0 / clamp(mt_globals.get_config("fps_limit"), FPS_LIMIT_MIN, FPS_LIMIT_MAX)) * 1_000_000
		1006: # NOTIFICATION_WM_QUIT_REQUEST
			await get_tree().process_frame
			quit()

# -----------------------------------------------------------------------
#                             File menu
# -----------------------------------------------------------------------

func new_project() -> void:
	ProjectsManager.new_project()


func load_project() -> void:
	var dialog = preload("res://UI/windows/file_dialog/file_dialog.tscn").instantiate()
	add_child(dialog)
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	dialog.add_filter("*.mt.tres;My Touch text files")

	if mt_globals.config.has_section_key("path", "project"):
		dialog.current_dir = mt_globals.config.get_value("path", "project")
	var files = await dialog.select_files()
	if files.size() > 0:
		do_load_projects(files)

func do_load_projects(filenames) -> void:
	var file_name : String = ""
	for f in filenames:
		var file = FileAccess.open(f, FileAccess.READ)
		if file == null:
			continue
		file_name = file.get_path_absolute()
		file = null
		do_load_project(file_name)
	if file_name != "":
		mt_globals.config.set_value("path", "project", file_name.get_base_dir())

func do_load_project(file_name) -> bool:
	var status : bool = false
	match file_name.get_extension():
		"tres":
			status = do_load_mt(file_name)
	if status:
		add_recent(file_name)
	else:
		remove_recent(file_name)
	return status
func do_load_mt(filename : String) -> bool:
	var name_used = false
	var name_without_path = filename.substr(filename.rfind("/")+1)
	for project in ProjectsManager.projects:
		if project.save_path == filename:
			ProjectsManager.current_project = project
			return true
		if project.save_path.substr(filename.rfind("/")+1) == name_without_path:
			project.name_used = true
			name_used = true
	ProjectsManager.load_file(filename, name_used)
	return true

func create_menu_load_recent(menu) -> void:
	menu.clear()
	if recent_files.is_empty():
		menu.add_item("No items found", 0)
		menu.set_item_disabled(0, true)
	else:
		for i in recent_files.size():
			menu.add_item(recent_files[i], i)
		if !menu.is_connected("id_pressed", _on_LoadRecent_id_pressed):
			menu.connect("id_pressed", _on_LoadRecent_id_pressed)

func _on_LoadRecent_id_pressed(id) -> void:
	do_load_project(recent_files[id])

func load_recents() -> void:
	var f = FileAccess.open("user://recent_files.cache", FileAccess.READ)
	if f != null:
		recent_files = JSON.parse_string(f.get_as_text())
		
		f = null

func save_recents() -> void:
	var f = FileAccess.open("user://recent_files.cache", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(recent_files))
	f = null

func add_recent(path, save = true) -> void:
	remove_recent(path, false)
	recent_files.push_front(path)
	while recent_files.size() > RECENT_FILES_COUNT:
		recent_files.pop_back()
	if save:
		save_recents()

func remove_recent(path, save = true) -> void:
	while true:
		var index = recent_files.find(path)
		if index >= 0:
			recent_files.remove_at(index)
		else:
			break
	if save:
		save_recents()

func save_project() -> bool:
	return await ProjectsManager.save()

func save_project_as() -> bool:
	return await ProjectsManager.save_as()

func save_all_projects() -> void:
	for project in ProjectsManager.projects:
		project.save_project()




func create_menu_export(menu : PopupMenu):
	menu.clear()
	for E in EXPORT_TYPES:
		menu.add_item(E)
	if !menu.is_connected("id_pressed", _on_export_id_pressed):
		menu.connect("id_pressed", _on_export_id_pressed)
func _on_export_id_pressed(id) -> void:
	var export_name : String = EXPORT_TYPES[id].to_lower()
	match export_name:
		"png":
			export_png_image()
		"jpeg":
			export_jpeg_image()
func export_png_image():
	if !ProjectsManager.current_project:
		return
	# Prompt for a target PNG file
	var dialog = preload("res://UI/windows/file_dialog/file_dialog.tscn").instantiate()
	add_child(dialog)
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.png;PNG image file")
	var files = await dialog.select_files()
	if files.size() != 1:
		return
	# Generate the image
	var rendering_window : Viewport = $AppRender
	var image : Image = Image.new() #create(graph_edit.canvas_size.x,graph_edit.canvas_size.y,true,Image.FORMAT_BPTC_RGBA)
	# Wait until the frame has finished before getting the texture.
	await RenderingServer.frame_post_draw
	image = rendering_window.get_texture().get_image()
	image.save_png(files[0])
	
func export_jpeg_image():
	if !ProjectsManager.current_project:
		return
	# Prompt for a target PNG file
	var dialog = preload("res://UI/windows/file_dialog/file_dialog.tscn").instantiate()
	add_child(dialog)
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.jpeg;JPEG image file")
	var files = await dialog.select_files()
	if files.size() != 1:
		return
	# Generate the image
	var rendering_window : Viewport = $AppRender
	var image : Image = Image.new()
	# Wait until the frame has finished before getting the texture.
	await RenderingServer.frame_post_draw
	image = rendering_window.get_texture().get_image()
	image.save_jpg(files[0])
func refresh():
	ProjectsManager.refresh()
func open_file_location():
	if ProjectsManager.current_project != null:
		if ProjectsManager.current_project.save_path != "":
			var path = ProjectsManager.current_project.save_path
			var path_array = path.split("/")
			path_array.remove_at(path_array.size()-1)
			path = ""
			for s in path_array:
				path += s + "/"
			
			OS.shell_open(path)
func close_project() -> void:
	ProjectsManager.close_project(ProjectsManager.projects.find(ProjectsManager.current_project))

func quit() -> void:
	if quitting:
		return
	quitting = true
	var dialog = preload("res://UI/windows/accept_dialog/accept_dialog.tscn").instantiate()
	dialog.dialog_text = "Quit My Touch?"
	dialog.add_cancel_button("Cancel")
	add_child(dialog)
	if mt_globals.get_config("confirm_quit"):
		var result = await dialog.ask()
		print(result)
		if result == "cancel":
			quitting = false
			return
	if mt_globals.get_config("confirm_close_project"):
		var result = await $VBoxContainer/ProjectTabs.check_save_tabs()
		if !result:
			quitting = false
			return
	dim_window()
	# Save the window position and size to remember it when restarting the application
	mt_globals.config.set_value("window", "screen", DisplayServer.window_get_current_screen())
	mt_globals.config.set_value("window", "maximized", DisplayServer.window_get_mode())
	mt_globals.config.set_value("window", "position", DisplayServer.window_get_position())
	mt_globals.config.set_value("window", "size", DisplayServer.window_get_size())
	#Save Layout
	if layout.layout.resource_name != "default_layout" and layout.layout.resource_name != "touch_layout":
		ResourceSaver.save(layout.layout, SAVED_LAYOUT_PATH)
	get_tree().quit()
	quitting = false

func dim_window() -> void:
	# Darken the UI to denote that the application is currently exiting
	# (it won't respond to user input in this state).
	modulate = Color(0.5, 0.5, 0.5)

# -----------------------------------------------------------------------
#                             Edit menu
# -----------------------------------------------------------------------
func edit_undo() -> void:
	ProjectsManager.undo()

func edit_undo_is_disabled() -> bool:
	return !ProjectsManager.can_undo()

func edit_redo() -> void:
	ProjectsManager.redo()

func edit_redo_is_disabled() ->  bool:
	return !ProjectsManager.can_redo()

func edit_cut() -> void:
	ProjectsManager.cut()
func edit_copy() -> void:
	ProjectsManager.copy()

func edit_paste() -> void:
	ProjectsManager.paste()

func edit_duplicate() -> void:
	ProjectsManager.duplicate_selected()

func edit_select_all() -> void:
	ProjectsManager.select_all()

func edit_select_none() -> void:
	ProjectsManager.select_none()

func edit_select_invert() -> void:
	ProjectsManager.select_invert()
func parent_layer() -> void:
	var selected_layers = ProjectsManager.current_project.layers_container.selected_layers
	
	if selected_layers.size() < 2:
		return
	
	for i in selected_layers.size():
		if i == 0:
			continue
		ProjectsManager.current_project.layers_container.add_layer(selected_layers[i], selected_layers[0])
func edit_load_selection() -> void:
	var dialog = preload("res://UI/windows/file_dialog/file_dialog.tscn").instantiate()
	add_child(dialog)
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	dialog.add_filter("*.mt.tres;My Touch text files")

	if mt_globals.config.has_section_key("path", "project"):
		dialog.current_dir = mt_globals.config.get_value("path", "project")
	var files = await dialog.select_files()
	if files.size() > 0:
		ProjectsManager.load_selection(files)

func edit_save_selection():
	return await ProjectsManager.save_selection()

func edit_load_project_as_image() -> void:
	var dialog = preload("res://UI/windows/file_dialog/file_dialog.tscn").instantiate()
	add_child(dialog)
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	dialog.add_filter("*.mt.tres;My Touch text files")

	if mt_globals.config.has_section_key("path", "project"):
		dialog.current_dir = mt_globals.config.get_value("path", "project")
	var files = await dialog.select_files()
	if files.size() > 0:
		ProjectsManager.load_project_layer(files)

func set_app_theme(theme_name : String) -> void:
	theme = load("res://UI/theme/"+theme_name+".tres")

func _on_SetTheme_id_pressed(id) -> void:
	var theme_name : String = THEMES[id].to_lower()
	set_app_theme(theme_name)
	mt_globals.config.set_value("window", "theme", theme_name)

func create_menu_set_theme(menu) -> void:
	menu.clear()
	for t in THEMES:
		menu.add_item(t)
	if !menu.is_connected("id_pressed", _on_SetTheme_id_pressed):
		menu.connect("id_pressed", _on_SetTheme_id_pressed)

func edit_preferences() -> void:
	var dialog = load("res://UI/windows/preferences/preferences.tscn").instantiate()
	add_child(dialog)
	dialog.connect("config_changed", on_config_changed)
	dialog.edit_preferences(mt_globals.config)


# -----------------------------------------------------------------------
#                             View menu
# -----------------------------------------------------------------------
signal signal_view_center
signal signal_view_reset_zoom

func view_center() -> void:
	signal_view_center.emit()

func view_reset_zoom() -> void:
	signal_view_reset_zoom.emit()


func touch_mode_switch() -> void:
	var saved_layout : DockableLayout = load("res://touch_editor_layout.tres")
	if saved_layout:
		var clone = saved_layout.clone()
		clone.resource_name = "touch_layout"
		layout.set_layout(clone)
	else:
		print("Error: Can't Load Layout")
func default_mode_switch() -> void:
	var saved_layout : DockableLayout = load("res://normal_editor_layout.tres")
	if saved_layout:
		var clone = saved_layout.clone()
		clone.resource_name = "default_layout"
		layout.set_layout(clone)
	else:
		print("Error: Can't Load Layout")
func user_mode_switch() -> void:
	var saved_layout : DockableLayout = ResourceLoader.load(SAVED_LAYOUT_PATH)
	if saved_layout:
		layout.set_layout(saved_layout.clone())
	else:
		print("Error: Can't Load Layout")

var window_packed_scene = preload("res://UI/windows/undocked_window/undocked_window.tscn")
func new_window():
	get_viewport().gui_embed_subwindows = false
	var window : Window = window_packed_scene.instantiate()
	add_child(window)
func new_dock_window():
	var control := preload("res://UI/windows/windows_manager/WindowsManager.tscn").instantiate()
	layout.add_child(control, true)
	await layout.sort_children
	layout.set_control_as_current_tab(control)

func fullscreen():
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
# -----------------------------------------------------------------------
#                             Help menu
# -----------------------------------------------------------------------
func get_doc_dir() -> String:
	var base_dir = MTPaths.get_resource_dir().replace("\\", "/")
	# In release builds, documentation is expected to be located in
	# a subdirectory of the program directory
	var release_doc_path = base_dir.plus_file("doc")
	# In development, documentation is part of the project files.
	# We can use a globalized `res://` path here as the project isn't exported.
	var devel_doc_path = ProjectSettings.globalize_path("res://doc/_build/html")
	for p in [ release_doc_path, devel_doc_path ]:
		if FileAccess.file_exists(p+"/index.html"):
			return p
	return ""

func show_doc() -> void:
	var doc_dir = get_doc_dir()
	if doc_dir != "":
		OS.shell_open(doc_dir+"/index.html")

func bug_report() -> void:
	OS.shell_open("https://github.com/ywmaa/My-Touch/issues")

func about() -> void:
	#replace with preload
	var about_box = load("res://UI/windows/about/about.tscn").instantiate()
	add_child(about_box)
	about_box.connect("popup_hide", about_box.queue_free)
	about_box.popup_centered()







#image import
func import_image() -> void:
	var dialog = preload("res://UI/windows/file_dialog/file_dialog.tscn").instantiate()
	add_child(dialog)
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	dialog.add_filter("*.jpg,*.jpeg;JPEG Image")
	dialog.add_filter("*.png;PNG Image")
	dialog.add_filter("*.svg;SVG Image")
	dialog.add_filter("*.tga;TGA Image")
	dialog.add_filter("*.webp;WebP Image")
	var files = await dialog.select_files()
	if files.size() > 0:
		on_files_dropped(files)

#Handle dropped files
func on_files_dropped(files : PackedStringArray) -> void:
	for f in files:
		var file = FileAccess.open(f, FileAccess.READ)
		if file == null:
			continue
		f = file.get_path_absolute()
		match f.get_extension():
			"tres":
				do_load_project(f)
			"jpg", "jpeg", "png", "svg", "webp":
				ProjectsManager.on_import_image_file(f)



