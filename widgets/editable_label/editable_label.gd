extends HBoxContainer
class_name editable_label
signal label_changed(new_label)

func _ready():
	$Label.connect("gui_input",_on_gui_input)
	$Editor.connect("focus_exited",_on_Editor_focus_exited)
	$Editor.connect("text_submitted",_on_Editor_text_entered)

func get_text() -> String:
	return $Label.text

func set_text(t) -> void:
	$Label.text = t

func _on_gui_input(ev) -> void:
	print("input")
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		$Label.visible = false
		$Editor.text = $Label.text
		$Editor.visible = true
		$Editor.select()
		$Editor.grab_focus()

func _on_Editor_text_entered(__) -> void:
	_on_Editor_focus_exited()

func _on_Editor_focus_exited() -> void:
	$Label.text = $Editor.text
	$Label.visible = true
	$Editor.visible = false
	emit_signal("label_changed", $Editor.text)
