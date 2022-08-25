extends Panel
var quitting : bool = false

var recent_files = []

var current_tab = null

var updating : bool = false
var need_update : bool = false

@onready var projects = $VBoxContainer/Layout/SplitRight/ProjectsPanel/Projects

@onready var layout = $VBoxContainer/Layout
var library
var hierarchy
var brushes

const FPS_LIMIT_MIN = 20
const FPS_LIMIT_MAX = 500
const IDLE_FPS_LIMIT_MIN = 1
const IDLE_FPS_LIMIT_MAX = 100

const RECENT_FILES_COUNT = 15

const THEMES = [ "Dark", "Default", "Light" ]

const MENU = [
	{ menu="File/New Canvas", command="new_canvas", shortcut="Control+N" },
	{ menu="File/Load", command="load_project", shortcut="Control+O" },
	{ menu="File/Load recent", submenu="load_recent", standalone_only=true },
	{ menu="File/-" },
	{ menu="File/Save", command="save_project", shortcut="Control+S" },
	{ menu="File/Save as...", command="save_project_as", shortcut="Control+Shift+S" },
	{ menu="File/Save all...", command="save_all_projects" },
	{ menu="File/-" },
	{ menu="File/Export", submenu="export" },
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
	{ menu="Edit/Select All", command="edit_select_all", shortcut="Control+A" },
	{ menu="Edit/Select None", command="edit_select_none", shortcut="Control+Shift+A" },
	{ menu="Edit/Invert Selection", command="edit_select_invert", shortcut="Control+I" },
	{ menu="Edit/-" },
	{ menu="Edit/Load Selection", command="edit_load_selection" },
	{ menu="Edit/Save Selection", command="edit_save_selection" },
	{ menu="Edit/-" },
	{ menu="Edit/Set theme", submenu="set_theme" },
	{ menu="Edit/Preferences", command="edit_preferences" },

	{ menu="View/Center view", command="view_center", shortcut="C" },
	{ menu="View/Reset zoom", command="view_reset_zoom", shortcut="Control+0" },
	{ menu="View/-" },
	{ menu="View/Show or Hide side panels", command="toggle_side_panels", shortcut="Control+Space" },
	{ menu="View/Panels", submenu="show_panels" },

	{ menu="Tools/Create", submenu="create" },
	{ menu="Tools/-" },
	{ menu="Tools/Create a screenshot of the current graph", command="generate_graph_screenshot", mode="material" },
	{ menu="Tools/Paint project settings", command="paint_project_settings", mode="paint" },
	#{ menu="Tools", command="generate_screenshots", description="Generate screenshots for the library nodes", mode="material" },

	{ menu="Help/User manual", command="show_doc", shortcut="F1" },
	{ menu="Help/Show selected library item documentation", command="show_library_item_doc", shortcut="Control+F1" },
	{ menu="Help/Report a bug", command="bug_report" },
	{ menu="Help/" },
	{ menu="Help/About", command="about" }
]

func _ready() -> void:
	
	get_tree().set_auto_accept_quit(false)
	
	if mt_globals.get_config("locale") == "":
		mt_globals.set_config("locale", TranslationServer.get_locale())

	on_config_changed()

	# Restore the window position/size if values are present in the configuration cache
	if mt_globals.config.has_section_key("window", "screen"):
		DisplayServer.window_set_current_screen(mt_globals.config.get_value("window", "screen"))
	if mt_globals.config.has_section_key("window", "maximized"):
		DisplayServer.window_set_mode(mt_globals.config.get_value("window", "maximized"))
	
	if !Window.MODE_MAXIMIZED:
		if mt_globals.config.has_section_key("window", "position"):
			DisplayServer.window_set_position(mt_globals.config.get_value("window", "position"))
		if mt_globals.config.has_section_key("window", "size"):
			DisplayServer.window_set_size(mt_globals.config.get_value("window", "size"))

	# Restore the theme
	var theme_name : String = "dark"
	if mt_globals.config.has_section_key("window", "theme"):
		theme_name = mt_globals.config.get_value("window", "theme")
	set_app_theme(theme_name)
	# In HTML5 export, copy all examples to the filesystem
	if OS.get_name() == "HTML5":
		print("Copying samples")
		var dir : Directory = Directory.new()
		dir.make_dir("/examples")
		dir.open("res://examples/")
		dir.list_dir_begin()
		while true:
			var f = dir.get_next()
			if f == "":
				break
			if f.ends_with(".mt"):
				print(f)
				dir.copy("res://examples/"+f, "/examples/"+f)
		print("Done")



	# Set a minimum window size to prevent UI elements from collapsing on each other.
	DisplayServer.window_set_min_size(Vector2i(1024, 600))
	# Set window title
	DisplayServer.window_set_title(str(ProjectSettings.get_setting("application/config/name")+" v"+ProjectSettings.get_setting("application/config/actual_release")))


	layout.load_panels()
	hierarchy = get_panel("Hierarchy")
