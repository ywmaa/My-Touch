extends VBoxContainer

var current_graph : MTGraph 
var current_layer : base_layer
var locked_aspect_icon = load("res://graphics/misc/lock_aspect.png")
var unlocked_aspect_icon = load("res://graphics/misc/lock_aspect_2.png")
# Called when the node enters the scene tree for the first time.
func _ready():
	%PositionX.connect("value_changed",value_changed.bind(%PositionX))
	%PositionY.connect("value_changed",value_changed.bind(%PositionY))

	%Rotation.connect("value_changed",value_changed.bind(%Rotation))


	%SizeX.connect("value_changed",value_changed.bind(%SizeX))
	%SizeY.connect("value_changed",value_changed.bind(%SizeY))

	%ScaleX.connect("value_changed",value_changed.bind(%ScaleX))
	%ScaleY.connect("value_changed",value_changed.bind(%ScaleY))
	
	%Opacity.connect("value_changed",value_changed.bind(%Opacity))
	
	%LabelText.connect("text_changed",value_changed.bind(%LabelText))
	
	$CanvasRes3/Aspect.connect("pressed",func():
		if current_layer.lock_aspect == true:
			current_layer.lock_aspect = false
			$CanvasRes3/Aspect.icon = unlocked_aspect_icon
		else:
			current_layer.lock_aspect = true
			$CanvasRes3/Aspect.icon = locked_aspect_icon
		)
	




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
	if current_layer.main_object == null:
		return
	visible = true
	if current_layer.main_object.position.x != %PositionX.value:
		%PositionX.value = current_layer.main_object.position.x
	if current_layer.main_object.position.y != %PositionY.value:
		%PositionY.value = current_layer.main_object.position.y

	if current_layer.main_object.rotation_degrees != %Rotation.value:
		%Rotation.value = fmod(current_layer.main_object.rotation_degrees, 360)

	if current_layer.main_object.get_rect().size.x != %SizeX.value:
		%SizeX.value = current_layer.main_object.get_rect().size.x
	if current_layer.main_object.get_rect().size.y != %SizeY.value:
		%SizeY.value = current_layer.main_object.get_rect().size.y

	if current_layer.main_object.scale.x != %ScaleX.value:
		%ScaleX.value = current_layer.main_object.scale.x
	if current_layer.main_object.scale.y != %ScaleY.value:
		%ScaleY.value = current_layer.main_object.scale.y
		
	if current_layer.lock_aspect == true:
		if $CanvasRes3/Aspect.icon != locked_aspect_icon:
			$CanvasRes3/Aspect.icon = locked_aspect_icon
		else:
			$CanvasRes3/Aspect.icon = unlocked_aspect_icon
		
	if current_layer.opacity != %Opacity.value:
		%Opacity.value = current_layer.opacity
	
	if current_layer is text_layer:
		if current_layer.main_object.text != %LabelText.placeholder_text:
			%LabelText.placeholder_text = current_layer.main_object.text
		$TextProperties.visible = true
	else:
		$TextProperties.visible = false


func value_changed(value,property):
	
	if current_layer.main_object.position.x != %PositionX.value and property == %PositionX:
		current_layer.main_object.position.x = %PositionX.value
	if current_layer.main_object.position.y != %PositionY.value and property == %PositionY:
		current_layer.main_object.position.y = %PositionY.value

	if current_layer.main_object.rotation_degrees != %Rotation.value and property == %Rotation:
		current_layer.main_object.rotation_degrees = fmod(%Rotation.value, 360)

	if current_layer.main_object.scale.x != %ScaleX.value and property == %ScaleX:
		current_layer.main_object.scale.x = %ScaleX.value
	if current_layer.main_object.scale.y != %ScaleY.value and property == %ScaleY:
		current_layer.main_object.scale.y = %ScaleY.value
		
	if current_layer.opacity != %Opacity.value and property == %Opacity:
		current_layer.opacity = %Opacity.value
		
	if property == %LabelText:
		if current_layer.main_object.text != %LabelText.text:
			current_layer.main_object.text = %LabelText.text
