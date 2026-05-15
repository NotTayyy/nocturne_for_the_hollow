@tool
extends CollisionShape2D
class_name HitboxDataObject

## Which frame this hitbox becomes active (-1 = whole index duration)
@export var start_frame : int = -1
## Which frame this hitbox deactivates inclusive (-1 = whole index duration)
@export var end_frame   : int = -1
## Which hit of the move this shape belongs to
@export var hit_index   : int = 0

func _ready() -> void:
	debug_color = Color(1.0, 0.2, 0.2, 0.35)

func _get_tool_buttons() -> Array:
	return [
		{ displayName = "Add Box To This Index", call = "AddBoxToIndex" },
		{ displayName = "Remove This Box",       call = "RemoveThisBox" },
		{ displayName = "Insert Frame Before",   call = "InsertBefore"  },
		{ displayName = "Insert Frame After",    call = "InsertAfter"   },
	]

func AddBoxToIndex() -> void:
	var hfd : HitboxFrameData = get_parent() as HitboxFrameData
	if hfd == null:
		push_error("[HitDO] Parent is not HitboxFrameData")
		return
	var new_box   : HitboxDataObject = hfd._make_hitdo(hit_index)
	var box_count : int              = _count_siblings_at_index(hit_index) + 1
	new_box.name = "HitDO_%d_index_%d" % [box_count, hit_index]
	hfd.add_child(new_box)
	new_box.owner = get_tree().edited_scene_root

func RemoveThisBox() -> void:
	var hfd : HitboxFrameData = get_parent() as HitboxFrameData
	queue_free()

func InsertBefore() -> void:
	var hfd : HitboxFrameData = get_parent() as HitboxFrameData
	if hfd == null:
		return
	var new_index : int              = maxi(hit_index - 1, 0)
	var new_box   : HitboxDataObject = hfd._make_hitdo(new_index)
	var box_count : int              = _count_siblings_at_index(new_index) + 1
	new_box.name = "HitDO_%d_index_%d" % [box_count, new_index]
	hfd.add_child(new_box)
	hfd.move_child(new_box, get_index())
	new_box.owner = get_tree().edited_scene_root

func InsertAfter() -> void:
	var hfd : HitboxFrameData = get_parent() as HitboxFrameData
	if hfd == null:
		return
	var new_index : int              = hit_index + 1
	var new_box   : HitboxDataObject = hfd._make_hitdo(new_index)
	var box_count : int              = _count_siblings_at_index(new_index) + 1
	new_box.name = "HitDO_%d_index_%d" % [box_count, new_index]
	hfd.add_child(new_box)
	hfd.move_child(new_box, get_index() + 1)
	new_box.owner = get_tree().edited_scene_root

func _count_siblings_at_index(index : int) -> int:
	var count  : int  = 0
	var parent : Node = get_parent()
	if parent == null:
		return 0
	for child in parent.get_children():
		if child is HitboxDataObject and (child as HitboxDataObject).hit_index == index:
			count += 1
	return count
