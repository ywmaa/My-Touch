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
		if l.children.size() > 0:
			do_update_from_layers(l.children, selected_layers, new_item)


func get_drag_data(_position : Vector2):
	var l = get_selected().get_meta("layer")
	var label : Label = Label.new()
	label.text = l.name
	set_drag_preview(label)
	return get_selected()

func item_is_child(i1 : TreeItem, i2 : TreeItem):
	while i1 != null:
		if i1 == i2:
			return true
		i1 = i1.get_parent()
	return false

func can_drop_data(p_position : Vector2, data):
	drop_mode_flags = DROP_MODE_ON_ITEM | DROP_MODE_INBETWEEN
	var target_item = get_item_at_position(p_position)
	if target_item != null and !item_is_child(target_item, data):
		return true
	return false

static func get_item_index(item : TreeItem) -> int:
	var rv : int = 0
	while item.get_prev() != null:
		item = item.get_prev()
		rv += 1
	return rv

func drop_data(p_position : Vector2, data):
	var target_item : TreeItem = get_item_at_position(p_position)
	if data != null and target_item != null and !item_is_child(target_item, data):
		var layer = data.get_meta("layer")
		match get_drop_section_at_position(p_position):
			0:
				layers.move_layer_into(layer, target_item.get_meta("layer"))
			-1:
				if target_item.get_parent() != null:
					
					layers.move_layer_into(layer, target_item.get_parent().get_meta("layer"), LayersTree.get_item_index(target_item))
				else:
					print("Cannot move item")
			1:
				if target_item.get_parent() != null:
					layers.move_layer_into(layer, target_item.get_parent().get_meta("layer"), LayersTree.get_item_index(target_item)+1)
				else:
					print("Cannot move item")
		_on_layers_changed()

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




