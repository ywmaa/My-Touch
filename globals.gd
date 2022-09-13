extends Node

# warning-ignore:unused_class_variable
@onready var menu_manager = $MenuManager

# warning-ignore:unused_class_variable
var main_window

var config : ConfigFile = ConfigFile.new()
const DEFAULT_CONFIG = {
	locale = "",
	confirm_quit = true,
	confirm_close_project = true,
	vsync = true,
	fps_limit = 145,
	idle_fps_limit = 20,
	ui_scale = 0,
}


func _enter_tree():
	config.load("user://cache.ini")
	for k in DEFAULT_CONFIG.keys():
		if ! config.has_section_key("config", k):
			config.set_value("config", k, DEFAULT_CONFIG[k])

func _exit_tree():
	config.save("user://cache.ini")

func _ready():
	pass # Replace with function body.


func has_config(key : String) -> bool:
	return config.has_section_key("config", key)

func get_config(key : String):
	if ! config.has_section_key("config", key):
		return DEFAULT_CONFIG[key]
	return config.get_value("config", key)

func set_config(key : String, value):
	config.set_value("config", key, value)

