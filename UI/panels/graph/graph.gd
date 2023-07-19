extends SubViewportContainer
class_name MTGraph

var project : Project:
	set(new_project):
		
		#Disconnect Signals
		if project:
			project.disconnect("save_path_changed", func(): emit_signal("graph_changed"))
			project.disconnect("project_saved", func(): emit_signal("graph_changed"))
			project.disconnect("need_save_changed", func(): emit_signal("graph_changed"))
			project.disconnect("canvas_size_changed", func(prev, new): on_canvas_size_changed(prev);emit_signal("graph_changed"))
			if project.layers:
				project.layers.disconnect("layers_changed",func(): emit_signal("graph_changed"))
		
		var update_data : bool = (project and new_project != project)
		project = new_project
		#sync values
		if update_data:
			if tiles:
				tiles = Tiles.new(project.canvas_size)
			update_tab_title()
		
		#Connect Signals
		project.connect("save_path_changed", func(): emit_signal("graph_changed"))
		project.connect("project_saved", func(): emit_signal("graph_changed"))
		project.connect("need_save_changed", func(): emit_signal("graph_changed"))
		project.connect("canvas_size_changed", func(prev, new): on_canvas_size_changed(prev);emit_signal("graph_changed"))
		if project.layers:
			project.layers.connect("layers_changed",func(): emit_signal("graph_changed"))
		
		if !project.undo_redo:
			project.undo_redo = UndoRedo.new()
		print("project changed",project)
var clipboard_file_path = "user://my_touch_clipboard.res"
var tiles: Tiles
var has_focus

func on_canvas_size_changed(value):
	if !tiles:
		return
	if project.canvas_size.x != 0:
		tiles.x_basis = (tiles.x_basis * value.x / project.canvas_size.x).round()
	else:
		tiles.x_basis = Vector2(value.x, 0)
	if project.canvas_size.y != 0:
		tiles.y_basis = (tiles.y_basis * value.y / project.canvas_size.y).round()
	else:
		tiles.y_basis = Vector2(0, value.y)
	tiles.tile_size = value
	tiles.reset_mask()
	transparent_checker.update_rect()



@onready var viewport : SubViewport = $Viewport/TransparentChecker/SubViewport
@onready var canvas : Node2D = $Viewport/TransparentChecker/SubViewport/Canvas
@onready var transparent_checker = $Viewport/TransparentChecker
@onready var camera: Camera2D = get_node("Viewport/Camera2D")

var default_icon = "res://icon.png"
var name_used : bool = false

signal graph_changed

func set_current():
	emit_signal("graph_changed")
	# Called when the node enters the scene tree for the first time.
func _init():
	project = Project.new()
	project.canvas_size = Vector2(mt_globals.default_width,mt_globals.default_height)
	tiles = Tiles.new(project.canvas_size)
	project.layers = layers_manager.new()
	project.layers.connect("layers_changed",func(): emit_signal("graph_changed"))
	


func _ready() -> void:
	add_child(context_menu)
	self.connect("mouse_entered",_on_mouse_entered)
	self.connect("mouse_exited",_on_mouse_exited)
	self.connect("graph_changed", update_tab_title)
	OS.low_processor_usage_mode = true
	
	center_view()
	
	#default layer
	var new_layer : base_layer = base_layer.new()
	new_layer.init(project.layers.get_unused_layer_name(),default_icon,base_layer.layer_type.image,canvas)
	project.layers.add_layer(new_layer)
	
	project.layers.canvas = canvas



var dragging : bool = false
var drag_start : Vector2 = Vector2.ZERO



func _draw():
	if dragging:
		draw_rect(Rect2(drag_start,get_local_mouse_position()-drag_start),Color(0.75,0.75,0.75),false)

var context_menu : PopupMenu = PopupMenu.new()

func create_add_context_menu(pos: Vector2 = get_global_mouse_position()):
	context_menu.clear()
	context_menu.add_item("Import Image")
	context_menu.add_item("Load Project As Image")
	context_menu.add_separator()
	context_menu.add_item("Text Layer")
	context_menu.add_item("Selection Layer")
	
	
	context_menu.connect("id_pressed",add_context_menu_item_pressed)
	context_menu.position = pos
	context_menu.visible = true

