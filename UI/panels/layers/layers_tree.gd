extends Tree
class_name LayersTree
var layers = null
var selected_items : Array[TreeItem]
var just_selected : bool = false
var editing : bool = false

const ICON_LAYER_PAINT = preload("res://UI/panels/layers/icons/layer_paint.tres")
const ICON_LAYER_PROC = preload("res://UI/panels/layers/icons/layer_proc.tres")
const ICON_LAYER_MASK = preload("res://UI/panels/layers/icons/layer_mask.tres")
const ICONS = [ ICON_LAYER_PAINT, ICON_LAYER_PROC, ICON_LAYER_PROC, ICON_LAYER_MASK, ICON_LAYER_PROC]

var BUTTON_SHOWN = preload("res://UI/panels/layers/icons/visible.tres")
var BUTTON_HIDDEN = preload("res://UI/panels/layers/icons/not_visible.tres")

signal selection_changed(new_selected)

func _ready():
	set_column_expand(1, false)
	set_column_custom_minimum_width(1, 30)

func _make_custom_tooltip(for_text):
	if for_text == "":
		return null
	var panel = preload("res://UI/panels/layers/layer_tooltip.tscn").instantiate()
	var item : TreeItem = instance_from_id(for_text.to_int()) as TreeItem
	panel.set_layer(item.get_meta("layer"))
	return panel

func update_from_layers(layers_array : Array, selected_layers:Array[base_layer]) -> void:
	if !editing:
		selected_items.clear()
		clear()
		do_update_from_layers(layers_array, selected_layers, create_item())

func do_update_from_layers(layers_array : Array, selected_layers:Array[base_layer], parent_item : TreeItem=null) -> void:
	for l in layers_array:
		var new_item : TreeItem = create_item(parent_item)
		new_item.set_text(0, l.name)
		new_item.set_icon(0, ICONS[l.type])
		new_item.add_button(1, BUTTON_HIDDEN if l.hidden else BUTTON_SHOWN)
		new_item.set_meta("layer", l)
		new_item.set_tooltip_text(0, str(new_item.get_instance_id()))
		if l in selected_layers:
			new_item.select(0)
			selected_items.append(new_item)
		if !selected_layers.is_empty() and l == selected_layers[0]:
			# Active layer: the one tools apply to
			new_item.set_custom_color(0, ToolsManager.active_layer_color)
			new_item.set_custom_bg_color(0, Color(ToolsManager.active_layer_color, 0.18))
		if l.children.size() > 0:
			do_update_from_layers(l.children, selected_layers, new_item)


# Drag & drop to reorder or reparent layers.
# The tree is rebuilt every frame, so the drag carries the layers, not the TreeItems.
const DRAG_TYPE := "layers_tree_layers"

func _get_drag_data(at_position : Vector2):
	var item : TreeItem = get_item_at_position(at_position)
	if item == null or editing:
		return null
	var dragged : Array[base_layer] = []
	var item_layer : base_layer = item.get_meta("layer")
	if layers and layers.selected_layers.has(item_layer):
		# Drag the whole selection, keeping tree order, skipping layers whose parent is dragged too
		for selected in _layers_in_tree_order():
			if layers.selected_layers.has(selected) and !_has_dragged_ancestor(selected, layers.selected_layers):
				dragged.append(selected)
	else:
		dragged.append(item_layer)
	var label := Label.new()
	label.text = dragged[0].name if dragged.size() == 1 else "%d layers" % dragged.size()
	set_drag_preview(label)
	return { "type": DRAG_TYPE, "layers": dragged }

func _can_drop_data(at_position : Vector2, data) -> bool:
	if !(data is Dictionary) or data.get("type") != DRAG_TYPE or layers == null:
		return false
	drop_mode_flags = DROP_MODE_ON_ITEM | DROP_MODE_INBETWEEN
	var target := _get_drop_target(at_position)
	if target.is_empty():
		return false
	for layer in data.layers:
		# Can't move a layer into itself or its own children
		if target.parent != null and layers.is_ancestor_of(layer, target.parent):
			return false
	return true

