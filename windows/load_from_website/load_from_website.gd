extends WindowDialog

var assets : Array = []
var displayed_assets : Array = []
var thumbnail_update_thread : Thread

onready var item_list : ItemList = $VBoxContainer/ItemList

signal return_asset(json)

func _ready() -> void:
	Directory.new().make_dir_recursive("user://website_cache")

func _exit_tree():
	print("Waiting for thread to finish")
	thumbnail_update_thread.wait_to_finish()
	print("Finished")

func _on_ItemList_item_activated(index) -> void:
	var error = $HTTPRequest.request("https://www.materialmaker.org/api/getMaterial?id="+str(displayed_assets[index]))
	if error != OK:
		return
	var data = yield($HTTPRequest, "request_completed")[3].get_string_from_utf8()
	var parse_result : JSONParseResult = JSON.parse(data)
	if parse_result == null or ! parse_result.result is Dictionary:
		return
	emit_signal("return_asset", parse_result.result.json)

func _on_LoadFromWebsite_popup_hide() -> void:
	emit_signal("return_asset", "")

func _on_OK_pressed() -> void:
	if item_list.get_selected_items().empty():
		emit_signal("return_asset", "")
		return
	_on_ItemList_item_activated(item_list.get_selected_items()[0])

func _on_Cancel_pressed() -> void:
	emit_signal("return_asset", "")

func fill_list(filter : String):
	item_list.clear()
	displayed_assets = []
	var item_index : int = 0
	for i in range(assets.size()):
		var m = assets[i]
		if filter == "" or m.name.to_lower().find(filter.to_lower()) != -1 or m.tags.to_lower().find(filter.to_lower()) != -1:
			item_list.add_item(m.name)
			item_list.set_item_icon(item_index, m.texture)
			displayed_assets.push_back(m.id)
			item_index += 1

func select_material(type : int = 0) -> String:
	var error = $HTTPRequest.request("https://www.materialmaker.org/api/getMaterials")
	if error != OK:
		queue_free()
		return ""
	popup_centered()
	var data = yield($HTTPRequest, "request_completed")[3].get_string_from_utf8()
	var parse_result : JSONParseResult = JSON.parse(data)
	if parse_result == null or ! parse_result.result is Array:
		queue_free()
		return ""
	var tmp_assets = parse_result.result
	tmp_assets.invert()
	assets = []
	var image : Image = Image.new()
	image.create(256, 256, false, Image.FORMAT_RGBA8)
	for i in range(tmp_assets.size()):
		var m = tmp_assets[i]
		if m.type == type:
			m.texture = ImageTexture.new()
			m.texture.create_from_image(image)
			assets.push_back(m)
	fill_list("")
	thumbnail_update_thread = Thread.new()
	thumbnail_update_thread.start(self, "update_thumbnails", null, 0)
	var result = yield(self, "return_asset")
	queue_free()
	return result

func update_thumbnails() -> void:
	for i in range(assets.size()):
		var m = assets[i]
		var cache_filename : String = "user://website_cache/thumbnail_%d.png" % m.id
		var image : Image = Image.new()
		if image.load(cache_filename) != OK:
			var error = $ImageHTTPRequest.request("https://www.materialmaker.org/data/materials/material_"+str(m.id)+".webp")
			if error == OK:
				var data : PoolByteArray = yield($ImageHTTPRequest, "request_completed")[3]
				image.load_webp_from_buffer(data)
				image.save_png(cache_filename)
			else:
				continue
		m.texture.create_from_image(image)

func _on_ItemList_item_selected(_index):
	$VBoxContainer/Buttons/OK.disabled = false

func _on_ItemList_nothing_selected():
	$VBoxContainer/Buttons/OK.disabled = true

func _on_VBoxContainer_minimum_size_changed():
	rect_size = $VBoxContainer.rect_size+Vector2(4, 4)


func _on_Filter_changed(new_text):
	fill_list(new_text)
