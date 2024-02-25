extends image_layer
class_name paint_layer

var paint_image_path : String 

func set_position(_v):
	if !image:
		return
	if !image.texture:
		return
	image.position = image.texture.get_size()/2
	emit_changed()

func set_rotation(_v):
	pass

func set_size(_v):
	pass

func set_scale(_v):
	pass

func update_path(path:String = "./"):
	paint_image_path = path.path_join(name.c_unescape() + ".png")

func _init():
	type = LAYER_TYPE.BRUSH
	affect_children_opacity = true

func save_paint_image():
	if paint_image_path:
		image.texture.get_image().save_png(paint_image_path)


func canvas_changed(_prev:Vector2, new:Vector2):
	var prev_image = texture.get_image()
	prev_image.crop(new.x,new.y)
	prev_image.save_png(paint_image_path)
	texture.set_image(prev_image)
	position = Vector2.ZERO #Just Invoking the setter, no need to assign a value

func get_canvas_node() -> Node:
	if image == null:
		return null
	return image

func refresh():
	update_path(parent_project.project_folder_abs_path + "/")
	if !parent_project.is_connected("canvas_size_changed",canvas_changed):
		parent_project.connect("canvas_size_changed",canvas_changed)
	var load_test : Error = Image.new().load(paint_image_path)
	if load_test == OK:
		var load_image = Image.load_from_file(paint_image_path)
		texture.set_image(load_image)
		if image:
			image.texture = texture
			image.name = name
		position = Vector2.ZERO #Just Invoking the setter, no need to assign a value
	else:
		Image.create(ProjectsManager.current_project.canvas_size.x,ProjectsManager.current_project.canvas_size.y,false,Image.FORMAT_RGBA8).save_png(paint_image_path)
		var load_image = Image.load_from_file(paint_image_path)
		texture.set_image(load_image)
		if image:
			image.texture = texture
			image.name = name
		position = Vector2.ZERO #Just Invoking the setter, no need to assign a value


#func get_rect() -> Rect2:
##	var graph : MTGraph = mt_globals.main_window.get_current_graph_edit()
#	var camera = graph.camera
#	var canvas_position : Vector2 = graph.size/2-camera.offset*(camera.zoom)
#	return Rect2(canvas_position+(main_object.position*camera.zoom)-(Vector2(10,10)*main_object.scale*camera.zoom/2),Vector2(10,10)*main_object.scale*camera.zoom)
