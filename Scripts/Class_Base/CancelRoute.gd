@tool
extends Resource
class_name CancelRoute

@export var library : CancelRouteLibrary = null : set = _on_library_set

func _on_library_set(v: CancelRouteLibrary) -> void:
	library = v
	notify_property_list_changed()

@export var is_state : bool = false : set = _on_is_state_set

func _on_is_state_set(v: bool) -> void:
	is_state = v
	notify_property_list_changed()

var command : String = ""
var path    : String = ""

func _get_property_list() -> Array:
	var props : Array = []

	# Command dropdown
	if library != null and not library.commands.is_empty():
		props.append({
			"name":        "command",
			"type":        TYPE_STRING,
			"usage":       PROPERTY_USAGE_DEFAULT,
			"hint":        PROPERTY_HINT_ENUM,
			"hint_string": ",".join(library.commands),
		})
	else:
		props.append({
			"name":        "command",
			"type":        TYPE_STRING,
			"usage":       PROPERTY_USAGE_DEFAULT,
			"hint":        PROPERTY_HINT_NONE,
			"hint_string": "",
		})

	# Path dropdown — from library.hfd_paths keys
	if library != null and not library.hfd_paths.is_empty() and not is_state:
		props.append({
			"name":        "path",
			"type":        TYPE_STRING,
			"usage":       PROPERTY_USAGE_DEFAULT,
			"hint":        PROPERTY_HINT_ENUM,
			"hint_string": ",".join(library.hfd_paths.keys()),
		})
	else:
		props.append({
			"name":        "path",
			"type":        TYPE_STRING,
			"usage":       PROPERTY_USAGE_DEFAULT,
			"hint":        PROPERTY_HINT_NONE,
			"hint_string": "",
		})

	return props

func _get(property: StringName):
	match property:
		"command": return command
		"path":    return path
	return null

func _set(property: StringName, value) -> bool:
	match property:
		"command":
			command = value
			return true
		"path":
			path = value
			return true
	return false

# -----------------------------------------------------------------------------
# Runtime resolution
# -----------------------------------------------------------------------------

func resolve_hfd_path() -> String:
	if library == null or is_state: return ""
	return library.hfd_paths.get(path, "")

func resolve_state_id() -> String:
	return path if is_state else ""
