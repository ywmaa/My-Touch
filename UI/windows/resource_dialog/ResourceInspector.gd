extends InspectorBase
class_name ResourceInspector

var current_resource : base_resource:
	set(v):
		current_resource = v
		current_object = current_resource
		current_object_changed.emit()
