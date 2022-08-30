extends ScrollContainer
class_name MTGraph
enum tool_mode {none,move_image,rotate_image,scale_image}
enum coordinates {xy,x,y}


@onready var canvas : SubViewport = get_node("SubViewportContainer/Canvas")
var direction : coordinates = coordinates.xy
	
var last_mode : tool_mode = tool_mode.none
var current_mode : tool_mode = tool_mode.none:
	get: return current_mode
	set(new_mode):
		last_mode = current_mode
		current_mode = new_mode


var layers : layers_object = layers_object.new()
var default_icon = preload("res://icon.png")
var save_path = null : 
	set(path):
		if path != save_path:
			remove_crash_recovery_file()
			need_save_crash_recovery = false
			save_path = path
			update_tab_title()
			emit_signal("save_path_changed", self, path)
var need_save : bool = false
var need_save_crash_recovery : bool = false


signal save_path_changed
signal graph_changed

signal activate_layer_related_tools(state:bool)


func set_current():
	mt_globals.main_window.get_panel("Layers").set_layers(layers)
	# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	layers.canvas = canvas
	
	OS.low_processor_usage_mode = true
	
	#default layer
	var new_layer : base_layer = base_layer.new()
	new_layer.image.texture = default_icon
	new_layer.name = "new_layer"
	new_layer.type = base_layer.layer_type.image
	layers.add_layer(new_layer)
	center_view()


# Called every frame. 'delta' is the elapsed time since the previous frame.
var previous_mouse_position : Vector2
var mouse_position_delta : Vector2
@export var smooth_mode : bool = false


func _process(delta):

	if Input.is_action_pressed("ui_up"):
		canvas.get_camera_2d().position.y += -1.0
	if Input.is_action_pressed("ui_down"):
		canvas.get_camera_2d().position.y += 1.0
	if Input.is_action_pressed("ui_left"):
		canvas.get_camera_2d().position.x += -1.0
	if Input.is_action_pressed("ui_right"):
		canvas.get_camera_2d().position.x += 1.0
	#zoom
	if Input.is_action_pressed("ui_text_scroll_up"):
		canvas.get_camera_2d().zoom += Vector2(0.1,0.1)
	if Input.is_action_pressed("ui_text_scroll_down"):
		canvas.get_camera_2d().zoom -= Vector2(0.1,0.1)
	if Input.is_action_just_pressed("mouse_left"):
		for child in canvas.get_children():
			if child is Camera2D:
				continue
			if child.get_rect().has_point(canvas.get_mouse_position()):
#				print(child)
				layers.select_layer_name(child.name)
	#handle shortcuts
	if Input.is_action_just_pressed("move"):
		tool_shortcut(tool_mode.move_image)
	if Input.is_action_just_pressed("rotate"):
		tool_shortcut(tool_mode.rotate_image)
	if Input.is_action_just_pressed("scale"):
		tool_shortcut(tool_mode.scale_image)
	if Input.is_action_just_pressed("lock_x"):
		if direction == coordinates.x:
			direction = coordinates.xy
		else:
			direction = coordinates.x
	if Input.is_action_just_pressed("lock_y"):
		if direction == coordinates.y:
			direction = coordinates.xy
		else:
			direction = coordinates.y
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		current_mode = tool_mode.none
		direction = coordinates.xy
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if current_mode != tool_mode.none:
			current_mode = tool_mode.none
			direction = coordinates.xy
			undo()
	mouse_position_delta = get_global_mouse_position() - previous_mouse_position if smooth_mode == false else Input.get_last_mouse_velocity() * delta
	if current_mode == tool_mode.none:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	match current_mode:
		tool_mode.move_image:
			if layers.selected_layers:
				for selected in layers.selected_layers:
					match direction:
						coordinates.xy:
							selected.image.position += mouse_position_delta
						coordinates.x:
							selected.image.position.x += mouse_position_delta.x
						coordinates.y:
							selected.image.position.y += mouse_position_delta.y
		tool_mode.rotate_image:
			if layers.selected_layers:
				for selected in layers.selected_layers:
					selected.image.rotation = selected.image.global_position.angle_to_point(get_local_mouse_position())
		tool_mode.scale_image:
			if layers.selected_layers:
				for selected in layers.selected_layers:
					match direction:
						coordinates.xy:
							selected.image.scale += mouse_position_delta * delta
						coordinates.x:
							selected.image.scale.x += mouse_position_delta.x * delta
						coordinates.y:
							selected.image.scale.y += mouse_position_delta.y * delta

	previous_mouse_position = get_global_mouse_position()



