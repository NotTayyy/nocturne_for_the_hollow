@tool
extends CollisionShape2D
class_name HurtboxDataObject

## Which frame this hurtbox becomes active (-1 = always active)
@export var start_frame : int = -1
## Which frame this hurtbox deactivates inclusive (-1 = always active)
@export var end_frame   : int = -1

func _ready() -> void:
	debug_color = Color(0.0, 0.531, 0.852, 0.35)

func _get_tool_buttons() -> Array:
	return [
		{ displayName = "Add Hurtbox",         call = "AddHurtbox"    },
		{ displayName = "Remove This Box",      call = "RemoveThisBox" },
		{ displayName = "Insert Frame Before",  call = "InsertBefore"  },
		{ displayName = "Insert Frame After",   call = "InsertAfter"   },
	]

func AddHurtbox() -> void:
	var hfd : HitboxFrameData = get_parent() as HitboxFrameData
	if hfd == null:
		push_error("[HurtDO] Parent is not HitboxFrameData")
		return
	var new_box   : HurtboxDataObject = hfd._make_hurtdo()
	var box_count : int               = _count_hurtdo_siblings() + 1
	new_box.name = "HurtDO_%d" % box_count
	hfd.add_child(new_box)
	new_box.owner = get_tree().edited_scene_root

func RemoveThisBox() -> void:
	queue_free()

func InsertBefore() -> void:
	var hfd : HitboxFrameData = get_parent() as HitboxFrameData
	if hfd == null:
		return
	var new_box   : HurtboxDataObject = hfd._make_hurtdo()
	var box_count : int               = _count_hurtdo_siblings() + 1
	new_box.name = "HurtDO_%d" % box_count
	hfd.add_child(new_box)
	hfd.move_child(new_box, get_index())
	new_box.owner = get_tree().edited_scene_root

func InsertAfter() -> void:
	var hfd : HitboxFrameData = get_parent() as HitboxFrameData
	if hfd == null:
		return
	var new_box   : HurtboxDataObject = hfd._make_hurtdo()
	var box_count : int               = _count_hurtdo_siblings() + 1
	new_box.name = "HurtDO_%d" % box_count
	hfd.add_child(new_box)
	hfd.move_child(new_box, get_index() + 1)
	new_box.owner = get_tree().edited_scene_root

func _count_hurtdo_siblings() -> int:
	var count  : int  = 0
	var parent : Node = get_parent()
	if parent == null:
		return 0
	for child in parent.get_children():
		if child is HurtboxDataObject:
			count += 1
	return count
