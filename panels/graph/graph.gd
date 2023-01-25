extends SubViewportContainer
class_name MTGraph

var clipboard_file_path = "user://my_touch_clipboard.tres"
var undo_redo := UndoRedo.new()
var tiles: Tiles
var has_focus
var canvas_size : Vector2: 
	set(value):
		if !tiles:
			canvas_size = value
			return
		if canvas_size.x != 0:
			tiles.x_basis = (tiles.x_basis * value.x / canvas_size.x).round()
		else:
			tiles.x_basis = Vector2(value.x, 0)
		if canvas_size.y != 0:
			tiles.y_basis = (tiles.y_basis * value.y / canvas_size.y).round()
		else:
			tiles.y_basis = Vector2(0, value.y)
		tiles.tile_size = value
		tiles.reset_mask()
		canvas_size = value
		transparent_checker.update_rect()


@onready var viewport : SubViewport = $Viewport/TransparentChecker/SubViewport
@onready var canvas : Node2D = $Viewport/TransparentChecker/SubViewport/Canvas
@onready var transparent_checker = $Viewport/TransparentChecker
@onready var camera: Camera2D = get_node("Viewport/Camera2D")

var layers : layers_object = layers_object.new()
var default_icon = "res://icon.png"
var name_used : bool = false
var save_path = null : 
	set(path):
		if path != save_path:
			save_path = path
			update_tab_title()
			emit_signal("save_path_changed", self, path)
var need_save : bool = false


signal save_path_changed
signal graph_changed

signal activate_layer_related_tools(state:bool)

func _init():
	canvas_size = Vector2(mt_globals.default_width,mt_globals.default_height)
	tiles = Tiles.new(canvas_size)
	
func set_current():
	emit_signal("graph_changed")
	# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.connect("mouse_entered",_on_mouse_entered)
	self.connect("mouse_exited",_on_mouse_exited)
	layers.canvas = canvas
	
	layers.connect("layers_changed",func(): emit_signal("graph_changed"))
	OS.low_processor_usage_mode = true
	
	#default layer
	var new_layer : base_layer = base_layer.new()
	new_layer.init(layers.get_unused_layer_name(),default_icon,base_layer.layer_type.image,canvas)
	layers.add_layer(new_layer)
	
	center_view()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
var previous_mouse_position : Vector2
var mouse_position_delta : Vector2
var dragging : bool = false
var drag_start : Vector2 = Vector2.ZERO
var select_rect = RectangleShape2D.new()
var select_draw_rectangle : bool = false
var select_draw_circle : bool = false
@export var smooth_mode : bool = false


func _draw():
	if select_draw_circle:
		draw_circle(drag_start,(get_local_mouse_position()-drag_start).length(),Color(0.5,0.5,0.5))
	if select_draw_rectangle:
		draw_rect(Rect2(drag_start,get_local_mouse_position()-drag_start),Color(0.5,0.5,0.5),false)

	if dragging:
#		draw_polyline() # free select
		draw_rect(Rect2(drag_start,get_local_mouse_position()-drag_start),Color(0.5,0.5,0.5),false)

func _input(event):
	if !visible or has_focus == false:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			if ToolManager.current_mode != ToolManager.tool_mode.none:
				ToolManager.current_mode = ToolManager.tool_mode.none
				ToolManager.direction = ToolManager.coordinates.xy
				undo()
	
	if event is InputEventMouseMotion and dragging:
		queue_redraw()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if ToolManager.current_tool == ToolManager.tool_mode.move_image:
				if ToolManager.current_mode == ToolManager.tool_mode.move_image:
					ToolManager.current_mode = ToolManager.tool_mode.none
					ToolManager.direction = ToolManager.coordinates.xy
				else:
					tool_shortcut(ToolManager.tool_mode.move_image)
			if ToolManager.current_tool == ToolManager.tool_mode.rotate_image:
				if ToolManager.current_mode == ToolManager.tool_mode.rotate_image:
					ToolManager.current_mode = ToolManager.tool_mode.none
					ToolManager.direction = ToolManager.coordinates.xy
				else:
					tool_shortcut(ToolManager.tool_mode.rotate_image)
			if ToolManager.current_tool == ToolManager.tool_mode.scale_image:
				if ToolManager.current_mode == ToolManager.tool_mode.scale_image:
					ToolManager.current_mode = ToolManager.tool_mode.none
					ToolManager.direction = ToolManager.coordinates.xy
				else:
					tool_shortcut(ToolManager.tool_mode.scale_image)
			if ToolManager.current_tool == ToolManager.tool_mode.none:
				ToolManager.current_mode = ToolManager.tool_mode.none
				ToolManager.direction = ToolManager.coordinates.xy
				dragging = true
				drag_start = get_local_mouse_position()
				layers.selected_layers = []
				for layer in layers.layers:
					print(transparent_checker.global_position)
					if Rect2(drag_start,get_local_mouse_position()-drag_start).intersects(Rect2(position+layer.image.position,layer.image.get_rect().size*layer.image.scale),true):
						layers.select_layer(layer)

		elif dragging:
			dragging = false
			queue_redraw()
			var drag_end = get_local_mouse_position()
		

