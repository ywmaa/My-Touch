extends VBoxContainer

var project
var has_focus

func _ready():
	%CanvasX.connect("value_changed",value_changed)
	%CanvasY.connect("value_changed",value_changed)
	%AntiAliasing.connect("item_selected",value_changed)
	self.connect("mouse_entered",_on_mouse_entered)
	self.connect("mouse_exited",_on_mouse_exited)
func _process(_delta):
	if !ProjectsManager.current_project:
		return
	if !project or project != ProjectsManager.current_project:
		project = ProjectsManager.current_project
		if project:
			var canvas_size : Vector2 = project.canvas_size
			%CanvasX.value = canvas_size.x
			%CanvasY.value = canvas_size.y
		return
	if project.canvas_size.x != %CanvasX.value:
		%CanvasX.value = project.canvas_size.x
	if project.canvas_size.y != %CanvasY.value:
		%CanvasY.value = project.canvas_size.y
		
	if get_viewport().msaa_2d != %AntiAliasing.selected:
		%AntiAliasing.selected = get_viewport().msaa_2d


func value_changed(value):
	if project.canvas_size.x != %CanvasX.value:
		project.canvas_size.x = %CanvasX.value
	if project.canvas_size.y != %CanvasY.value:
		project.canvas_size.y = %CanvasY.value

	if get_viewport().msaa_2d != %AntiAliasing.selected:
		get_viewport().msaa_2d = %AntiAliasing.selected

func _on_mouse_entered():
	has_focus = true


func _on_mouse_exited():
	has_focus = false
