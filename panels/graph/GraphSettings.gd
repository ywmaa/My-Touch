extends VBoxContainer

var project
var has_focus

func _ready():
	%CanvasX.connect("value_changed",value_changed)
	%CanvasY.connect("value_changed",value_changed)
	self.connect("mouse_entered",_on_mouse_entered)
	self.connect("mouse_exited",_on_mouse_exited)
func _process(delta):
	if !mt_globals.main_window.get_current_graph_edit():
		return
	if !project or project != mt_globals.main_window.get_current_graph_edit():
		project = mt_globals.main_window.get_current_graph_edit()
		
		return
	if project.canvas_size.x != %CanvasX.value:
		%CanvasX.value = project.canvas_size.x
	if project.canvas_size.y != %CanvasY.value:
		%CanvasY.value = project.canvas_size.y


func value_changed(value):
	if project.canvas_size.x != %CanvasX.value:
		project.canvas_size.x = %CanvasX.value
	if project.canvas_size.y != %CanvasY.value:
		project.canvas_size.y = %CanvasY.value

func _on_mouse_entered():
	has_focus = true


func _on_mouse_exited():
	has_focus = false
