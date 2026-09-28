extends PopupPanel

var config : ConfigFile

signal config_changed()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()

func edit_preferences(c : ConfigFile) -> void:
	config = c
	update_controls($VBoxContainer/TabContainer/General)
	popup_centered()

func update_controls(p : Node) -> void:
	for c in p.get_children():
		if c.has_method("init_from_config"):
			c.init_from_config(config)
			_connect_option(c)
		update_controls(c)

## Every option applies and saves as soon as it changes, no Apply/OK needed.
func _connect_option(option : Node) -> void:
	var callback := _on_option_changed.bind(option).unbind(1)
	if option is BaseButton and option.toggle_mode and !option.toggled.is_connected(callback):
		option.toggled.connect(callback)
	elif option is OptionButton and !option.item_selected.is_connected(callback):
		option.item_selected.connect(callback)
	elif option is Range and !option.value_changed.is_connected(callback):
		option.value_changed.connect(callback)

# Options waiting to be applied (number sliders apply once released)
var _pending_options : Array[Node] = []

func _on_option_changed(option : Node) -> void:
	if !_pending_options.has(option):
		_pending_options.append(option)
	set_process(true)

func _process(_delta : float) -> void:
	if _pending_options.is_empty():
		set_process(false)
		return
	for option in _pending_options:
		if "sliding" in option and option.sliding:
			return # Rescaling the UI under the finger while dragging would make the value jump
	for option in _pending_options:
		option.update_config(config)
	_pending_options.clear()
	set_process(false)
	emit_signal("config_changed")
	mt_globals.save_config()

func update_config(p : Node) -> void:
	for c in p.get_children():
		if c.has_method("update_config"):
			c.update_config(config)
		update_config(c)


func _on_Preferences_about_to_show():
	await get_tree().process_frame
	_on_VBoxContainer_minimum_size_changed()

func _on_VBoxContainer_minimum_size_changed():
	size = $VBoxContainer.get_rect().size+Vector2(4, 4)
	


func _on_InstallLanguage_pressed():
	var dialog = load("res://UI/windows/file_dialog/file_dialog.tscn").instance()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter("*.po,*.translation,*.csv;Translation file")
	var files = await dialog.select_files()
	if files.size() > 0:
		var locale = load("res://locale/locale.gd").new()
		locale.install_translation(files[0])
		update_language_list()

func update_language_list():
	$VBoxContainer/TabContainer/General/HBoxContainer/Language.init_from_locales()
	$VBoxContainer/TabContainer/General/HBoxContainer/Language.init_from_config(config)

func _on_DownloadLanguage_pressed():
	var download_popup = load("res://UI/windows/preferences/language_download.tscn").instance()
	mt_globals.main_window.add_child(download_popup)
	download_popup.connect("tree_exited", self, "_on_DownloadLanguage_closed")

func _on_DownloadLanguage_closed():
	var locale = load("res://locale/locale.gd").new()
	locale.read_translations()
	update_language_list()
