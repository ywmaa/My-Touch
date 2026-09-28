extends Tree
class_name LayersTree
var layers = null
var selected_items : Array[TreeItem]
var just_selected : bool = false
var editing : bool = false

const ICON_LAYER_PAINT = preload("res://UI/panels/layers/icons/layer_paint.tres")
const ICON_LAYER_PROC = preload("res://UI/panels/layers/icons/layer_proc.tres")
const ICON_LAYER_MASK = preload("res://UI/panels/layers/icons/layer_mask.tres")
# Indexed by base_layer.LAYER_TYPE
const ICONS = [ ICON_LAYER_PAINT, ICON_LAYER_PROC, ICON_LAYER_PROC, ICON_LAYER_MASK, ICON_LAYER_PROC, ICON_LAYER_PROC, ICON_LAYER_PROC, ICON_LAYER_PROC, ICON_LAYER_PAINT ]

var BUTTON_SHOWN = preload("res://UI/panels/layers/icons/visible.tres")
var BUTTON_HIDDEN = preload("res://UI/panels/layers/icons/not_visible.tres")

signal selection_changed(new_selected)

func _ready():
	set_column_expand(1, false)
	set_column_custom_minimum_width(1, 30)
	drop_mode_flags = DROP_MODE_ON_ITEM | DROP_MODE_INBETWEEN # Also used by the touch reorder
	set_process(false) # Only while waiting for a long press

# Touch reorder. Godot's drag & drop only starts with the left button, but on Android a
# long press becomes a right click (enable_long_press_as_right_click), and a quick drag scrolls
# the tree. So a long press (the right click, or holding still) starts a reorder that follows
# the finger and drops on release.
const TOUCH_HOLD_TIME_MS := 450
const TOUCH_MOVE_TOLERANCE := 12.0
var _touch_hold_pending : bool = false
var _touch_press_position : Vector2
var _touch_press_time : int
var _touch_reorder : bool = false
var _touch_dragged : Array[base_layer] = []
var _touch_position : Vector2

func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.device == InputEvent.DEVICE_ID_EMULATION:
			_touch_hold_pending = true
			_touch_press_position = event.position
			_touch_press_time = Time.get_ticks_msec()
			set_process(true)
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and (event.device == InputEvent.DEVICE_ID_EMULATION or DisplayServer.is_touchscreen_available()):
			_start_touch_reorder(event.position) # Long press on Android
			accept_event()
		elif !event.pressed:
			_touch_hold_pending = false
			if _touch_reorder:
				_finish_touch_reorder(event.position)
				accept_event()
	elif event is InputEventMouseMotion:
		if _touch_reorder:
			_touch_position = event.position
			queue_redraw()
			accept_event() # Don't scroll the tree meanwhile
		elif _touch_hold_pending and event.position.distance_to(_touch_press_position) > TOUCH_MOVE_TOLERANCE:
			_touch_hold_pending = false # Moved: it's a scroll

func _process(_delta : float) -> void:
	if !_touch_hold_pending:
		set_process(false)
	elif Time.get_ticks_msec() - _touch_press_time >= TOUCH_HOLD_TIME_MS:
		_touch_hold_pending = false
		_start_touch_reorder(_touch_press_position)

func _start_touch_reorder(at_position : Vector2) -> void:
	var item : TreeItem = get_item_at_position(at_position)
	if item == null or editing or layers == null:
		return
	_touch_hold_pending = false
	_touch_dragged = _dragged_layers_for(item)
	_touch_reorder = true
	_touch_position = at_position
	Input.vibrate_handheld(30)
	queue_redraw()

func _finish_touch_reorder(at_position : Vector2) -> void:
	_touch_reorder = false
	var target := _get_drop_target(at_position)
	if _is_valid_drop(_touch_dragged, target):
		move_layers_to(_touch_dragged, target)
		_on_layers_changed()
	_touch_dragged = []
	queue_redraw()

func _draw() -> void:
	if !_touch_reorder:
		return
	var color : Color = ToolsManager.active_layer_color
	var target := _get_drop_target(_touch_position)
	var item : TreeItem = get_item_at_position(_touch_position)
	if !_is_valid_drop(_touch_dragged, target):
		color = Color(0.9, 0.2, 0.2)
	# Where it will land: a box around the new parent, or a line between layers
	if item:
		var rect := get_item_area_rect(item)
		rect.position.y -= get_scroll().y
		match get_drop_section_at_position(_touch_position):
			0: draw_rect(rect, color, false, 2.0)
			-1: draw_line(rect.position, Vector2(rect.end.x, rect.position.y), color, 3.0)
			1: draw_line(Vector2(rect.position.x, rect.end.y), rect.end, color, 3.0)
	# The dragged layer name next to the finger
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	var text := _drag_label(_touch_dragged)
	var text_position := _touch_position + Vector2(24, -24)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_rect(Rect2(text_position - Vector2(6, text_size.y), text_size + Vector2(12, 8)), Color(0, 0, 0, 0.7))
	draw_string(font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

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
	var dragged := _dragged_layers_for(item)
	var label := Label.new()
	label.text = _drag_label(dragged)
	set_drag_preview(label)
	return { "type": DRAG_TYPE, "layers": dragged }

## Dragging a selected layer drags the whole selection (in tree order, skipping layers whose
## parent is dragged too), otherwise just that layer.
func _dragged_layers_for(item : TreeItem) -> Array[base_layer]:
	var dragged : Array[base_layer] = []
	var item_layer : base_layer = item.get_meta("layer")
	if layers and layers.selected_layers.has(item_layer):
		for selected in _layers_in_tree_order():
			if layers.selected_layers.has(selected) and !_has_dragged_ancestor(selected, layers.selected_layers):
				dragged.append(selected)
	else:
		dragged.append(item_layer)
	return dragged

func _drag_label(dragged : Array) -> String:
	return dragged[0].name if dragged.size() == 1 else "%d layers" % dragged.size()

func _can_drop_data(at_position : Vector2, data) -> bool:
	if !(data is Dictionary) or data.get("type") != DRAG_TYPE or layers == null:
		return false
	return _is_valid_drop(data.layers, _get_drop_target(at_position))

func _is_valid_drop(dragged : Array, target : Dictionary) -> bool:
	if target.is_empty():
		return false
	for layer in dragged:
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
