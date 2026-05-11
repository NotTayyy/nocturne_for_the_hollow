@tool
extends Area2D
class_name HitboxFrameData

## The MoveData resource this frame data belongs to
@export var move_data : MoveData

## How many hitbox shapes to add per index when clicking Add Frame
@export var hitboxes_to_add : int = 1

## Default box type for newly added shapes
@export var default_box_type : FrameDataObject.BoxType = FrameDataObject.BoxType.Hitbox

## Read-only index viewer — shows all hit indices and box counts
@export var index_viewer : Array[String] = []

var _current_frame : int      = 0
var _active        : bool     = false
var _move_data_rt  : MoveData = null
var _hit_log       : Dictionary = {}

func _get_tool_buttons() -> Array:
	return [
		{ "displayName": "Add Frame",             "call": "AddFrame"       },
		{ "displayName": "Clear All",             "call": "ClearFrameData" },
		{ "displayName": "Bake to MoveData",      "call": "Bake"           },
		{ "displayName": "Restore from MoveData", "call": "Restore"        },
	]

# =============================================================================
# Runtime API
# =============================================================================

func begin(p_move_data : MoveData) -> void:
	_move_data_rt  = p_move_data
	_current_frame = 0
	_active        = true
	_hit_log.clear()
	_set_all_monitoring(false)

func tick() -> void:
	if not _active or _move_data_rt == null:
		return
	_current_frame += 1
	_update_active_boxes()

func stop() -> void:
	_active = false
	_set_all_monitoring(false)
	_hit_log.clear()

func already_hit(hit_index : int, hurtbox_id : int) -> bool:
	if not _hit_log.has(hit_index):
		return false
	return hurtbox_id in _hit_log[hit_index]

func register_hit(hit_index : int, hurtbox_id : int) -> void:
	if not _hit_log.has(hit_index):
		_hit_log[hit_index] = []
	_hit_log[hit_index].append(hurtbox_id)

# =============================================================================
# Frame update
# =============================================================================

func _update_active_boxes() -> void:
	if _move_data_rt == null:
		return

	var startup      : int = _move_data_rt.startup
	var frame        : int = _current_frame
	var active_frame : int = frame - startup
	var current_index : int = -1
	var index_frame   : int = 0
	var cursor        : int = 0

	if frame <= startup:
		_set_all_monitoring(false)
		return

	for i : int in _move_data_rt.active.size():
		var window_size : int = _move_data_rt.active[i]
		if active_frame <= cursor + window_size:
			current_index = i
			index_frame   = active_frame - cursor
			break
		cursor += window_size
		if i < _move_data_rt.gaps.size():
			cursor += _move_data_rt.gaps[i]

	if current_index == -1:
		_set_all_monitoring(false)
		return

	for child in get_children():
		if not child is FrameDataObject:
			continue
		var obj              : FrameDataObject = child
		var should_be_active : bool            = false
		if obj.hit_index == current_index:
			if obj.active_start == -1 and obj.active_end == -1:
				should_be_active = true
			elif obj.active_start != -1 and obj.active_end != -1:
				should_be_active = index_frame >= obj.active_start and index_frame <= obj.active_end
			elif obj.active_start != -1:
				should_be_active = index_frame >= obj.active_start
			elif obj.active_end != -1:
				should_be_active = index_frame <= obj.active_end
		obj.set_deferred("disabled", not should_be_active)

func _set_all_monitoring(enabled : bool) -> void:
	for child in get_children():
		if child is FrameDataObject:
			(child as FrameDataObject).set_deferred("disabled", not enabled)

# =============================================================================
# Editor
# =============================================================================

func AddFrame() -> void:
	var next_index : int = _get_next_hit_index()
	for i : int in hitboxes_to_add:
		var obj     : FrameDataObject = _make_frame_object_with_index(next_index, default_box_type)
		var box_num : int             = i + 1
		obj.name = "Hitbox_%d_index_%d" % [box_num, next_index]
		add_child(obj)
		obj.owner = get_tree().edited_scene_root
	_refresh_index_viewer()
	print("[HFD] Added %d box(es) at index %d" % [hitboxes_to_add, next_index])

func ClearFrameData() -> void:
	for child in get_children():
		if child is FrameDataObject:
			child.free()
	_refresh_index_viewer()
	print("[HFD] Cleared all frame data objects")

