# Represents and draws a bounding rectangle 
# centered around the center of its bottom edge

extends Node2D
class_name RectExtents

var my_layer : base_layer

var size: Vector2 = Vector2(0.0, 0.0):
	set(value):
		size = value
		_recalculate_rect()
		queue_redraw()
var color: Color = Color("#ff0ea7"):
	set(value):
		color = value
		queue_redraw()
var offset: Vector2:
	set(value):
		offset = value
		_recalculate_rect()
		queue_redraw()

var _rect: Rect2


func _recalculate_rect():
	_rect = Rect2(-1.0 * size / 2 + offset, size)


func _draw() -> void:
	draw_rect(_rect, color, false)
	draw_gizmos()


func has_point(point: Vector2) -> bool:
	var rect_global = Rect2(global_position + _rect.position, _rect.size)
	return rect_global.has_point(point)
	
enum Anchors { TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT }

# List of all anchors drawn over the RectExtents node
# Each anchor has the form { position: Vector2, rect: Rect2 }
var anchors: Array
# Get and stores the anchor the user is dragging from the anchors array above
var dragged_anchor: Dictionary = {}
# Stores the RectExtents' state when the user starts dragging an anchor
# we need this info to safely add undo/redo support when the drag operation ends
var rect_drag_start: Dictionary = {'size': Vector2(), 'offset': Vector2()}

const CIRCLE_RADIUS: float = 6.0
const STROKE_RADIUS: float = 2.0
const STROKE_COLOR = Color("#f50956")
const FILL_COLOR = Color("#ffffff")

#func handles(object: Object) -> bool:
#	# Required to use forward_canvas_draw_... below
#	return object is RectExtents
var mouse_pos
func _process(delta):
	queue_redraw()
	visible = false
	if !mt_globals.main_window.get_current_graph_edit():
		return
#	if !mt_globals.main_window.get_current_graph_edit().layers.selected_layers.has(my_layer):
#		return
	visible = true
	if not visible:
		return
	mouse_pos = mt_globals.main_window.get_current_graph_edit().get_local_mouse_position()-(my_layer.get_rect().position+my_layer.get_rect().size/2)
	var graph : MTGraph = mt_globals.main_window.get_current_graph_edit()
	var camera = graph.camera
	mouse_pos = mouse_pos/camera.zoom/my_layer.main_object.scale
	# Clicking and releasing the click
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		
		if dragged_anchor.is_empty():
			for anchor in anchors:
				if not anchor['rect'].has_point(mouse_pos):
					continue
				dragged_anchor = anchor
				rect_drag_start = {
					'size': size,
					'offset': offset,
				}
				return
	if not dragged_anchor.is_empty() and Input.is_action_just_released("mouse_left"):
		drag_to(mouse_pos)
		
		var undo : UndoRedo = mt_globals.main_window.get_current_graph_edit().undo_redo
		undo.create_action("Move anchor")
		undo.add_do_property(my_layer.main_object, "scale", size/rect_drag_start['size'])
		undo.add_undo_property(my_layer.main_object, "scale", rect_drag_start['size']/my_layer.main_object.get_rect().size)

#		undo.add_do_property(my_layer.main_object, "offset", offset)
#		undo.add_undo_property(my_layer.main_object, "offset", rect_drag_start['offset'])

		undo.commit_action()
		dragged_anchor = {}
		return
	if dragged_anchor.is_empty():
		return
	# Dragging
	if Input.get_last_mouse_velocity() != Vector2.ZERO:
		drag_to(mouse_pos)
		return
	# Cancelling with ui_cancel
	if Input.is_action_pressed("ui_cancel"):
		dragged_anchor = {}

		return
	return
	

func draw_gizmos() -> void:
	# Calculate the 4 anchor positions and bounding rectangles
	# from the selected RectExtents node and draw them as circles
	# over the viewport

	var half_size: Vector2 = size / 2.0
	var edit_anchors := {
		Anchors.TOP_LEFT: position - half_size + offset,
		Anchors.TOP_RIGHT: position + Vector2(half_size.x, -1.0 * half_size.y) + offset,
		Anchors.BOTTOM_LEFT: position + Vector2(-1.0 * half_size.x, half_size.y) + offset,
		Anchors.BOTTOM_RIGHT: position + half_size + offset,
	}

	var transform_viewport := get_viewport_transform()
	var transform_global := get_canvas_transform()
	anchors = []
	var anchor_size: Vector2 = Vector2(CIRCLE_RADIUS * 2.0, CIRCLE_RADIUS * 2.0)
	for coord in edit_anchors.values():
		var anchor_center: Vector2 = transform_viewport * (transform_global * coord)
		var new_anchor = {
			'position': anchor_center,
			'rect': Rect2(anchor_center - anchor_size / 2.0, anchor_size),
		}
		draw_anchor(new_anchor)
		anchors.append(new_anchor)


func draw_anchor(anchor: Dictionary, overlay: Control = null) -> void:
	var pos = anchor['position']
	draw_circle(pos, CIRCLE_RADIUS + STROKE_RADIUS, STROKE_COLOR)
	draw_circle(pos, CIRCLE_RADIUS, FILL_COLOR)


func drag_to(event_position: Vector2) -> void:
	if dragged_anchor.is_empty():
		return
	# Update the rectangle's size. Only resizes uniformly around the center for now
	event_position.y *= -1
	var target_size = (event_position - offset) * 2.0
	size = target_size