func _drop_data(at_position : Vector2, data) -> void:
	if !_can_drop_data(at_position, data):
		return
	move_layers_to(data.layers, _get_drop_target(at_position))

## Moves [param dragged] layers, in order, to [param target] ({parent, index}), as one undo step.
func move_layers_to(dragged : Array, target : Dictionary) -> void:
	var index : int = target.index
	var undo_redo : UndoRedo = ProjectsManager.current_project.undo_redo
	undo_redo.create_action("Move Layers")
	var undo_calls : Array[Callable] = []
	for layer in dragged:
		var from_array : Array = layers.find_parent_array(layer)
		var from_index : int = from_array.find(layer)
		var to_array : Array = target.parent.children if target.parent else layers.layers
		var final_index : int = to_array.size() if index < 0 else index
		if to_array == from_array and final_index > from_index:
			final_index -= 1 # The layer itself is removed first
		undo_redo.add_do_method(layers._place_layer.bind(layer, target.parent, final_index))
		undo_calls.append(layers._place_layer.bind(layer, layer.parent, from_index))
		layers._place_layer(layer, target.parent, final_index)
		if index >= 0:
			index = final_index + 1 # Keep the dropped layers together, in order
	# Undo puts them back in reverse order, so each saved index is valid again
	undo_calls.reverse()
	for call in undo_calls:
		undo_redo.add_undo_method(call)
	undo_redo.commit_action(false)
	_on_layers_changed()

## Where a drop at [param at_position] goes: {parent: base_layer or null, index: int (-1 = last)}.
func _get_drop_target(at_position : Vector2) -> Dictionary:
	var item : TreeItem = get_item_at_position(at_position)
	if item == null:
		return { "parent": null, "index": -1 } # Empty space: end of the top level
	var item_layer : base_layer = item.get_meta("layer")
	match get_drop_section_at_position(at_position):
		0: # On the item: make it the parent
			if item_layer is project_layer:
				return {} # Project layers show another project's layers
			return { "parent": item_layer, "index": -1 }
		-1, 1: # Before/after the item, with the same parent
			var siblings : Array = layers.find_parent_array(item_layer)
			var index : int = siblings.find(item_layer)
			if get_drop_section_at_position(at_position) == 1:
				index += 1
			return { "parent": item_layer.parent, "index": index }
	return {}

func _layers_in_tree_order(layers_array : Array = layers.layers) -> Array[base_layer]:
	var result : Array[base_layer] = []
	for l in layers_array:
		result.append(l)
		result.append_array(_layers_in_tree_order(l.children))
	return result

func _has_dragged_ancestor(layer : base_layer, dragged : Array) -> bool:
	var p : base_layer = layer.parent
	while p != null:
		if dragged.has(p):
			return true
		p = p.parent
	return false

func _on_tree_button_clicked(item, _column, _id, _mouse_button_index):
	var l = item.get_meta("layer")
	l.hidden = !l.hidden
	_on_layers_changed()

func _on_Tree_gui_input(event):
	if event is InputEventMouseButton and event.double_click == true:
		for selected_item in selected_items:
			if !(selected_item.get_meta("layer") is project_layer):
				selected_item.set_editable(0, true)
				editing = true
		just_selected = false

func _on_Tree_item_edited():
	for selected_item in selected_items:
		selected_item.get_meta("layer").name = selected_item.get_text(0)
	editing = false

func _on_layers_changed():
	layers._on_layers_changed()



func _on_tree_nothing_selected():
	selected_items = []
	emit_signal("selection_changed", selected_items)


func _on_tree_multi_selected(item, _column, selected):
#	item.set_selectable(column,true)
	if selected:
		if !selected_items.has(item):
			selected_items.append(item)
	else:
		selected_items.erase(item)
#	if !selected_items.is_empty():
#		for selected_item in selected_items:
#			selected_item.set_editable(0, true)
	emit_signal("selection_changed", selected_items)
