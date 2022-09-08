extends Resource
class_name layers_object

@export var layers = []
var selected_layers : Array[base_layer] = []
var canvas

func load_layers():
	for layer in layers:
		layer.image.z_index = layers.find(layer)
		canvas.add_child(layer.image)
		_on_layers_changed()
func add_layer(new_layer:base_layer):
	layers.append(new_layer)
	new_layer.image.z_index = layers.find(new_layer)
	canvas.add_child(new_layer.image)
	_on_layers_changed()

func select_layer_name(layer_name):
	for l in layers:
		if l.name == layer_name:
			if !selected_layers.has(l):
				selected_layers.append(l) 
	_on_layers_changed()


func select_layer(layer : base_layer) -> void:
	if layers.has(layer):
		if !selected_layers.has(layer):
			selected_layers.append(layer)

func deselect_layer(layer : base_layer) -> void:
	if layers.has(layer):
		selected_layers.erase(layer)
		

func _on_layers_changed() -> void:
	pass
	

func duplicate_layer(source_layer : base_layer) -> void:
	var layer = base_layer.new()#source_layer.duplicate()
	layer.name = get_unused_layer_name(layers)
	layer.image.texture = source_layer.image.texture
	layer.type = source_layer.type
	add_layer(layer)
	select_layer(layer)
	_on_layers_changed()

func remove_layer(layer : base_layer) -> void:
	var need_reselect : bool = (layer in selected_layers)
	var layers_array : Array = find_parent_array(layer)
	layer.clear_image()
	layers_array.erase(layer)
	if need_reselect:
		selected_layers = []
		if !layers.is_empty():
			select_layer(layers[0])
			_on_layers_changed()
			return
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
	layer.image.z_index = index
	_on_layers_changed()

func move_layer_up(layer : base_layer) -> void:
	var array : Array = find_parent_array(layer)
	var orig_index = array.find(layer)
	if orig_index > 0:
		array.erase(layer)
		array.insert(orig_index-1, layer)
		layer.image.z_index = orig_index-2
		array[orig_index].image.z_index = orig_index
		_on_layers_changed()

func move_layer_down(layer : base_layer) -> void:
	var array : Array = find_parent_array(layer)
	var orig_index = array.find(layer)
	if orig_index < array.size()-1:
		array.erase(layer)
		array.insert(orig_index+1, layer)
		layer.image.z_index = orig_index+1
		array[orig_index].image.z_index = orig_index
		_on_layers_changed()



func find_parent_array(layer : base_layer, layer_array : Array = layers):
	for l in layer_array:
		if l == layer:
			return layer_array
	return null


func get_unused_layer_name(layers_array : Array) -> String:
	return "New"
