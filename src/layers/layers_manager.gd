extends Resource
class_name layers_manager

@export var layers : Array[base_layer]
var selected_layers : Array[base_layer] = []
var canvas: Node 

signal layers_changed
func add_layer(new_layer:base_layer):
	layers.append(new_layer)
	_on_layers_changed()

func remove_layer(layer : base_layer) -> void:
	var layers_array = find_parent_array(layer)
	layers_array.erase(layer)
#	layer.clear_image()
	_on_layers_changed()

func select_layer_name(layer_name):
	if find_layer(layer_name) == null:
		return
	if !selected_layers.has(find_layer(layer_name)):
		selected_layers.append(find_layer(layer_name)) 
	_on_layers_changed()
func find_layer(name:String):
	for l in layers:
		if l.name == name:
			return l
	return null

func select_layer(layer : base_layer) -> void:
	if layers.has(layer):
		if !selected_layers.has(layer):
			selected_layers.append(layer)
	_on_layers_changed()

func deselect_layer(layer : base_layer) -> void:
	if layers.has(layer):
		selected_layers.erase(layer)
	_on_layers_changed()

func _on_layers_changed() -> void:
	emit_signal("layers_changed")
	ProjectsManager.refresh()
	

func duplicate_layer(source_layer) -> void:
	var layer = source_layer.get_copy(get_unused_layer_name())
	add_layer(layer)
	select_layer(layer)
	_on_layers_changed()



func move_layer_into(layer : base_layer, target_layer : base_layer, index : int = -1) -> void:
	assert(layer != null)
	var array : Array = find_parent_array(layer)
	var orig_index = array.find(layer)
	array.erase(layer)
	var target_array = target_layer.layers if target_layer != null else layers
	if index == -1:
		index = target_array.size()
	elif array == target_array and index > orig_index:
		index -= 1
	target_array.insert(index, layer)
	_on_layers_changed()

func move_layer_up(layer : base_layer) -> void:
	var array : Array = find_parent_array(layer)
	var orig_index = array.find(layer)
	if orig_index > 0:
		array.erase(layer)
		array.insert(orig_index-1, layer)
		_on_layers_changed()

func move_layer_down(layer : base_layer) -> void:
	var array : Array = find_parent_array(layer)
	var orig_index = array.find(layer)
	if orig_index < array.size()-1:
		array.erase(layer)
		array.insert(orig_index+1, layer)
		_on_layers_changed()



func find_parent_array(layer : base_layer, layer_array : Array = layers):
	for l in layer_array:
		if l == layer:
			return layer_array
	return null


func get_unused_layer_name() -> String:
	var naming = "new_layer"
	var return_name : String
	var count = 0
	return_name = naming
	for layer in layers:
		if layer.name == return_name:
			count += 1
		if count > 0:
			return_name = naming + " " + str(count)
	return return_name