#
#	# Load recent projects
#	load_recents()
#
	# Create menus
	mt_globals.menu_manager.create_menus(MENU, self, $VBoxContainer/TopBar/Menu)

#	new_project()
#
#	do_load_projects(OS.get_cmdline_args())
#
#	get_tree().connect("files_dropped", self, "on_files_dropped")
#
func on_config_changed() -> void:
	DisplayServer.window_set_vsync_mode(mt_globals.get_config("vsync"))
	# Convert FPS to microseconds per frame.
	# Clamp the FPS to reasonable values to avoid locking up the UI.
# warning-ignore:narrowing_conversion
	OS.low_processor_usage_mode_sleep_usec = (1.0 / clamp(mt_globals.get_config("fps_limit"), FPS_LIMIT_MIN, FPS_LIMIT_MAX)) * 1_000_000
	# locale
	var locale = mt_globals.get_config("locale")
	if locale != "" and locale != TranslationServer.get_locale():
		TranslationServer.set_locale(locale)
		get_tree().call_group("updated_from_locale", "update_from_locale")
	
	var scale = mt_globals.get_config("ui_scale")
	if scale <= 0:
		# If scale is set to 0 (auto), scale everything if the display requires it (crude hiDPI support).
		# This prevents UI elements from being too small on hiDPI displays.
		scale = 2 if DisplayServer.screen_get_dpi() >= 192 and DisplayServer.window_get_size().x >= 2048 else 1

#	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_IGNORE, Vector2(), scale)

func _exit_tree() -> void:
	
	# Save the window position and size to remember it when restarting the application
	mt_globals.config.set_value("window", "screen", DisplayServer.window_get_current_screen())
	mt_globals.config.set_value("window", "maximized", DisplayServer.WINDOW_MODE_MAXIMIZED || DisplayServer.WINDOW_MODE_FULLSCREEN)
	mt_globals.config.set_value("window", "position", DisplayServer.window_get_position())
	mt_globals.config.set_value("window", "size", DisplayServer.window_get_size())
	layout.save_config()

func set_app_theme(theme_name : String) -> void:
	theme = load("res://theme/"+theme_name+".tres")

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




func create_menu_show_panels(menu : PopupMenu) -> void:
	menu.clear()
	var panels = layout.get_panel_list()
	for i in range(panels.size()):
		menu.add_check_item(panels[i], i)
		menu.set_item_checked(i, layout.is_panel_visible(panels[i]))
	if !menu.is_connected("id_pressed", _on_ShowPanels_id_pressed):
		menu.connect("id_pressed", _on_ShowPanels_id_pressed)

func _on_ShowPanels_id_pressed(id) -> void:
	var panel : String = layout.get_panel_list()[id]
	layout.set_panel_visible(panel, !layout.is_panel_visible(panel))

func get_panel(panel_name : String) -> Control:
	return layout.get_panel(panel_name)

func get_current_project() -> Control:
	return projects.get_current_tab_control()



# -----------------------------------------------------------------------
#                             Help menu
# -----------------------------------------------------------------------

func bug_report() -> void:
	OS.shell_open("https://github.com/ywmaa/Photo-Touch/issues")

func about() -> void:
	var about_box = preload("res://windows/about/about.tscn").instantiate()
	add_child(about_box)
	about_box.connect("popup_hide", about_box.queue_free)
	about_box.popup_centered()
func quit() -> void:
	if quitting:
		return
	quitting = true
	var dialog = preload("res://windows/accept_dialog/accept_dialog.tscn").instantiate()
	dialog.dialog_text = "Quit My Touch?"
	dialog.add_cancel_button("Cancel")
	add_child(dialog)
	if mt_globals.get_config("confirm_quit"):
		var result = await dialog.ask()
		if result == "cancel":
			quitting = false
			return
	if mt_globals.get_config("confirm_close_project"):
		var result = $VBoxContainer/Layout/SplitRight/ProjectsPanel/Projects.check_save_tabs()
		if !result:
			quitting = false
			return
	dim_window()
	get_tree().quit()
	quitting = false

func dim_window() -> void:
	# Darken the UI to denote that the application is currently exiting
	# (it won't respond to user input in this state).
	modulate = Color(0.5, 0.5, 0.5)


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
		DisplayServer.WINDOW_EVENT_CLOSE_REQUEST:
			await get_tree().idle_frame
			quit()
		



