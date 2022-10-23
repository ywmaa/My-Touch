extends VBoxContainer

var current_graph : MTGraph 
var current_layer : base_layer
# Called when the node enters the scene tree for the first time.
func _ready():
	%PositionX.connect("value_changed",value_changed)
	%PositionY.connect("value_changed",value_changed)

	%SizeX.connect("value_changed",value_changed)
	%SizeY.connect("value_changed",value_changed)

	%ScaleX.connect("value_changed",value_changed)
	%ScaleY.connect("value_changed",value_changed)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !mt_globals.main_window.get_current_graph_edit():
		visible = false
		return
	if !current_graph or current_graph != mt_globals.main_window.get_current_graph_edit():
		visible = false
		current_graph = mt_globals.main_window.get_current_graph_edit()
		return
	current_layer = current_graph.layers.selected_layers.front()
	if !current_layer:
		visible = false
		return
	visible = true
	if current_layer.image.position.x != %PositionX.value:
		%PositionX.value = current_layer.image.position.x
	if current_layer.image.position.y != %PositionY.value:
		%PositionY.value = current_layer.image.position.y

	if current_layer.image.get_rect().size.x != %SizeX.value:
		%SizeX.value = current_layer.image.get_rect().size.x
	if current_layer.image.get_rect().size.y != %SizeY.value:
		%SizeY.value = current_layer.image.get_rect().size.y

	if current_layer.image.scale.x != %ScaleX.value:
		%ScaleX.value = current_layer.image.scale.x
	if current_layer.image.scale.y != %ScaleY.value:
		%ScaleY.value = current_layer.image.scale.y


func value_changed(value):
	if !current_layer:
		return
#	if current_layer.image.position.x != %PositionX.value:
#		current_layer.image.position.x = %PositionX.value
#	if current_layer.image.position.y != %PositionY.value:
#		current_layer.image.position.y = %PositionY.value
