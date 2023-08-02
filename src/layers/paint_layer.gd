extends base_layer
class_name paint_layer

var paint_image_path : String 

func update_path(path:String = "./"):
	paint_image_path = path.path_join(name.c_unescape() + ".png")

func init(_name: String,_path: String,p_layer_type : layer_type):
	name = _name
	type = p_layer_type
	main_object = image
	refresh()

func _init():
	type = layer_type.brush
	affect_children_opacity = true
	

func get_image() -> Node:
	refresh()
	if main_object == null:
		return null
	return main_object

func save_paint_image():
	if paint_image_path:
		image.texture.get_image().save_png(paint_image_path)
func refresh():
	if ProjectsManager.project.save_path.is_empty():
		update_path("user://")
	else:
		update_path(ProjectsManager.project.save_path.get_base_dir() + "/")
	var load_test : Error = Image.new().load(paint_image_path)
	if load_test == OK:
		var load_image = Image.load_from_file(paint_image_path)
		texture.set_image(load_image)
		if image:
			image.texture = texture
			image.name = name
			main_object = image
		position = image.texture.get_size()/2
	else:
		Image.create(ProjectsManager.project.canvas_size.x,ProjectsManager.project.canvas_size.y,false,Image.FORMAT_RGBA8).save_png(paint_image_path)
		var load_image = Image.load_from_file(paint_image_path)
		texture.set_image(load_image)
		if image:
			image.texture = texture
			image.name = name
			main_object = image
		position = image.texture.get_size()/2


func get_rect() -> Rect2:
	var graph : MTGraph = mt_globals.main_window.get_current_graph_edit()
	var camera = graph.camera
	var canvas_position : Vector2 = graph.size/2-camera.offset*(camera.zoom)
	return Rect2(canvas_position+(main_object.position*camera.zoom)-(Vector2(10,10)*main_object.scale*camera.zoom/2),Vector2(10,10)*main_object.scale*camera.zoom)
