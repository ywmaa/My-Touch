extends Resource
class_name layers_manager

@export var layers : Array[base_layer]
var selected_layers : Array[base_layer] = []
var canvas: Node 

signal layers_changed
func add_layer(new_layer:base_layer, parent:base_layer=null):
	if parent:
		remove_layer(new_layer)
		parent.add_child(new_layer)
	else:
		if !layers.has(new_layer):
			layers.append(new_layer)
	_on_layers_changed()

func remove_layer(layer : base_layer) -> void:
	var layers_array = find_parent_array(layer)
	if layers_array:
		deselect_layer(layer)
		layers_array.erase(layer)
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
	#if layers.has(layer):
	if !selected_layers.has(layer):
		selected_layers.append(layer)
	_on_layers_changed()

func deselect_layer(layer : base_layer) -> void:
	if selected_layers.has(layer):
		selected_layers.erase(layer)
	_on_layers_changed()

func _on_layers_changed() -> void:
	emit_signal("layers_changed")
	ProjectsManager.refresh()
	

func duplicate_layer(source_layer, parent:base_layer=null) -> void:
	ProjectsManager.select_none()
	source_layer.parent = parent
	source_layer.parent_project = ToolsManager.current_project
	var layer = source_layer.get_copy(get_unused_layer_name())
	if source_layer == parent:
		layer.children.clear()
	var undo_redo : UndoRedo = ToolsManager.current_project.undo_redo
	undo_redo.create_action("Layer duplication/paste action")
	undo_redo.add_do_method(add_layer.bind(layer, parent))
	undo_redo.add_do_method(select_layer.bind(layer))
	#undo_redo.add_do_reference(layer)
	
	undo_redo.add_undo_method(remove_layer.bind(layer))
	undo_redo.commit_action(true)



## Moves [param layer] into [param target_parent] (null for the top level) before the layer
## currently at [param index] (-1 to add it last). Returns false if the move isn't possible,
## like moving a layer into itself or one of its children.
func move_layer_into(layer : base_layer, target_parent : base_layer, index : int = -1, with_undo : bool = true) -> bool:
	assert(layer != null)
	if target_parent == layer or is_ancestor_of(layer, target_parent):
		return false
	var from_array : Array = find_parent_array(layer)
	if from_array == null:
		return false
	var from_parent : base_layer = layer.parent
	var from_index : int = from_array.find(layer)
	var to_array : Array = target_parent.children if target_parent else layers
	if index < 0 or index > to_array.size():
		index = to_array.size()
	if to_array == from_array and index > from_index:
		index -= 1 # The layer itself is removed first
	if to_array == from_array and index == from_index:
		return false # Nothing changes
	if with_undo:
		var undo_redo : UndoRedo = ToolsManager.current_project.undo_redo
		undo_redo.create_action("Move Layer")
		undo_redo.add_do_method(_place_layer.bind(layer, target_parent, index))
		undo_redo.add_undo_method(_place_layer.bind(layer, from_parent, from_index))
		undo_redo.commit_action()
	else:
		_place_layer(layer, target_parent, index)
	return true

## Puts [param layer] at exactly [param index] of [param parent]'s children (or the top level).
func _place_layer(layer : base_layer, parent : base_layer, index : int) -> void:
	var from_array : Array = find_parent_array(layer)
	if from_array != null:
		from_array.erase(layer)
	var to_array : Array = parent.children if parent else layers
	to_array.insert(clampi(index, 0, to_array.size()), layer)
	layer.parent = parent
	if parent:
		layer.parent_project = parent.parent_project
	if ProjectsManager.current_project:
		ProjectsManager.current_project.need_save = true
	_on_layers_changed()

## True if [param layer] is [param other] or one of its parents.
func is_ancestor_of(layer : base_layer, other : base_layer) -> bool:
	while other != null:
		if other == layer:
			return true
		other = other.parent
	return false

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
	if layer.parent:
		return layer.parent.children
	if layer_array.has(layer):
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
