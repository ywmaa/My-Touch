extends HBoxContainer

var websocket_server : WebSocketServer
var websocket_port : int
var websocket_id : int = -1

var is_multipart : bool = false
var multipart_message : String = ""

var preview_viewport : Viewport = null

func _ready():
	set_process(false)

func create_server() -> void:
	if websocket_server == null:
		websocket_server = WebSocketServer.new()
		websocket_server.connect("client_connected", self, "_on_client_connected")
		websocket_server.connect("client_disconnected", self, "_on_client_disconnected")
		websocket_server.connect("data_received", self, "_on_data_received")
		websocket_port = 8000
		while true:
			if websocket_server.listen(websocket_port) == OK:
				break
			websocket_port += 1
		if websocket_server.is_listening():
			print_debug("Listening on port %d..." % websocket_port)
			set_process(true)

func create_preview_viewport():
	if preview_viewport == null:
		preview_viewport = load("res://material_maker/tools/share/preview_viewport.tscn").instance()
		add_child(preview_viewport)

func _on_ConnectButton_pressed() -> void:
	if websocket_id == -1:
		create_server()
		OS.shell_open("https://www.materialmaker.org?mm_port=%d" % websocket_port)

func update_preview_texture():
	create_preview_viewport()
	var status = mm_globals.main_window.update_preview_3d([ preview_viewport ], true)
	while status is GDScriptFunctionState:
		status = yield(status, "completed")
	preview_viewport.get_materials()[0].set_shader_param("uv1_scale", Vector3(4, 2, 4))
	preview_viewport.get_materials()[0].set_shader_param("uv1_offset", Vector3(0, 0.5, 0))
	preview_viewport.get_materials()[0].set_shader_param("depth_offset", 0.8)
	preview_viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ALWAYS
	preview_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	preview_viewport.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")

func get_preview_texture():
	return preview_viewport.get_texture()

func can_share():
	return ! $SendButton.disabled

func _on_SendButton_pressed():
	var main_window = mm_globals.main_window
	var asset_type : String
	var preview_texture : Texture
	match main_window.get_current_project().get_project_type():
		"material":
			asset_type = "material"
			create_preview_viewport()
			var status = main_window.update_preview_3d([ preview_viewport ], true)
			while status is GDScriptFunctionState:
				status = yield(status, "completed")
			preview_viewport.get_materials()[0].set_shader_param("uv1_scale", Vector3(4, 2, 4))
			preview_viewport.get_materials()[0].set_shader_param("uv1_offset", Vector3(0, 0.5, 0))
			preview_viewport.get_materials()[0].set_shader_param("depth_offset", 0.8)
			preview_viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ALWAYS
			preview_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
			preview_viewport.update_worlds()
			yield(get_tree(), "idle_frame")
			yield(get_tree(), "idle_frame")
			preview_texture = preview_viewport.get_texture()
		"paint":
			asset_type = "brush"
			var status = main_window.get_current_project().get_brush_preview()
			while status is GDScriptFunctionState:
				status = yield(status, "completed")
			preview_texture = status
		_:
			return
	send_asset(asset_type, main_window.get_current_graph_edit().top_generator.serialize(), preview_texture)

func send_asset(asset_type : String, asset_data : Dictionary, preview_texture : Texture):
	var png_image = preview_texture.get_data().save_png_to_buffer()
	var png_data = Marshalls.raw_to_base64(png_image)
	var data = { type=asset_type, image=png_data, json=JSON.print(asset_data) }
	send_data(JSON.print(data))

func _process(_delta):
	websocket_server.poll()

const PACKET_SIZE : int = 64000
func send_data(data : String):
	if (data.length() < PACKET_SIZE):
		websocket_server.get_peer(websocket_id).put_packet(data.to_utf8())
	else:
		websocket_server.get_peer(websocket_id).put_packet("%MULTIPART_BEGIN%".to_utf8())
		for s in range(0, data.length(), PACKET_SIZE):
			yield(get_tree(), "idle_frame")
			websocket_server.get_peer(websocket_id).put_packet(data.substr(s, PACKET_SIZE).to_utf8())
		yield(get_tree(), "idle_frame")
		websocket_server.get_peer(websocket_id).put_packet("%MULTIPART_END%".to_utf8())

# warning-ignore:unused_argument
func _on_client_connected(id: int, protocol: String) -> void:
	if websocket_id == -1:
		websocket_id = id
		$ConnectButton.texture_normal = preload("res://material_maker/tools/share/link.tres")
		$ConnectButton.hint_tooltip = "Connected to the web site.\nLog in to submit materials."
		$SendButton.disabled = true
		is_multipart = false
		var data = {
			type="mm_release",
			release=ProjectSettings.get_setting("application/config/actual_release"),
			features=[ "share_environments" ]
		}
		send_data(JSON.print(data))


# warning-ignore:unused_argument
func _on_client_disconnected(id: int, was_clean_close: bool) -> void:
	if websocket_id == id:
		websocket_id = -1
		$ConnectButton.texture_normal = preload("res://material_maker/tools/share/broken_link.tres")
		$ConnectButton.hint_tooltip = "Disconnected. Click to connect to the web site."
		$SendButton.disabled = true

func bring_to_top() -> void:
	var is_always_on_top = OS.is_window_always_on_top()
	OS.set_window_always_on_top(true)
	OS.set_window_always_on_top(is_always_on_top)

func _on_data_received(id: int) -> void:
	var message = websocket_server.get_peer(id).get_packet().get_string_from_utf8()
	if is_multipart:
		if message == "%MULTIPART_END%":
			is_multipart = false
			process_message(multipart_message)
		else:
			multipart_message += message
	elif message == "%MULTIPART_BEGIN%":
		is_multipart = true
		multipart_message = ""
	else:
		process_message(message)

func process_message(message : String) -> void:
	print("received message (%d)" % message.length())
	var json = JSON.parse(message)
	if json.error == OK:
		var data = json.result
		match data.action:
			"logged_in":
				$ConnectButton.texture_normal = preload("res://material_maker/tools/share/golden_link.tres")
				$ConnectButton.hint_tooltip = "Connected and logged in.\nMaterials can be submitted."
				$SendButton.disabled = false
			"load_material":
				var main_window = mm_globals.main_window
				main_window.new_material()
				var graph_edit = main_window.get_current_graph_edit()
				var new_generator = mm_loader.create_gen(JSON.parse(data.json).result)
				graph_edit.set_new_generator(new_generator)
				main_window.hierarchy.update_from_graph_edit(graph_edit)
				bring_to_top()
			"load_brush":
				var main_window = mm_globals.main_window
				var project_panel = main_window.get_current_project()
				if not project_panel.has_method("set_brush"):
					print("Cannot load brush")
					return
				project_panel.set_brush(JSON.parse(data.json).result)
				bring_to_top()
			"load_environment":
				var environment_manager = get_node("/root/MainWindow/EnvironmentManager")
				environment_manager.add_environment(JSON.parse(data.json).result)
	else:
		print("Incorrect JSON")

