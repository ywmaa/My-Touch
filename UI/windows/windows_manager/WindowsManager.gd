extends Panel
class_name window_manager

@export_enum("Layers Panel", "Layer Inspector", "Graph", "Tool Settings", "Project Settings", "Reference Panel")\
var init_window : int = 0


var windows = [
	{scene=preload("res://UI/panels/layers/layers.tscn"),name="Layers Panel"},
	{scene=preload("res://UI/panels/layer_inspector/LayerInspector.tscn"),name="Layer Inspector"},
	{scene=preload("res://UI/panels/graph/graph.tscn"),name="Graph"},
	{scene=preload("res://UI/panels/tools bar/tool_settings.tscn"),name="Tool Settings"},
	{scene=preload("res://UI/panels/graph/GraphSettings.tscn"),name="Project Settings"},
	{scene=preload("res://UI/panels/reference/reference_panel.tscn"),name="Reference Panel"},
]

@onready var window_button : OptionButton = $VBoxContainer/WindowOptions
@onready var panel : PanelContainer = $VBoxContainer/PanelContainer

func _process(_delta):
	if $VBoxContainer/PanelContainer.get_child_count() == 0:
		change_window(window_button.get_selected_id())
	if name != windows[window_button.get_selected_id()].name:
		name = windows[window_button.get_selected_id()].name
func _ready():
	window_button.connect("item_selected",change_window)
	for window in windows:
		window_button.add_item(window.name)
	change_window(init_window)


func change_window(index:int):
	if panel.get_child_count() > 0:
		var child = panel.get_child(0)
		panel.remove_child(child)
		child.queue_free()
	panel.add_child(windows[index].scene.instantiate())
	window_button.select(index)
	
