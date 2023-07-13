@tool
extends EditorPlugin

const elements_dir := "res://addons/tnowe_extra_controls/elements/"

var element_scripts := [
	["UnfoldedOptionButton", preload(elements_dir + "unfolded_option_button.gd"), null],
	["PropertiesBox", preload(elements_dir + "properties_box.gd"), null],
]


func _enter_tree():
	var editor_base_node := get_editor_interface().get_base_control()
	for x in element_scripts:
		var x_icon = x[2]
		if x_icon == null:
			x_icon = x[1].get_instance_base_type()

		if x_icon is StringName || x_icon is String:
			x_icon = editor_base_node.get_theme_icon(x_icon, "EditorIcons")

		add_custom_type(x[0], x[1].get_instance_base_type(), x[1], x_icon)


func _exit_tree():
	for x in element_scripts:
		remove_custom_type(x[0])
