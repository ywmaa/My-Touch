extends VBoxContainer

var current_graph : MTGraph 
var current_layer : base_layer
# Called when the node enters the scene tree for the first time.
func _ready():
	%PositionX.connect("value_changed",value_changed.bind(%PositionX))
	%PositionY.connect("value_changed",value_changed.bind(%PositionY))

	%SizeX.connect("value_changed",value_changed.bind(%SizeX))
	%SizeY.connect("value_changed",value_changed.bind(%SizeY))

	%ScaleX.connect("value_changed",value_changed.bind(%ScaleX))
	%ScaleY.connect("value_changed",value_changed.bind(%ScaleY))


func _process(delta):
	if !mt_globals.main_window.get_current_graph_edit():
		visible = false
		return
	if !current_graph or current_graph != mt_globals.main_window.get_current_graph_edit():
		visible = false
		current_graph = mt_globals.main_window.get_current_graph_edit()
		return
	if current_graph.layers.selected_layers.is_empty():
		visible = false
		return
	current_layer = current_graph.layers.selected_layers.front()
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


func value_changed(value,property):
	
	if current_layer.image.position.x != %PositionX.value and property == %PositionX:
		current_layer.image.position.x = %PositionX.value
	if current_layer.image.position.y != %PositionY.value and property == %PositionY:
		current_layer.image.position.y = %PositionY.value

	if current_layer.image.scale.x != %ScaleX.value and property == %ScaleX:
		current_layer.image.scale.x = %ScaleX.value
	if current_layer.image.scale.y != %ScaleY.value and property == %ScaleY:
		current_layer.image.scale.y = %ScaleY.value
