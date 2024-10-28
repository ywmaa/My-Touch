extends Node

# warning-ignore:unused_class_variable
@onready var menu_manager = $MenuManager

# warning-ignore:unused_class_variable
var main_window : MainWindow
var show_left_tool_icon := true
var config : ConfigFile = ConfigFile.new()

#enum GridTypes { CARTESIAN, ISOMETRIC, ALL }
enum PressureSensitivity { NONE, ALPHA, SIZE, ALPHA_AND_SIZE }


var default_width := 1920
var default_height := 1080
var default_fill_color := Color(0, 0, 0, 0)
var pixel_grid_show_at_zoom := 150.0  # percentage
var pixel_grid_color := Color(91212121)
var guide_color := Color.PURPLE
var checker_size := 10
var checker_color_1 := Color(0.47, 0.47, 0.47, 1)
var checker_color_2 := Color(0.34, 0.35, 0.34, 1)
var checker_follow_movement := false
var checker_follow_scale := false
var tilemode_opacity := 1.0

# View menu options
var greyscale_view := false
var mirror_view := false
var draw_pixel_grid := false
var show_rulers := true
var show_guides := true

# Canvas related stuff
var can_draw := true
var move_guides_on_canvas := false

var show_x_symmetry_axis := false
var show_y_symmetry_axis := false

# Preferences
var pressure_sensitivity_mode = PressureSensitivity.NONE
var smooth_zoom := true
var zoom_speed : float = 0.06

const DEFAULT_CONFIG = {
	locale = "",
	confirm_quit = true,
	confirm_close_project = true,
	save_inactive_project = true,
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
	if !config.has_section_key("config", key):
		return DEFAULT_CONFIG[key]
	return config.get_value("config", key)

func set_config(key : String, value):
	config.set_value("config", key, value)
