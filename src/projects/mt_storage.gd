class_name MTStorage
## File helpers that work for both regular paths and Android SAF content URIs.
##
## On Android the app only touches its own app-specific storage directly.
## Anything outside of it goes through the system picker (Storage Access Framework),
## which returns "content://" URIs. Godot's FileAccess can read/write those, and for a
## folder (tree) URI it resolves "content://<tree>#sub/dir/file.png" to a file inside
## that folder, creating sub folders on write. DirAccess does not support them.

const CONTENT_PREFIX := "content://"
const GRANTED_FOLDERS_SECTION := "android_storage"
const GRANTED_FOLDERS_KEY := "granted_folders"


static func is_android() -> bool:
	return OS.get_name() == "Android"

static func is_saf(path: String) -> bool:
	return path.begins_with(CONTENT_PREFIX)

## App-specific root folder, accessible without any permission on Android.
static func app_root_dir() -> String:
	return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS, false).get_base_dir()

## Default folder for saving projects.
static func projects_dir() -> String:
	var dir : String
	if is_android():
		dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS, false)
	else:
		dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	DirAccess.make_dir_recursive_absolute(dir)
	return dir

## Default folder for exported images.
static func pictures_dir() -> String:
	var dir : String
	if is_android():
		dir = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES, false)
	else:
		dir = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	DirAccess.make_dir_recursive_absolute(dir)
	return dir

## Path of [param file_name] inside [param folder] (a local dir or a SAF tree URI).
static func join(folder: String, file_name: String) -> String:
	if is_saf(folder):
		if folder.contains("#"):
			return folder + "/" + file_name
		return folder + "#" + file_name
	return folder.path_join(file_name)

## Parent folder of [param path]. For SAF paths, returns "" when the parent is the tree root
## that can't be expressed as a path.
static func parent_dir(path: String) -> String:
	if is_saf(path):
		var hash_pos := path.find("#")
		if hash_pos == -1:
			return ""
		var slash_pos := path.rfind("/")
		if slash_pos > hash_pos:
			return path.substr(0, slash_pos)
		return path.substr(0, hash_pos)
	return path.get_base_dir()

## Human readable file name, used for titles and when copying files into a project.
static func display_name(path: String) -> String:
	if !is_saf(path):
		return path.get_file()
	var hash_pos := path.find("#")
	if hash_pos != -1:
		return path.substr(hash_pos + 1).get_file()
	# Document URIs look like content://<authority>/document/primary%3APictures%2Fcat.png
	var last := path.get_file().uri_decode()
	last = last.get_file()
	var colon := last.rfind(":")
	if colon != -1:
		last = last.substr(colon + 1)
	return last

## Path to show to the user, SAF URIs are not readable so only their file name is shown.
static func display_path(path: String) -> String:
	return display_name(path) if is_saf(path) else path

## Removes characters that are not safe in a file name / URI fragment.
static func sanitize_file_name(file_name: String) -> String:
	var result := file_name.validate_filename()
	for c in ["#", "%", "?"]:
		result = result.replace(c, "_")
	return result

static func file_exists(path: String) -> bool:
	return FileAccess.file_exists(path)

static func dir_exists(path: String) -> bool:
	if is_saf(path):
		return false # Can't be listed, callers fall back to known file names.
	return DirAccess.dir_exists_absolute(path)

static func make_dir(path: String) -> void:
	if is_saf(path):
		return # Created automatically when a file is written inside it.
	DirAccess.make_dir_recursive_absolute(path)

## Copies a file using FileAccess, so it works with SAF URIs on both ends.
static func copy_file(from: String, to: String) -> bool:
	if from == to:
		return true
	var data := FileAccess.get_file_as_bytes(from)
	if data.is_empty() and FileAccess.get_open_error() != OK:
		push_error("Could not read " + from)
		return false
	var output := FileAccess.open(to, FileAccess.WRITE)
	if output == null:
		push_error("Could not write " + to)
		return false
	output.store_buffer(data)
	output.close()
	return true

## Returns a file name with a proper image extension for [param path].
## Picked photos often come as URIs without an extension (content://.../image%3A1234),
## so the format is detected from the file header.
static func image_file_name(path: String) -> String:
	var file_name := sanitize_file_name(display_name(path))
	if file_name.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp", "svg", "tga", "bmp"]:
		return file_name
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return file_name
	var header := file.get_buffer(12)
	file.close()
	var ext := "png"
	if header.size() >= 3 and header[0] == 0xFF and header[1] == 0xD8 and header[2] == 0xFF:
		ext = "jpg"
	elif header.size() >= 12 and header.slice(0, 4).get_string_from_ascii() == "RIFF" and header.slice(8, 12).get_string_from_ascii() == "WEBP":
		ext = "webp"
	elif header.size() >= 2 and header[0] == 0x42 and header[1] == 0x4D:
		ext = "bmp"
	return file_name + "." + ext

static func _saf_cache_path(path: String) -> String:
	DirAccess.make_dir_recursive_absolute("user://saf_cache")
	return "user://saf_cache/%d.%s" % [path.hash(), path.get_extension()]

## Saves a resource, going through a local temp file for SAF paths.
static func save_resource(resource: Resource, path: String) -> Error:
	if !is_saf(path):
		return ResourceSaver.save(resource, path)
	var temp := _saf_cache_path(path)
	var error := ResourceSaver.save(resource, temp)
	if error != OK:
		return error
	var copied := copy_file(temp, path)
	DirAccess.remove_absolute(temp)
	return OK if copied else ERR_FILE_CANT_WRITE

