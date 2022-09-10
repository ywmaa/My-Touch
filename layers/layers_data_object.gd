extends Resource
class_name layers_object

@export var layers = []
var selected_layers : Array = []
var canvas

signal layers_changed
func unload_layers():
	for layer in layers:
		if layer:
			layer.clear_image()
#		if canvas:
#			if layer.image.get_parent() == canvas:
#				canvas.add_child(layer.image)
func load_layers():
	for layer in layers:
		if layer:
			layer.refresh()
			layer.image.z_index = layers.find(layer)
		if canvas:
			if layer.image.get_parent() == null:
				canvas.add_child(layer.image)
func add_layer(new_layer:base_layer):
	layers.append(new_layer)
	if new_layer.image.get_parent() == null:
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
	_on_layers_changed()

func deselect_layer(layer : base_layer) -> void:
	if layers.has(layer):
		selected_layers.erase(layer)
	_on_layers_changed()

func _on_layers_changed() -> void:
	emit_signal("layers_changed")
	

func duplicate_layer(source_layer) -> void:
	if source_layer is project_layer:
		var layer = project_layer.new()
		layer.project_layers = layers_object.new()
		layer.name = source_layer.name
		add_layer(layer)
		select_layer(layer)
		_on_layers_changed()
		return
	if source_layer is base_layer:
		var layer = base_layer.new()
		layer.name = get_unused_layer_name()
		layer.image.texture = source_layer.image.texture
		layer.type = source_layer.type
		add_layer(layer)
		select_layer(layer)
		_on_layers_changed()
		return

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