func add_context_menu_item_pressed(id: int):
	match id:
		0: #import image
			mt_globals.main_window.import_image()
		1: #project layer
			mt_globals.main_window.edit_load_project_as_image()
		3: #text layer
			var new_text_layer = text_layer.new()
			new_text_layer.init(project.layers.get_unused_layer_name(),default_icon,base_layer.layer_type.text,canvas)
			project.layers.add_layer(new_text_layer)
		4: #selection layer
			var new_selection_layer = selection_layer.new()
			new_selection_layer.init(project.layers.get_unused_layer_name(),default_icon,base_layer.layer_type.mask,canvas)
			project.layers.add_layer(new_selection_layer)
		
var mouse_rect : Rect2

func pass_event_to_tool(event) -> bool:
	return ToolsManager.handle_image_input(event)
func _input(event):
	pass_event_to_tool(event)
	if !visible or has_focus == false:
		return
	#handle shortcuts
	if event.is_action_pressed("add_context_menu"):
		create_add_context_menu()
	if event is InputEventMouseMotion and dragging:
		queue_redraw()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pass
#					layers.selected_layers = []
			dragging = true
			drag_start = get_local_mouse_position()
				
				
		elif dragging:
			dragging = false
			queue_redraw()
			var drag_end = get_local_mouse_position()
			
			for layer in project.layers.layers:
				
				if drag_end.y - drag_start.y < 0.0:
					mouse_rect = Rect2(drag_end,abs(drag_end-drag_start))
				else:
					mouse_rect = Rect2(drag_start,abs(drag_end-drag_start))
				mouse_rect.position.x = drag_start.x if drag_start.x < drag_end.x else drag_end.x
				
				if mouse_rect.intersects(layer.get_rect(),true):
					project.layers.select_layer(layer)
		

func on_import_image_file(path):
	var new_layer : base_layer = base_layer.new()
	new_layer.init(project.layers.get_unused_layer_name(),path,base_layer.layer_type.image,canvas)
	project.layers.add_layer(new_layer)
	
func _process(delta):
	ToolsManager.current_mouse_position = get_local_mouse_position()
	ToolsManager.mouse_position_delta = ToolsManager.current_mouse_position - ToolsManager.previous_mouse_position if ToolsManager.smooth_mode == false else Input.get_last_mouse_velocity() * delta
	ToolsManager.previous_mouse_position = get_local_mouse_position()


# Cut / copy / paste / duplicate

func remove_selection() -> void:
	graph_changed.emit()
	for selection in project.layers.selected_layers:
		project.layers.remove_layer(selection)
		
func cut() -> void:
	copy()
	remove_selection()

func copy() -> void:
	graph_changed.emit()
	var data : mt_clipboard = mt_clipboard.new()
	data.layers = project.layers.selected_layers
	ResourceSaver.save(data,clipboard_file_path)

func paste() -> void:
	graph_changed.emit()
	var data = ResourceLoader.load(clipboard_file_path) as mt_clipboard
	select_none()
	for layer in data.layers:
		project.layers.duplicate_layer(layer)

func duplicate_selected() -> void:
	copy()
	paste()

func select_all():
	project.layers.selected_layers = project.layers.layers
func select_none():
	project.layers.selected_layers = []
func select_invert():
	var inverted_selections : Array[base_layer] = []
	for layer in project.layers.layers:
		if layer in project.layers.selected_layers:
			continue
		inverted_selections.append(layer)
	project.layers.selected_layers = inverted_selections
func load_selection(filenames) -> void:
	var file_name : String = ""
	for f in filenames:
		var file = FileAccess.open(f, FileAccess.READ)
		if file == null:
			continue
		file_name = file.get_path_absolute()
		var data = ResourceLoader.load(file_name) as Project
		if data != null:
			project.layers.layers.append_array(data.layers.layers)
			project.layers.canvas = canvas
			project.layers.load_layers()
			graph_changed.emit()
		else:
			var dialog : AcceptDialog = AcceptDialog.new()
			add_child(dialog)
			dialog.title = "Load failed!"
			dialog.dialog_text = "Failed to load "+file_name
			dialog.connect("popup_hide", dialog.queue_free)
			dialog.popup_centered()