func _unhandled_input(event):

	#handle shortcuts
	if event.is_action_pressed("move"):
		tool_shortcut(ToolManager.tool_mode.move_image)
	if event.is_action_pressed("rotate"):
		tool_shortcut(ToolManager.tool_mode.rotate_image)
	if event.is_action_pressed("scale"):
		tool_shortcut(ToolManager.tool_mode.scale_image)
	if event.is_action_pressed("lock_x"):
		ToolManager.lock_x()
	if event.is_action_pressed("lock_y"):
		ToolManager.lock_y()


func on_drop_image_file(path):
	var new_layer : base_layer = base_layer.new()
	new_layer.init(layers.get_unused_layer_name(),path,base_layer.layer_type.image,canvas)
	layers.add_layer(new_layer)
	
func _process(delta):
	mouse_position_delta = get_global_mouse_position() - previous_mouse_position if smooth_mode == false else Input.get_last_mouse_velocity() * delta
	if ToolManager.current_mode == ToolManager.tool_mode.none:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	if ToolManager.current_mode == ToolManager.tool_mode.move_image:
		if layers.selected_layers:
			for selected in layers.selected_layers:
				ToolManager.move(selected.image,mouse_position_delta)
	if ToolManager.current_mode == ToolManager.tool_mode.rotate_image:
		if layers.selected_layers:
			for selected in layers.selected_layers:
				ToolManager.rotate(selected.image,get_global_mouse_position()-canvas_size/2.0)
	if ToolManager.current_mode == ToolManager.tool_mode.scale_image:
		if layers.selected_layers:
			for selected in layers.selected_layers:
				ToolManager.scale(selected.image,mouse_position_delta * delta) 

	previous_mouse_position = get_global_mouse_position()

# Cut / copy / paste / duplicate

func remove_selection() -> void:
	for selection in layers.selected_layers:
		layers.remove_layer(selection)
		
func cut() -> void:
	copy()
	remove_selection()

func copy() -> void:
	var data : mt_clipboard = mt_clipboard.new()
	data.layers = layers.selected_layers
	ResourceSaver.save(data,clipboard_file_path)

func paste() -> void:
	var data = ResourceLoader.load(clipboard_file_path) as mt_clipboard
	select_none()
	for layer in data.layers:
		layers.duplicate_layer(layer)

func duplicate_selected() -> void:
	copy()
	paste()

func select_all():
	layers.selected_layers = layers.layers
func select_none():
	layers.selected_layers = []
func select_invert():
	var inverted_selections : Array = []
	for layer in layers.layers:
		if layer in layers.selected_layers:
			continue
		inverted_selections.append(layer)
	layers.selected_layers = inverted_selections
func load_selection(filenames) -> void:
	var file_name : String = ""
	for f in filenames:
		var file = FileAccess.open(f, FileAccess.READ)
		if file == null:
			continue
		file_name = file.get_path_absolute()
		file.close()
		var data = ResourceLoader.load(file_name) as SaveProject
		if data != null:
			layers.layers.append_array(data.layers.layers)
			layers.canvas = canvas
			layers.load_layers()
		else:
			var dialog : AcceptDialog = AcceptDialog.new()
			add_child(dialog)
			dialog.title = "Load failed!"
			dialog.dialog_text = "Failed to load "+file_name
			dialog.connect("popup_hide", dialog.queue_free)
			dialog.popup_centered()

func save_selection() -> void:
	var dialog = preload("res://windows/file_dialog/file_dialog.tscn").instantiate()
	add_child(dialog)
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.mt.tres;My Touch files")
	var main_window = mt_globals.main_window
	if mt_globals.config.has_section_key("path", "project"):
		dialog.current_dir = mt_globals.config.get_value("path", "project")
	var files = await dialog.select_files()
	if files.size() == 1:
		if do_save_selection(files[0]):
			pass
#			main_window.add_recent(save_path)

func do_save_selection(filename) -> bool:
	var data : SaveProject = SaveProject.new()
	data.layers = layers_object.new()
	data.layers.layers = layers.selected_layers
	ResourceSaver.save(data,filename)
	return true

