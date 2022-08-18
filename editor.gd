extends Control
enum tool_mode {none,move_image,rotate_image,scale_image,new}

@onready var LayersList : ItemList = get_node("TabContainer/PhotoEditing/LayersList")
@onready var ToolsList : ItemList = get_node("TabContainer/PhotoEditing/ToolsList")
@onready var Canvas : Control = get_node("TabContainer/PhotoEditing/Canvas")

var last_mode : tool_mode = tool_mode.none
var current_mode : tool_mode = tool_mode.none:
	get: return current_mode
	set(new_mode):
		last_mode = current_mode
		current_mode = new_mode

var selected_layer :
	get: return selected_layer
	set(layer):
		selected_layer = layer
		if selected_layer:
			activate_layer_related_tools(true)
		else:
			activate_layer_related_tools(false)
var layers := []





# Called every frame. 'delta' is the elapsed time since the previous frame.
var previous_mouse_position : Vector2
var mouse_position_delta : Vector2
@export var smooth_mode : bool = false


func _process(delta):
	mouse_position_delta = get_global_mouse_position() - previous_mouse_position if smooth_mode == false else Input.get_last_mouse_velocity() * delta
	match current_mode:
		tool_mode.move_image:
			if selected_layer:
				selected_layer.position += mouse_position_delta
		tool_mode.rotate_image:
			if selected_layer:
				selected_layer.rotation = selected_layer.global_position.angle_to_point(get_local_mouse_position())
		tool_mode.scale_image:
			if selected_layer:
				selected_layer.scale += mouse_position_delta * delta
		tool_mode.new:
			add_new_image()
	
	previous_mouse_position = get_global_mouse_position()










func _input(event): #handle shortcuts
	if Input.is_action_pressed("undo"):
		undo()
	if Input.is_action_just_pressed("move"):
		select_tool_shortcuts(0)
	if Input.is_action_just_pressed("rotate"):
		select_tool_shortcuts(1)
	if Input.is_action_just_pressed("scale"):
		select_tool_shortcuts(2)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		deselect_all_tools()
	

func select_tool_shortcuts(index):
	ToolsList.select(index)
	_on_tools_list_item_selected(index)

func _on_tools_list_item_selected(index): # handle tools list
	match index:
		0:
			if selected_layer:
				add_to_undo_history([selected_layer, "position", selected_layer.position])
				current_mode = tool_mode.move_image
		1:
			if selected_layer:
				add_to_undo_history([selected_layer, "rotation", selected_layer.rotation])
				current_mode = tool_mode.rotate_image
		2:
			if selected_layer:
				add_to_undo_history([selected_layer, "scale", selected_layer.scale])
				current_mode = tool_mode.scale_image
		3:
			current_mode = tool_mode.new

func deselect_all_tools():
	ToolsList.deselect_all()
	current_mode = tool_mode.none
	
func activate_layer_related_tools(state:bool):
	ToolsList.set_item_disabled(0,!state) 
	ToolsList.set_item_disabled(1,!state) 
	ToolsList.set_item_disabled(2,!state) 



func add_new_image():
	var new_layer : TextureRect = TextureRect.new()
	new_layer.texture = load("res://icon.png")
	Canvas.add_child(new_layer)
	new_layer.position = get_global_mouse_position()
	LayersList.add_item(str(new_layer.name))
	layers.append(new_layer)
	new_layer.connect("mouse_entered",func(): select_layer(layers.find(new_layer)))
	deselect_all_tools()

func select_layer(index):
	LayersList.select(index)
	_on_layers_list_multi_selected(index,true)

func _on_layers_list_multi_selected(index, selected):
	selected_layer = Canvas.get_node(str(LayersList.get_item_text(index)))







var undo_history = []
@export var undo_limit : int = 32
var undo_saved_step : int = 0
func add_to_undo_history(data:Array): # syntax : [object,str(property_name),value]
	print("history added")
	undo_history.append(data)
	if undo_history.size() > undo_limit:
		undo_history.pop_front()
func undo():
	if undo_history.size() <= 0:
		print("nothing to undo")
		return
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(undo_history.back()[0],undo_history.back()[1],undo_history.back()[2],0.01)
	undo_history.pop_back()
#func redo(): # todo
#	pass