func Bake() -> void:
	if move_data == null:
		push_error("[HFD] No MoveData assigned — cannot bake")
		return

	var baked : Array[Dictionary] = []

	for child in get_children():
		if not child is FrameDataObject:
			continue
		var obj   : FrameDataObject = child
		var shape : Shape2D         = obj.shape
		if shape == null:
			push_warning("[HFD] Box '%s' has no shape — skipping" % obj.name)
			continue

		var size     : Vector2 = Vector2.ZERO
		var position : Vector2 = obj.position

		if shape is RectangleShape2D:
			size = (shape as RectangleShape2D).size
		elif shape is CircleShape2D:
			var radius : float = (shape as CircleShape2D).radius
			size = Vector2(radius * 2.0, radius * 2.0)

		baked.append({
			"name":         obj.name,
			"hit_index":    obj.hit_index,
			"active_start": obj.active_start,
			"active_end":   obj.active_end,
			"box_type":     obj.box_type,
			"position":     { "x": position.x, "y": position.y },
			"size":         { "x": size.x,     "y": size.y     },
		})

	move_data.hitbox_data = baked
	ClearFrameData()

	if move_data.resource_path != "":
		ResourceSaver.save(move_data)

	print("[HFD] Baked %d boxes to %s" % [baked.size(), move_data.resource_path])

func Restore() -> void:
	if move_data == null:
		push_error("[HFD] No MoveData assigned — cannot restore")
		return
	if move_data.hitbox_data.is_empty():
		push_warning("[HFD] No hitbox data found in MoveData")
		return

	ClearFrameData()

	for entry : Dictionary in move_data.hitbox_data:
		var obj          : FrameDataObject  = preload("res://Scripts/Components/FrameDataObject.gd").new()
		obj.name         = entry.get("name",         "Box_%d" % get_child_count())
		obj.hit_index    = entry.get("hit_index",    0)
		obj.active_start = entry.get("active_start", -1)
		obj.active_end   = entry.get("active_end",   -1)
		obj.box_type     = entry.get("box_type",     FrameDataObject.BoxType.Hitbox)

		var pos  : Dictionary       = entry.get("position", { "x": 0.0,  "y": 0.0  })
		var sz   : Dictionary       = entry.get("size",     { "x": 50.0, "y": 50.0 })
		obj.position                = Vector2(pos["x"], pos["y"])

		var rect : RectangleShape2D = RectangleShape2D.new()
		rect.size                   = Vector2(sz["x"], sz["y"])
		obj.shape                   = rect

		add_child(obj)
		obj.owner = get_tree().edited_scene_root

	_refresh_index_viewer()
	print("[HFD] Restored %d boxes from MoveData" % move_data.hitbox_data.size())

# =============================================================================
# Helpers
# =============================================================================

func _get_next_hit_index() -> int:
	var children : Array = get_children()
	if children.is_empty():
		return 0
	var max_index : int = 0
	for child in children:
		if child is FrameDataObject:
			var idx : int = (child as FrameDataObject).hit_index
			if idx > max_index:
				max_index = idx
	return max_index + 1

func _make_frame_object_with_index(hit_index : int, box_type : FrameDataObject.BoxType) -> FrameDataObject:
	var obj          : FrameDataObject  = preload("res://Scripts/Components/FrameDataObject.gd").new()
	obj.hit_index    = hit_index
	obj.active_start = -1
	obj.active_end   = -1
	obj.box_type     = box_type

	var rect         : RectangleShape2D = RectangleShape2D.new()
	rect.size        = Vector2(50.0, 50.0)
	obj.shape        = rect

	return obj

func _refresh_index_viewer() -> void:
	var index_map   : Dictionary = {}
	var sorted_keys : Array      = []

	for child in get_children():
		if not child is FrameDataObject:
			continue
		var idx : int = (child as FrameDataObject).hit_index
		if not index_map.has(idx):
			index_map[idx] = 0
		index_map[idx] += 1

	index_viewer.clear()
	sorted_keys = index_map.keys()
	sorted_keys.sort()
	for key in sorted_keys:
		index_viewer.append("Index %d: %d box(es)" % [key, index_map[key]])
	notify_property_list_changed()
