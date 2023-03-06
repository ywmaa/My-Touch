extends Panel
class_name window_manager
var windows = [
	{scene=preload("res://panels/layers/layers.tscn"),name="Layers Panel"},
	{scene=preload("res://panels/layer_inspector/LayerInspector.tscn"),name="Layer Inspector"},
	{scene=preload("res://panels/tools bar/tool_settings.tscn"),name="Tool Settings"},
	{scene=preload("res://panels/graph/GraphSettings.tscn"),name="Project Settings"},
]

@onready var window_button : OptionButton = $VBoxContainer/WindowOptions
@onready var panel : PanelContainer = $VBoxContainer/PanelContainer

func _process(delta):
	if $VBoxContainer/PanelContainer.get_child_count() == 0:
		change_window(window_button.get_selected_id())
		
func _ready():
	window_button.connect("item_selected",change_window)
	for window in windows:
		window_button.add_item(window.name)


func change_window(index:int):
	if panel.get_child_count() > 0:
		var child = panel.get_child(0)
		panel.remove_child(child)
		child.queue_free()
	panel.add_child(windows[index].scene.instantiate())
	