func save_selection() -> void:
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
	var file_name : String = ""
	for f in filenames:
		var file = FileAccess.open(f, FileAccess.READ)
		if file == null:
			continue
		file_name = file.get_path_absolute()
		var data = ResourceLoader.load(file_name,"",ResourceLoader.CACHE_MODE_IGNORE) as Project
		if data != null:
			var new_project_layer = project_layer.new()
			new_project_layer.init(file_name,default_icon,base_layer.layer_type.project,canvas)
			project.layers.add_layer(new_project_layer)
		else:
			var dialog : AcceptDialog = AcceptDialog.new()
			add_child(dialog)
			dialog.title = "Load failed!"
			dialog.dialog_text = "Failed to load "+file_name
			dialog.connect("popup_hide", dialog.queue_free)
			dialog.popup_centered()
func refresh():
	for layer in project.layers.layers:
		layer.refresh()
	

func tool_shortcut(index): # handle tools list
	if index == ToolsManager.tool_mode.rotate_image:
		if project.layers.selected_layers:
			project.undo_redo.create_action("Rotate Layers")
			for selected in project.layers.selected_layers:
				project.undo_redo.add_undo_property(selected,"rotation",selected.rotation)
			send_changed_signal()
			ToolsManager.current_mode = ToolsManager.tool_mode.rotate_image
	if index == ToolsManager.tool_mode.scale_image:
		if project.layers.selected_layers:
			project.undo_redo.create_action("Scale Layers")
			for selected in project.layers.selected_layers:
				project.undo_redo.add_undo_property(selected,"scale",selected.scale)
			send_changed_signal()
			ToolsManager.current_mode = ToolsManager.tool_mode.scale_image
func new_project() -> void:
	center_view()
	project.save_path = ""
	project.need_save = false


#func deselect_all_tools():
#	ToolsList.deselect_all()
#	current_mode = tool_mode.none



func send_changed_signal() -> void:
	graph_changed.emit()
	project.need_save = true



func undo():
	project.undo_redo.undo()
	get_node("/root/Editor/MessageLabel").show_message("Current Step : " + str(project.undo_redo.get_current_action() + 1))

func redo():
	project.undo_redo.redo()
	get_node("/root/Editor/MessageLabel").show_message("Current Step : " + str(project.undo_redo.get_current_action() + 1))

func _exit_tree():
	save_config()

func load_config():
	pass

func save_config():
	pass

func get_project_type() -> String:
	return "photo_editing"

func get_graph_edit():
	return self


func update_tab_title() -> void:
	if !get_parent().has_method("set_tab_title"):
		#print("no set_tab_title method")
		return
	var title = "[unnamed]"
	if project.save_path != "":
		if name_used == true:
			title = project.save_path
		else:
			title = project.save_path.substr(project.save_path.rfind("/")+1)
		
	if project.need_save:
		title += " *"
	if get_parent().has_method("set_tab_title"):
		get_parent().set_tab_title(get_index(), title)

func load_file(filename) -> bool:
	
	var data : Project = Project.load_project(filename)
	if data != null:
		project = data
		project.layers.canvas = canvas
		project.layers.load_layers()
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
	var status
	if project.save_path != "":
		status = project.save_project()
	else:
		status = await save_as()
	return status

func save_as() -> bool:
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
	if project.save_path != "" and project.need_save:
		project.save_project()
		get_node("/root/Editor/MessageLabel").show_message("auto saved")
		



# Center view

func center_view() -> void:
	camera.fit_to_frame(project.canvas_size)


func close():
	project.layers.unload_layers()
	

func _on_mouse_entered():
	has_focus = true
	mt_globals.main_window.left_cursor.visible = mt_globals.show_left_tool_icon


func _on_mouse_exited():
	has_focus = false
	mt_globals.main_window.left_cursor.visible = false
