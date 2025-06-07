extends Control
class_name ImageEdit

@export var texture_rect : TextureRect
@export var image_name : Label
# this is the image path
var image_path: String:
	set(v):
		image_path = v

signal image_path_changed(image_path:String)

func init(p_image_path:String):
	image_path = p_image_path
	image_name.text = image_path
	var current_project := ToolsManager.current_project
	var load_image = Image.load_from_file(current_project.project_folder_abs_path + "/" + image_path)
	texture_rect.texture = ImageTexture.new()
	texture_rect.texture.set_image(load_image)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var dialog = preload("res://UI/windows/file_dialog/file_dialog.tscn").instantiate()
		dialog.min_size = Vector2(500, 500)
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		dialog.add_filter("*.jpg,*.jpeg;JPEG Image")
		dialog.add_filter("*.png;PNG Image")
		dialog.add_filter("*.svg;SVG Image")
		dialog.add_filter("*.tga;TGA Image")
		dialog.add_filter("*.webp;WebP Image")
		add_child(dialog)
		var files = await dialog.select_files()
		if files.size() > 0:
			on_import_image_file(files[0])


func on_import_image_file(path:String):
	if !ToolsManager.current_project:
		return
	var current_project := ToolsManager.current_project
	var new_image_path : String = current_project.project_folder_abs_path + "/" + path.get_file()
	DirAccess.copy_absolute(path, new_image_path) # Move Image to Project Folder
	image_path = new_image_path
	image_name.text = new_image_path.get_file()
	image_path_changed.emit(image_path)
	var load_image = Image.load_from_file(new_image_path)
	texture_rect.texture = ImageTexture.new()
	texture_rect.texture.set_image(load_image)