#
#
#
#
#
#enum tool_mode {none,move_image,rotate_image,scale_image,new}
#
#@onready var LayersList : ItemList = get_node("TabContainer/PhotoEditing/LayersList")
#@onready var ToolsList : ItemList = get_node("TabContainer/PhotoEditing/ToolsList")
#@onready var Canvas : Control = get_node("TabContainer/PhotoEditing/Canvas")
#
#var last_mode : tool_mode = tool_mode.none
#var current_mode : tool_mode = tool_mode.none:
#	get: return current_mode
#	set(new_mode):
#		last_mode = current_mode
#		current_mode = new_mode
#
#var selected_layer :
#	get: return selected_layer
#	set(layer):
#		selected_layer = layer
#		if selected_layer:
#			activate_layer_related_tools(true)
#		else:
#			activate_layer_related_tools(false)
#var layers := []
#
#
#
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#var previous_mouse_position : Vector2
#var mouse_position_delta : Vector2
#@export var smooth_mode : bool = false
#
#
#func _process(delta):
#	mouse_position_delta = get_global_mouse_position() - previous_mouse_position if smooth_mode == false else Input.get_last_mouse_velocity() * delta
#	match current_mode:
#		tool_mode.move_image:
#			if selected_layer:
#				selected_layer.position += mouse_position_delta
#		tool_mode.rotate_image:
#			if selected_layer:
#				selected_layer.rotation = selected_layer.global_position.angle_to_point(get_local_mouse_position())
#		tool_mode.scale_image:
#			if selected_layer:
#				selected_layer.scale += mouse_position_delta * delta
#		tool_mode.new:
#			add_new_image()
#
#	previous_mouse_position = get_global_mouse_position()
#
#
#
#
#
#
#
#
#
#
#func _input(event): #handle shortcuts
#	if event.is_action_pressed("toggle_fullscreen"):
#		OS.window_fullscreen = !OS.window_fullscreen
#	if Input.is_action_pressed("undo"):
#		undo()
#	if Input.is_action_just_pressed("move"):
#		select_tool_shortcuts(0)
#	if Input.is_action_just_pressed("rotate"):
#		select_tool_shortcuts(1)
#	if Input.is_action_just_pressed("scale"):
#		select_tool_shortcuts(2)
#	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
#		deselect_all_tools()
#
#
#func select_tool_shortcuts(index):
#	ToolsList.select(index)
#	_on_tools_list_item_selected(index)
#
#func _on_tools_list_item_selected(index): # handle tools list
#	match index:
#		0:
#			if selected_layer:
#				add_to_undo_history([selected_layer, "position", selected_layer.position])
#				current_mode = tool_mode.move_image
#		1:
#			if selected_layer:
#				add_to_undo_history([selected_layer, "rotation", selected_layer.rotation])
#				current_mode = tool_mode.rotate_image
#		2:
#			if selected_layer:
#				add_to_undo_history([selected_layer, "scale", selected_layer.scale])
#				current_mode = tool_mode.scale_image
#		3:
#			current_mode = tool_mode.new
#
#func deselect_all_tools():
#	ToolsList.deselect_all()
#	current_mode = tool_mode.none
#
#func activate_layer_related_tools(state:bool):
#	ToolsList.set_item_disabled(0,!state) 
#	ToolsList.set_item_disabled(1,!state) 
#	ToolsList.set_item_disabled(2,!state) 
#
#
#
#func add_new_image():
#	var new_layer : TextureRect = TextureRect.new()
#	new_layer.texture = load("res://icon.png")
#	Canvas.add_child(new_layer)
#	new_layer.position = get_global_mouse_position()
#	LayersList.add_item(str(new_layer.name))
#	layers.append(new_layer)
#	new_layer.connect("mouse_entered",func(): select_layer(layers.find(new_layer)))
#	deselect_all_tools()
#
#func select_layer(index):
#	LayersList.select(index)
#	_on_layers_list_multi_selected(index,true)
#
#func _on_layers_list_multi_selected(index, selected):
#	selected_layer = Canvas.get_node(str(LayersList.get_item_text(index)))
#
#
#
#
#
#
#
#var undo_history = []
#@export var undo_limit : int = 32
#var undo_saved_step : int = 0
#func add_to_undo_history(data:Array): # syntax : [object,str(property_name),value]
#	print("history added")
#	undo_history.append(data)
#	if undo_history.size() > undo_limit:
#		undo_history.pop_front()
#func undo():
#	if undo_history.size() <= 0:
#		print("nothing to undo")
#		return
#	var tween : Tween = get_tree().create_tween()
#	tween.tween_property(undo_history.back()[0],undo_history.back()[1],undo_history.back()[2],0.01)
#	undo_history.pop_back()
#func redo(): # todo
#	pass