func _input(event): 
	if event.is_action_pressed("toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen



func tool_shortcut(index): # handle tools list
	match index:
		tool_mode.move_image:
			if layers.selected_layers:
				for selected in layers.selected_layers:
					add_to_undo_history([selected.image, "position", selected.image.position])
				current_mode = tool_mode.move_image
		tool_mode.rotate_image:
			if layers.selected_layers:
				for selected in layers.selected_layers:
					add_to_undo_history([selected.image, "rotation", selected.image.rotation])
				current_mode = tool_mode.rotate_image
		tool_mode.scale_image:
			if layers.selected_layers:
				for selected in layers.selected_layers:
					add_to_undo_history([selected.image, "scale", selected.image.scale])
				current_mode = tool_mode.scale_image
func new_project() -> void:
	center_view()
	save_path = null
#	set_need_save(false)


#func deselect_all_tools():
#	ToolsList.deselect_all()
#	current_mode = tool_mode.none
#
#func activate_layer_related_tools(state:bool):
#	ToolsList.set_item_disabled(0,!state) 
#	ToolsList.set_item_disabled(1,!state) 
#	ToolsList.set_item_disabled(2,!state) 




	

var undo_history = []
var redo_history = []
@export var undo_limit : int = 32
var undo_saved_step : int = 0
func add_to_undo_history(data:Array): # syntax : [object,str(property_name),value]
	redo_history.clear()
	undo_history.append(data)
	if undo_history.size() > undo_limit:
		undo_history.pop_front()
	print("history added")
	get_node("/root/Editor/UndoRedoLabel").show_step(undo_history.size())
func undo():
	if !can_undo():
		print("nothing to undo")
		return
	var tween : Tween = get_tree().create_tween()
	var redo_data = [undo_history.back()[0],undo_history.back()[1],undo_history.back()[2]]
	redo_history.append(redo_data)
	tween.tween_property(undo_history.back()[0],undo_history.back()[1],undo_history.back()[2],0.01)
	undo_history.pop_back()
	print("undo")
	
func can_undo() -> bool:
	return !(undo_history.size() == 0)

func redo():
	if !can_redo():
		print("nothing to redo")
		return
	var tween : Tween = get_tree().create_tween()
	var undo_data = [redo_history.back()[0],redo_history.back()[1],redo_history.back()[2]]
	undo_history.append(undo_data)
	tween.tween_property(redo_history.back()[0],redo_history.back()[1],redo_history.back()[2],0.01)
	redo_history.pop_back()
	print("redo")

func can_redo() -> bool:
	return !(redo_history.size() == 0)

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
		title = save_path.right(save_path.rfind("/")+1)
	if need_save:
		title += " *"
	if get_parent().has_method("set_tab_title"):
		get_parent().set_tab_title(get_index(), title)

func load_file(filename) -> bool:
	var rescued = false
	var new_generator = null
	var file = File.new()
	if filename != null and file.file_exists(filename+".mmcr"):
		var dialog = preload("res://windows/accept_dialog/accept_dialog.tscn").instance()
		dialog.dialog_text = "Rescue file for "+filename.get_file()+" was found.\nLoad it?"
		dialog.get_ok().text = "Rescue"
		dialog.add_cancel("Load "+filename.get_file())
		add_child(dialog)
		var result = await dialog.ask()
		if result == "ok":
			pass
#			new_generator = mm_loader.load_gen(filename+".mtcr")
	if get_child_count() > 1:
		rescued = true
	else:
		pass
#		new_generator = mm_loader.load_gen(filename)
	if new_generator != null:
		save_path = filename
		if rescued:
			pass
#			set_need_save(true)
		return true
	else:
		var dialog : AcceptDialog = AcceptDialog.new()
		add_child(dialog)
		dialog.window_title = "Load failed!"
		dialog.dialog_text = "Failed to load "+filename
		dialog.connect("popup_hide", dialog.queue_free)
		dialog.popup_centered()
		return false

# Save

#func save() -> bool:
#	var status
#	if save_path != null:
#		status = await save_file(save_path)
#	else:
#		status = await save_as()
#	return status

#func save_as() -> bool:
#	var dialog = preload("res://windows/file_dialog/file_dialog.tscn").instantiate()
#	add_child(dialog)
#	dialog.rect_min_size = Vector2(500, 500)
#	dialog.access = FileDialog.ACCESS_FILESYSTEM
#	dialog.mode = FileDialog.MODE_SAVE_FILE
#	dialog.add_filter("*.mt;My Touch files")
#	var main_window = mt_globals.main_window
#	if mt_globals.config.has_section_key("path", "project"):
#		dialog.current_dir = mt_globals.config.get_value("path", "project")
#	var files = await dialog.select_files()
#	if files.size() == 1:
#		if save_file(files[0]):
#			main_window.add_recent(save_path)
#			mt_globals.config.set_value("path", "project", save_path.get_base_dir())
#			return true
#	return false
#
#func save_file(filename) -> bool:
#
#	var data = serialize_file()
#	var file = File.new()
#	if file.open(filename, File.WRITE) == OK:
#		file.store_string(JSON.print(data, "\t", true))
#		file.close()
#	else:
#		return false
#	save_path = filename
#	set_need_save(false)
#	remove_crash_recovery_file()
#	return true
#
#func set_need_save(ns = true) -> void:
#	if ns != need_save:
#		need_save = ns
#		update_tab_title()
#	if save_path != null:
#		if ns:
#			need_save_crash_recovery = true
#		else:
#			need_save_crash_recovery = false






# crash_recovery

#func crash_recovery_save() -> void:
#	if !need_save_crash_recovery:
#		return
#	var data = top_generator.serialize()
#	var file = File.new()
#	if file.open(save_path+".mtcr", File.WRITE) == OK:
#		file.store_string(JSON.print(data))
#		file.close()
#		need_save_crash_recovery = false

func remove_crash_recovery_file() -> void:
	if save_path != null:
		var dir = Directory.new()
		dir.remove(save_path+".mtcr")

# Center view

func center_view() -> void:
	var center = Vector2(0, 0)
	var layers_count = 0
	for c in canvas.get_children():
		if c is Camera2D:
			continue
		if c:
			center += c.position + 0.5*c.get_rect().size
			layers_count += 1
	if layers_count > 0:
		center /= layers_count
		scroll_horizontal = (center - 0.5*get_rect().size).x
		scroll_vertical = (center - 0.5*get_rect().size).y
