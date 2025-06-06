extends VBoxContainer

# The layer object
var layers : layers_manager
var has_focus
@onready var tree = $Tree
func _ready():
	tree.connect("selection_changed",_on_Tree_selection_changed)
	self.connect("mouse_entered",_on_mouse_entered)
	self.connect("mouse_exited",_on_mouse_exited)
func _process(_delta):
	if !ProjectsManager.current_project:
		visible = false
		return
	visible = true
	if ProjectsManager.current_project:
		set_layers(ProjectsManager.current_project.layers_container)
	else:
		set_layers([])
func set_layers(_layers) -> void:
	layers = _layers
	tree.layers = layers
	if layers:
#		layers.load_layers()
		tree.update_from_layers(layers.layers, layers.selected_layers)
	else:
		tree.update_from_layers([], [])

func _on_Tree_selection_changed(new_selected) -> void:
	var empty_layers_array : Array[base_layer] = []
	ProjectsManager.current_project.layers_container.selected_layers = empty_layers_array
	for item in new_selected:
		ProjectsManager.current_project.layers_container.select_layer(item.get_meta("layer"))

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
	ProjectsManager.remove_selection()


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
