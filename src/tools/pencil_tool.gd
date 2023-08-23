extends ToolBase

@export var crosshair_color := Color(0.5, 0.5, 0.5, 0.75)
@export var crosshair_size := 3
@export var crosshair_size_ruler := 32

var ruler_mode := false
var jaggies_removal := true

var drawing_color := Color()
var drawing_positions : Array[Vector2]
var image_size := Vector2()
var last_affected_rect := Rect2i()

var edited_object
var EditedImage : Image

func _init():
	tool_name = "Pencil Tool"
	tool_button_shortcut = "Shift+P"
	tool_desc = ""
	tool_icon = get_icon_from_project_folder("pencil")
	drawing_positions = []
func get_tool_inspector_properties():
	var PropertiesView : Array = []
	var PropertiesGroups : Array[String] = []
	PropertiesGroups.append("Settings")
	var PropertiesToShow : Dictionary = {}
	PropertiesToShow["ruler_mode"] = "Settings"
	PropertiesToShow["jaggies_removal"] = "Settings"
	PropertiesToShow["drawing_color"] = "Settings"
	PropertiesView.append(PropertiesGroups)
	PropertiesView.append(PropertiesToShow)
	return PropertiesView

func shortcut_pressed():
	if Input.is_action_just_pressed("pencil") and not Input.is_key_pressed(KEY_SHIFT) and not Input.is_key_pressed(KEY_CTRL) and not Input.is_key_pressed(KEY_ALT):
		ToolsManager.shortcut_tool = self
		if !tool_active:
			enable_tool()
			return
		if tool_active:
			confirm_tool()
			return
	if Input.is_action_just_pressed("mouse_left"):
		if !tool_active and ToolsManager.current_tool == self:
			enable_tool()
			return
		if tool_active:
			confirm_tool()
			return
	if Input.is_action_just_pressed("cancel"):
		cancel_tool()
	
func mouse_pressed(
	event : InputEventMouseButton,
	_image : base_layer,
):
	

	if event.button_index == MOUSE_BUTTON_RIGHT and tool_active:
		cancel_tool()
	if event.button_index == MOUSE_BUTTON_LEFT and tool_active and !event.pressed:
		confirm_tool()
	
	if tool_active:
		var object_correction = edited_object.main_object.position-edited_object.size/2
		last_affected_rect = Rect2i(ToolsManager.current_mouse_position-object_correction, Vector2i.ZERO)
		_add_point(ToolsManager.current_mouse_position-object_correction)
func enable_tool(): # Save History and Enable Tool
	edited_object = ToolsManager.get_paint_layer()
	EditedImage = edited_object.main_object.texture.get_image()
	image_size = EditedImage.get_size()
	super.enable_tool()
func cancel_tool(): # Redo Actions
	super.cancel_tool()
func confirm_tool(): # Confirm Actions
	for x in drawing_positions:
		set_image_pixelv(EditedImage, x, drawing_color)
	if edited_object:
		edited_object.main_object.texture.update(EditedImage) #= ImageTexture.create_from_image(EditedImage)
		edited_object.save_paint_image()
	drawing_positions.clear()
	super.confirm_tool()

func get_affected_rect():
	return last_affected_rect.grow_individual(0, 0, 1, 1)


func mouse_moved(event : InputEventMouseMotion):
	if !tool_active:
		return
	var pt_count = max(abs(event.relative.x), abs(event.relative.y))
	var lerp_step = 1 / pt_count
	var object_correction = edited_object.main_object.position-edited_object.size/2
	for i in pt_count:
		_add_point(ToolsManager.current_mouse_position-object_correction + Vector2.ONE - event.relative * i * lerp_step - Vector2.ONE)


func _add_point(pt : Vector2):
	pt = pt.floor()
	if drawing_positions.size() >= 1 && drawing_positions[-1] == pt:
		return

	if pt.x < 0 || pt.y < 0 || pt.x >= image_size.x || pt.y >= image_size.y:
		return

	if jaggies_removal && drawing_positions.size() > 2:
		var diff1 = (drawing_positions[-1] - drawing_positions[-2]).abs()
		var diff2 = (pt - drawing_positions[-1]).abs()
		if diff1 != diff2 && diff1.x + diff1.y + diff2.x + diff2.y == 2:
			drawing_positions.pop_back()

	drawing_positions.append(pt)
	last_affected_rect = last_affected_rect.expand(pt)


func draw_preview(image_view : CanvasItem, mouse_position : Vector2i):
	if tool_active:
		for x in drawing_positions:
			image_view.draw_rect(Rect2(x, Vector2.ONE), drawing_color)

	if !ruler_mode:
		draw_crosshair(image_view, mouse_position, crosshair_size, crosshair_color)

	else:
		draw_crosshair(image_view, mouse_position, crosshair_size_ruler, crosshair_color)
		var diag_distance := 8
		var posf := Vector2(mouse_position) + Vector2(0.5, 0.5)
		image_view.draw_line(posf + Vector2(-1, +1) * diag_distance, posf + Vector2(-1, +1) * (diag_distance + crosshair_size_ruler), crosshair_color, 1)
		image_view.draw_line(posf + Vector2(+1, -1) * diag_distance, posf + Vector2(+1, -1) * (diag_distance + crosshair_size_ruler), crosshair_color, 1)
		image_view.draw_line(posf + Vector2(+1, +1) * diag_distance, posf + Vector2(+1, +1) * (diag_distance + crosshair_size_ruler), crosshair_color, 1)
		image_view.draw_line(posf + Vector2(-1, -1) * diag_distance, posf + Vector2(-1, -1) * (diag_distance + crosshair_size_ruler), crosshair_color, 1)
