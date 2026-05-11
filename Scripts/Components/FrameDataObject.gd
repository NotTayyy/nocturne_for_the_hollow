@tool
extends CollisionShape2D
class_name FrameDataObject

## Which frame this hitbox becomes active
@export var start_frame : int = 0
## Which frame this hitbox deactivates (inclusive)
@export var end_frame   : int = 0
## Which hit of the move this shape belongs to (for multi-hit P2 lookup)
@export var hit_index   : int = 0

## Box type — used for debug color and passed to HitboxFrameData for layer setup
enum BoxType { Hitbox, Hurtbox }
@export var box_type : BoxType = BoxType.Hitbox :
	set(value):
		box_type = value
		_update_debug_color()

func _ready() -> void:
	_update_debug_color()

func _get_tool_buttons() -> Array:
	return [
		{ displayName = "Add Box To This Index", call = "AddBoxToIndex" },
		{ displayName = "Remove This Box",       call = "RemoveThisBox" },
		{ displayName = "Insert Frame Before",   call = "InsertBefore"  },
		{ displayName = "Insert Frame After",    call = "InsertAfter"   },
	]

# =============================================================================
# Buttons
# =============================================================================

func AddBoxToIndex() -> void:
	var hfd : HitboxFrameData = get_parent() as HitboxFrameData
	if hfd == null:
		push_error("[FrameDataObject] Parent is not HitboxFrameData")
		return
	var new_box   : FrameDataObject = hfd._make_frame_object_with_index(hit_index, box_type)
	var box_count : int             = _count_siblings_at_index(hit_index) + 1
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
	var new_index : int             = maxi(hit_index - 1, 0)
	var new_box   : FrameDataObject = hfd._make_frame_object_with_index(new_index, box_type)
	var box_count : int             = _count_siblings_at_index(new_index) + 1
	new_box.name = "Hitbox_%d_index_%d" % [box_count, new_index]
	hfd.add_child(new_box)
	hfd.move_child(new_box, get_index())
	new_box.owner = get_tree().edited_scene_root
	hfd._refresh_index_viewer()

func InsertAfter() -> void:
	var hfd : HitboxFrameData = get_parent() as HitboxFrameData
	if hfd == null:
		return
	var new_index : int             = hit_index + 1
	var new_box   : FrameDataObject = hfd._make_frame_object_with_index(new_index, box_type)
	var box_count : int             = _count_siblings_at_index(new_index) + 1
	new_box.name = "Hitbox_%d_index_%d" % [box_count, new_index]
	hfd.add_child(new_box)
	hfd.move_child(new_box, get_index() + 1)
	new_box.owner = get_tree().edited_scene_root
	hfd._refresh_index_viewer()

# =============================================================================
# Helpers
# =============================================================================

func _update_debug_color() -> void:
	match box_type:
		BoxType.Hitbox:  debug_color = Color(1.0, 0.2, 0.2, 0.35)
		BoxType.Hurtbox: debug_color = Color(0.0, 0.531, 0.852, 0.349)

func _count_siblings_at_index(index : int) -> int:
	var count  : int  = 0
	var parent : Node = get_parent()
	if parent == null:
		return 0
	for child in parent.get_children():
		if child is FrameDataObject and (child as FrameDataObject).hit_index == index:
			count += 1
	return count
