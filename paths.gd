@tool
class_name MTPaths

static func get_resource_dir() -> String:
	return OS.get_executable_path().get_base_dir()

