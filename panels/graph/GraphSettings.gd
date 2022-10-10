extends VBoxContainer

var canvas : SubViewport 
var background
var container
func _ready():
	%CanvasX.connect("value_changed",value_changed)
	%CanvasY.connect("value_changed",value_changed)
func _process(delta):
	if !mt_globals.main_window.get_current_graph_edit():
		return
	if !canvas or canvas != mt_globals.main_window.get_current_graph_edit().canvas:
		canvas = mt_globals.main_window.get_current_graph_edit().canvas
		background = mt_globals.main_window.get_current_graph_edit().get_node("SubViewportContainer/Background")
		container = mt_globals.main_window.get_current_graph_edit().get_node("SubViewportContainer")
		return
	if canvas.size.x != %CanvasX.value:
		%CanvasX.value = canvas.size.x
	if canvas.size.y != %CanvasY.value:
		%CanvasY.value = canvas.size.y

func value_changed(value):
	if canvas.size.x != %CanvasX.value:
		canvas.size.x = %CanvasX.value
		background.size.x = canvas.size.x
		container.size.x = canvas.size.x
	if canvas.size.y != %CanvasY.value:
		canvas.size.y = %CanvasY.value
		background.size.y = canvas.size.y
		container.size.y = canvas.size.y