func load_project_layer(filenames) -> void:
	var file_name : String = ""
	for f in filenames:
		var file = FileAccess.open(f, FileAccess.READ)
		if file == null:
			continue
		file_name = file.get_path_absolute()
		file.close()
		var data = ResourceLoader.load(file_name) as SaveProject
		if data != null:
			var new_project_layer = project_layer.new()
			new_project_layer.project_layers = layers_object.new()
			new_project_layer.init(file_name,default_icon,base_layer.layer_type.project,canvas)
			layers.add_layer(new_project_layer)
		else:
			var dialog : AcceptDialog = AcceptDialog.new()
			add_child(dialog)
			dialog.title = "Load failed!"
			dialog.dialog_text = "Failed to load "+file_name
			dialog.connect("popup_hide", dialog.queue_free)
			dialog.popup_centered()
func refresh():
	for layer in layers.layers:
		layer.refresh()
	

func tool_shortcut(index): # handle tools list
	if index == ToolManager.tool_mode.move_image:
		if layers.selected_layers:
			for selected in layers.selected_layers:
				add_to_undo_history([selected.image, "position", selected.image.position])
			send_changed_signal()
			ToolManager.current_mode = ToolManager.tool_mode.move_image
	if index == ToolManager.tool_mode.rotate_image:
		if layers.selected_layers:
			for selected in layers.selected_layers:
				add_to_undo_history([selected.image, "rotation", selected.image.rotation])
			send_changed_signal()
			ToolManager.current_mode = ToolManager.tool_mode.rotate_image
	if index == ToolManager.tool_mode.scale_image:
		if layers.selected_layers:
			for selected in layers.selected_layers:
				add_to_undo_history([selected.image, "scale", selected.image.scale])
			send_changed_signal()
			ToolManager.current_mode = ToolManager.tool_mode.scale_image
func new_project() -> void:
	center_view()
	save_path = null
	set_need_save(false)


#func deselect_all_tools():
#	ToolsList.deselect_all()
#	current_mode = tool_mode.none
#
#func activate_layer_related_tools(state:bool):
#	ToolsList.set_item_disabled(0,!state) 
#	ToolsList.set_item_disabled(1,!state) 
#	ToolsList.set_item_disabled(2,!state) 


func send_changed_signal() -> void:
	set_need_save(true)


@export var undo_limit : int = 32
func add_to_undo_history(data:Array): # syntax : [object,str(property_name),value]
	undo_redo.create_action(data[1],0)
	undo_redo.add_undo_property(data[0],data[1],data[2])
#	undo_redo.add_do_property(data[0],data[1],data[2])
	undo_redo.commit_action()
	get_node("/root/Editor/MessageLabel").show_step(undo_redo.get_history_count())
func undo():
	undo_redo.undo()
	

func redo():
	undo_redo.redo()

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
	if save_path != null:
		if name_used == true:
			title = save_path
		else:
			title = save_path.substr(save_path.rfind("/")+1)
		
	if need_save:
		title += " *"
	if get_parent().has_method("set_tab_title"):
		get_parent().set_tab_title(get_index(), title)

func load_file(filename) -> bool:
	var data = ResourceLoader.load(filename,"") as SaveProject
	if data != null:
		save_path = filename
		for child in canvas.get_children():
			if child is Camera2D:
				continue
			remove_child(child)
			
		layers = data.layers
		layers.canvas = canvas
		canvas_size = data.canvas_size
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
	if save_path != null:
		status = await save_file(save_path)
	else:
		status = await save_as()
	return status

func save_as() -> bool:
	#replace with preload
	var dialog = preload("res://windows/file_dialog/file_dialog.tscn").instantiate()
	add_child(dialog)
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.mt.tres;My Touch files")
	var main_window = mt_globals.main_window
	if mt_globals.config.has_section_key("path", "project"):
		dialog.current_dir = mt_globals.config.get_value("path", "project")
	var files = await dialog.select_files()
	if files.size() == 1:
		if save_file(files[0]):
#			main_window.add_recent(save_path)
			mt_globals.config.set_value("path", "project", save_path.get_base_dir())
			return true
	return false
#
func save_file(filename) -> bool:
	var data : SaveProject = SaveProject.new()
	data.layers = layers 
	data.canvas_size = canvas.size 
	ResourceSaver.save(data,filename)
	save_path = filename
	set_need_save(false)
	return true

func set_need_save(ns = true) -> void:
	if ns != need_save:
		need_save = ns
		update_tab_title()

func auto_save():
	if save_path != null and need_save:
		await save_file(save_path)
		get_node("/root/Editor/MessageLabel").show_message("auto saved")
		



# Center view

func center_view() -> void:
	camera.fit_to_frame(canvas_size)




func _on_mouse_entered():
	has_focus = true
	mt_globals.main_window.left_cursor.visible = mt_globals.show_left_tool_icon


func _on_mouse_exited():
	has_focus = false
	mt_globals.main_window.left_cursor.visible = false
