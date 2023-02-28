extends VBoxContainer

# The layer object
var layers : layers_object
var has_focus
@onready var tree = $Tree
func _ready():
	tree.connect("selection_changed",_on_Tree_selection_changed)
	self.connect("mouse_entered",_on_mouse_entered)
	self.connect("mouse_exited",_on_mouse_exited)
func _process(_delta):
	if !mt_globals.main_window.get_current_graph_edit():
		visible = false
		return
	visible = true
	if mt_globals.main_window.get_current_graph_edit():
		set_layers(mt_globals.main_window.get_current_graph_edit().layers)
	else:
		set_layers([])
func set_layers(_layers) -> void:
	layers = _layers
	tree.layers = layers
	if layers:
		layers.load_layers()
		tree.update_from_layers(layers.layers, layers.selected_layers)
	else:
		tree.update_from_layers([], [])

func _on_Tree_selection_changed(new_selected) -> void:
	var empty_layers_array : Array[base_layer] = []
	mt_globals.main_window.get_current_graph_edit().layers.selected_layers = empty_layers_array
	for item in new_selected:
		mt_globals.main_window.get_current_graph_edit().layers.select_layer(item.get_meta("layer"))

func _on_Add_pressed():
	pass

func _on_add_layer_menu(id):
	layers.add_layer(id)
	layers.get_parent().initialize_layers_history()

func _on_Duplicate_pressed():
	var current = tree.get_selected()
	if current != null:
		layers.duplicate_layer(current.get_meta("layer"))

func _on_Remove_pressed():
	for layer in layers.selected_layers:
		layers.remove_layer(layers.find_layer(layer.name))


func _on_Up_pressed():
	var current = tree.get_selected()
	if current != null:
		layers.move_layer_up(current.get_meta("layer"))

func _on_Down_pressed():
	var current = tree.get_selected()
	if current != null:
		layers.move_layer_down(current.get_meta("layer"))

func _on_Config_pressed():
	pass

func _input(_event):
	if Input.is_action_just_pressed("delete"):
		_on_Remove_pressed()

func _on_mouse_entered():
	has_focus = true


func _on_mouse_exited():
	has_focus = false
