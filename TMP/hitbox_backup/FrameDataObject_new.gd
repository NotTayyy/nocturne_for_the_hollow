@tool
extends CollisionShape2D
class_name FrameDataObject

## Which hit of the move this shape belongs to
@export var hit_index    : int = 0

## Active window override within the hit index slot
## -1 = active the entire hit index window
@export var active_start : int = -1
@export var active_end   : int = -1

## Box type — sets collision layer/mask automatically
enum BoxType { Hitbox, Hurtbox }
@export var box_type : BoxType = BoxType.Hitbox :
	set(value):
		box_type = value
		_apply_collision_layers()
		_update_debug_color()

func _ready() -> void:
	_apply_collision_layers()
	_update_debug_color()

func _get_tool_buttons() -> Array:
	return [
		{ "displayName": "Add Box To This Index", "call": "AddBoxToIndex"    },
		{ "displayName": "Remove This Box",       "call": "RemoveThisBox"    },
		{ "displayName": "Insert Frame Before",   "call": "InsertBefore"     },
		{ "displayName": "Insert Frame After",    "call": "InsertAfter"      },
	]

func AddBoxToIndex() -> void:
	var hfd : HitboxFrameData = get_parent() as HitboxFrameData
	if hfd == null:
		push_error("[FrameDataObject] Parent is not HitboxFrameData")
		return
	var new_box : FrameDataObject = hfd._make_frame_object_with_index(hit_index, box_type)
	var box_count : int = _count_siblings_at_index(hit_index) + 1
	new_box.name = "Hitbox_%d_index_%d" % [box_count, hit_index]
	hfd.add_child(new_box)
	new_box.owner = get_tree().edited_scene_root
	hfd._refresh_index_viewer()

func RemoveThisBox() -> void:
	var hfd : HitboxFrameData = get_parent() as HitboxFrameData
	queue_free()
	if hfd != null:
		hfd._refresh_index_viewer()

func InsertBefore() -> void:
	var hfd : HitboxFrameData = get_parent() as HitboxFrameData
	if hfd == null:
		return
	var new_index : int = maxi(hit_index - 1, 0)
	var new_box   : FrameDataObject = hfd._make_frame_object_with_index(new_index, box_type)
	var box_count : int = _count_siblings_at_index(new_index) + 1
	new_box.name = "Hitbox_%d_index_%d" % [box_count, new_index]
	hfd.add_child(new_box)
	hfd.move_child(new_box, get_index())
	new_box.owner = get_tree().edited_scene_root
	hfd._refresh_index_viewer()

func InsertAfter() -> void:
	var hfd : HitboxFrameData = get_parent() as HitboxFrameData
	if hfd == null:
		return
	var new_index : int = hit_index + 1
	var new_box   : FrameDataObject = hfd._make_frame_object_with_index(new_index, box_type)
	var box_count : int = _count_siblings_at_index(new_index) + 1
	new_box.name = "Hitbox_%d_index_%d" % [box_count, new_index]
	hfd.add_child(new_box)
	hfd.move_child(new_box, get_index() + 1)
	new_box.owner = get_tree().edited_scene_root
	hfd._refresh_index_viewer()

func _apply_collision_layers() -> void:
	match box_type:
		BoxType.Hitbox:
			collision_layer = 16
			collision_mask  = 1
		BoxType.Hurtbox:
			collision_layer = 1
			collision_mask  = 16

func _update_debug_color() -> void:
	match box_type:
		BoxType.Hitbox:  debug_color = Color(1.0, 0.2, 0.2, 0.35)
		BoxType.Hurtbox: debug_color = Color(0.0, 0.531, 0.852, 0.349)

func _count_siblings_at_index(index: int) -> int:
	var count  : int  = 0
	var parent : Node = get_parent()
	if parent == null:
		return 0
	for child in parent.get_children():
		if child is FrameDataObject and (child as FrameDataObject).hit_index == index:
			count += 1
	return count