static func resource_exists(path: String) -> bool:
	if is_saf(path):
		return FileAccess.file_exists(path)
	return ResourceLoader.exists(path)

## Loads a resource, going through a local temp file for SAF paths.
static func load_resource(path: String, cache_mode: ResourceLoader.CacheMode = ResourceLoader.CACHE_MODE_REUSE) -> Resource:
	if !is_saf(path):
		return ResourceLoader.load(path, "", cache_mode)
	var temp := _saf_cache_path(path)
	if !copy_file(path, temp):
		return null
	var resource := ResourceLoader.load(temp, "", ResourceLoader.CACHE_MODE_IGNORE)
	DirAccess.remove_absolute(temp)
	return resource


# -----------------------------------------------------------------------
#                    Android system picker (SAF)
# -----------------------------------------------------------------------

class _PickerWaiter extends RefCounted:
	signal done(paths: PackedStringArray)
	func on_result(status: bool, paths: PackedStringArray, _filter_index: int = 0) -> void:
		done.emit(paths if status else PackedStringArray())

static func _show_picker(title: String, mode: DisplayServer.FileDialogMode, filters: PackedStringArray, current_dir: String = "") -> PackedStringArray:
	var waiter := _PickerWaiter.new()
	var error := DisplayServer.file_dialog_show(title, current_dir, "", false, mode, filters, waiter.on_result)
	if error != OK:
		return PackedStringArray()
	return await waiter.done

## Lets the user pick files anywhere through the system picker.
## Only the picked files are shared with the app.
static func pick_files(filters: PackedStringArray, multiple: bool = true) -> PackedStringArray:
	var mode := DisplayServer.FILE_DIALOG_MODE_OPEN_FILES if multiple else DisplayServer.FILE_DIALOG_MODE_OPEN_FILE
	return await _show_picker("Open", mode, filters)

## Asks the user for access to one folder. Returns its tree URI, or "" if canceled.
## The access is persisted, so the folder stays usable after restarting the app.
static func pick_folder(current_dir: String = "") -> String:
	var paths := await _show_picker("Select Folder", DisplayServer.FILE_DIALOG_MODE_OPEN_DIR, PackedStringArray(), current_dir)
	if paths.is_empty():
		return ""
	var tree := paths[0]
	persist_folder_access(tree)
	return tree

static func persist_folder_access(tree: String) -> void:
	if Engine.has_singleton("AndroidRuntime"):
		Engine.get_singleton("AndroidRuntime").updatePersistableUriPermission(tree, true)
	var folders : Array = get_granted_folders()
	if !folders.has(tree):
		folders.append(tree)
		_config().set_value(GRANTED_FOLDERS_SECTION, GRANTED_FOLDERS_KEY, folders)

static func get_granted_folders() -> Array:
	return _config().get_value(GRANTED_FOLDERS_SECTION, GRANTED_FOLDERS_KEY, [])

## Splits "content://<authority>/tree/<id>" or ".../document/<id>" into [authority, id].
static func _uri_authority_and_id(uri: String, kind: String) -> PackedStringArray:
	var rest := uri.trim_prefix(CONTENT_PREFIX).get_slice("#", 0)
	var authority := rest.get_slice("/", 0)
	var marker := "/" + kind + "/"
	var pos := rest.rfind(marker)
	if pos == -1:
		return PackedStringArray()
	return PackedStringArray([authority, rest.substr(pos + marker.length()).uri_decode()])

## Maps a single picked document to a path inside a granted folder, so files next to it
## (like a project's data folder) are reachable too. Returns "" if no granted folder contains it.
static func document_to_tree_path(document: String) -> String:
	var doc := _uri_authority_and_id(document, "document")
	if doc.is_empty():
		return ""
	for tree in get_granted_folders():
		var tree_parts := _uri_authority_and_id(tree, "tree")
		if tree_parts.is_empty() or tree_parts[0] != doc[0]:
			continue
		if doc[1].begins_with(tree_parts[1] + "/"):
			return tree + "#" + doc[1].substr(tree_parts[1].length() + 1)
	return ""

## Local path hint for the folder containing [param document], used as the picker's start folder.
static func document_parent_hint(document: String) -> String:
	var doc := _uri_authority_and_id(document, "document")
	if doc.is_empty() or !doc[1].begins_with("primary:"):
		return ""
	return "/storage/emulated/0/" + doc[1].trim_prefix("primary:").get_base_dir()

## Opens a project picked with the system picker. Projects need their data folder, so if the
## project is not inside a granted folder the user is asked for access to its folder.
static func pick_project_files(multiple: bool = true) -> PackedStringArray:
	var result := PackedStringArray()
	var documents := await pick_files(PackedStringArray(), multiple)
	for document in documents:
		var path := document_to_tree_path(document)
		if path == "":
			await _show_message("Grant Folder Access", "Select the folder that contains \"%s\" so its project data can be loaded." % display_name(document))
			await pick_folder(document_parent_hint(document))
			path = document_to_tree_path(document)
		if path == "":
			await _show_message("Load failed!", "The selected folder does not contain \"%s\"." % display_name(document))
			continue
		result.append(path)
	return result

static func _show_message(title: String, text: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = text
	dialog.dialog_autowrap = true
	dialog.min_size = Vector2i(400, 150)
	_globals().main_window.add_child(dialog)
	dialog.popup_centered()
	await dialog.visibility_changed
	dialog.queue_free()

# Autoloads aren't known at compile time of global classes in every context, look it up instead.
static func _globals() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("/root/mt_globals")

static func _config() -> ConfigFile:
	return _globals().config
