extends ToolBase


var fill_mode := 0
var tolerance := 0.0

var drawing_color := Color.BLACK
var start_color := Color.TRANSPARENT
var affected_pixels := BitMap.new()
var last_affected_rect := Rect2i()
var copy_from_whole_canvas: bool = true
var image_to_copy : Image

var edited_object
var EditedImage : Image

func _init():
	tool_name = "Bucket Tool"
	tool_button_shortcut = "Shift+F"
	tool_desc = ""
	tool_icon = get_icon_from_project_folder("bucket")
func get_tool_inspector_properties():
	var PropertiesView : Array = []
	var PropertiesGroups : Array[String] = []
	PropertiesGroups.append("Settings")
	PropertiesGroups.append("Color")
	var PropertiesToShow : Dictionary = {}
	PropertiesToShow["copy_from_whole_canvas"] = "Settings"
	PropertiesToShow["tolerance:minvalue:0.0:maxvalue:1.0:step:0.01"] = "Settings"
	PropertiesToShow["fill_mode,Contiguous,Global"] = "Settings"
	PropertiesToShow["drawing_color"] = "Color"
	PropertiesView.append(PropertiesGroups)
	PropertiesView.append(PropertiesToShow)
	return PropertiesView



func shortcut_pressed():
	if Input.is_action_just_pressed("bucket") and not Input.is_key_pressed(KEY_SHIFT) and not Input.is_key_pressed(KEY_CTRL) and not Input.is_key_pressed(KEY_ALT):
		ToolsManager.shortcut_tool = self
		enable_tool()
		return
	if Input.is_action_just_pressed("mouse_left"):
		if ToolsManager.current_tool == self:
			enable_tool()
			return

func mouse_pressed(
	_event : InputEventMouseButton,
	_image : base_layer,
):
	pass


func enable_tool(): # Save History and Enable Tool
	edited_object = ToolsManager.get_paint_layer()

	EditedImage = edited_object.main_object.texture.get_image()
	if copy_from_whole_canvas:
		image_to_copy = mt_globals.main_window.get_node("AppRender").get_texture().get_image()
	else:
		image_to_copy = EditedImage
	start_color = image_to_copy.get_pixelv(ToolsManager.current_mouse_position)
	affected_pixels.create(EditedImage.get_size())
	var _task : TaskManager.Task = TaskManager.create_task(fill.bind(ToolsManager.current_mouse_position))
	confirm_tool()
#	ToolsManager.current_project.undo_redo.create_action("Move Layers")
#	for selected in ToolsManager.current_project.layers.selected_layers:
#		ToolsManager.current_project.undo_redo.add_undo_property(selected,"position",selected.position)
	super.enable_tool()
func cancel_tool(): # Redo Actions
	
#	if ToolsManager.current_project.layers.selected_layers:
#		for selected in ToolsManager.current_project.layers.selected_layers:
#			ToolsManager.current_project.undo_redo.add_do_property(selected, "position", selected.position)
#		ToolsManager.current_project.undo_redo.commit_action()
#		for selected in ToolsManager.current_project.layers.selected_layers:
#			ToolsManager.current_project.undo_redo.undo()
	super.cancel_tool()
func confirm_tool(): # Confirm Actions
	super.confirm_tool()
#	if EditedImage:
#		EditedImage.save_png(ToolsManager.current_project.layers.selected_layers[0].image_path)
#	ToolsManager.current_project.layers.selected_layers[0].texture = ImageTexture.create_from_image(EditedImage)
#	ToolsManager.current_project.layers.selected_layers[0].image.texture = ToolsManager.current_project.layers.selected_layers[0].texture
#	if ToolsManager.current_project.layers.selected_layers:
#		for selected in ToolsManager.current_project.layers.selected_layers:
#			ToolsManager.current_project.undo_redo.add_do_property(selected, "position", selected.position)
#		ToolsManager.current_project.undo_redo.commit_action()
	


func fill(start_pos : Vector2):
	last_affected_rect = ImageFillTools.fill_on_image(
		image_to_copy,
		affected_pixels,
		start_pos,
		tolerance,
		(fill_mode == 0) != Input.is_key_pressed(KEY_SHIFT),
		selection
	)
	for i in EditedImage.get_width():
		for j in EditedImage.get_height():
			if affected_pixels.get_bit(i, j):
				set_image_pixel(EditedImage, i, j, drawing_color)
	apply_texture()
	
	
func apply_texture():
	if edited_object:
		edited_object.main_object.texture.update(EditedImage) #= ImageTexture.create_from_image(EditedImage)
		edited_object.save_paint_image()
#	tool_active = false
#	confirm_tool()



func mouse_moved(_event : InputEventMouseMotion):
	pass

func draw_preview(_image_view : CanvasItem, _mouse_position : Vector2i):
	if !tool_active: return

#	image_view.draw_rect(Rect2(mouse_position, Vector2.ONE), Color.WHITE)
#	ImageFillTools.draw_bitmap(image_view, affected_pixels, drawing_color)
