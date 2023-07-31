extends TextureRect


func _process(_delta):
	if !texture.viewport_path:
		texture.viewport_path = mt_globals.main_window.find_child("AppRender").get_path()

