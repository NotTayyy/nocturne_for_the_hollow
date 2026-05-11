@tool
extends Area2D
class_name HitboxFrameData

## The MoveData resource this frame data belongs to
@export var move_data : MoveData

## How many hitbox shapes to add per index when clicking Add Frame
@export var hitboxes_to_add : int = 1

## Check this before clicking Bake to confirm — auto-unchecks after bake
@export var confirm_bake : bool = false

## Default box type for newly added shapes
@export var default_box_type : FrameDataObject.BoxType = FrameDataObject.BoxType.Hitbox :
	set(value):
		default_box_type = value
		_apply_collision_layers()

## Read-only index viewer — shows all hit indices and box counts
@export var index_viewer : Array[String] = []

## Live preview — shows hitbox state at current animation position
@export var preview_enabled : bool = false

## NodePath to the AnimationPlayer — set this in the Inspector
@export var preview_animation_player : NodePath = NodePath("../../../Char_Sprite_Animator")

## Read-only — current preview frame for reference
@export var preview_frame : int = 0

## Runtime — set by ST_Attack when a move begins
var _current_frame       : int        = 0
var _active              : bool       = false
var _move_data_rt        : MoveData   = null
var _current_active_index : int       = -1
var _spawned_shapes      : Array[CollisionShape2D] = []

## HitLog per index — prevents same target being hit twice per index
## key = hit_index, value = Array of hurtbox instance IDs already hit
var _hit_log             : Dictionary = {}

func _get_tool_buttons() -> Array:
	return [
		{ displayName = "Add Frame",             call = "AddFrame"          },
		{ displayName = "Clear All",             call = "ClearFrameData"    },
		{ displayName = "Bake to MoveData",      call = "Bake"              },
		{ displayName = "Restore from MoveData", call = "Restore"           },
		{ displayName = "Restore from Backup",   call = "RestoreFromBackup" },
	]

func _ready() -> void:
	_apply_collision_layers()
	if not Engine.is_editor_hint():
		area_entered.connect(_on_area_entered)

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if not preview_enabled or move_data == null:
		_preview_disable_all()
		return
	if preview_animation_player.is_empty():
		push_warning("[HFD Preview] No AnimationPlayer path set")
		return
	var ap : AnimationPlayer = get_node_or_null(preview_animation_player)
	if ap == null:
		push_warning("[HFD Preview] Could not find AnimationPlayer at: %s" % str(preview_animation_player))
		return
	preview_frame = int(ap.current_animation_position * 60.0)
	_preview_update(preview_frame)

func _preview_update(frame : int) -> void:
	var startup : int = move_data.startup
	var cursor  : int = 0
	var current_index : int = -1
	var active_frame  : int = frame - startup

	if frame <= startup:
		_preview_disable_all()
		return

	for i : int in move_data.active.size():
		var window : int = move_data.active[i]
		if active_frame > cursor and active_frame <= cursor + window:
			current_index = i
			break
		cursor += window
		if i < move_data.gaps.size():
			cursor += move_data.gaps[i]

	for child in get_children():
		if not child is FrameDataObject:
			continue
		var obj : FrameDataObject = child
		obj.disabled = obj.hit_index != current_index

func _preview_disable_all() -> void:
	for child in get_children():
		if child is FrameDataObject:
			(child as FrameDataObject).disabled = true

# =============================================================================
# Tmp hit detection test
# =============================================================================

func _on_area_entered(area : Area2D) -> void:
	# Ignore self — check owning fighter's player_id
	if area.owner == owner:
		return
	if not area.has_method("recieve_hit"):
		return
	var hit_index : int = _current_active_index
	if already_hit(hit_index, area.get_instance_id()):
		return
	register_hit(hit_index, area.get_instance_id())
	print("HIT! ", owner.name, " hit ", area.owner.name, " with index ", hit_index)
	print("Fag")

# =============================================================================
# Collision layers
# =============================================================================

func _apply_collision_layers() -> void:
	match default_box_type:
		FrameDataObject.BoxType.Hitbox:
			collision_layer = 16   # Layer 5
			collision_mask  = 1    # Layer 1
		FrameDataObject.BoxType.Hurtbox:
			collision_layer = 1    # Layer 1
			collision_mask  = 16   # Layer 5

# =============================================================================
# Runtime API — called by ST_Attack
# =============================================================================

func begin(p_move_data : MoveData) -> void:
	_move_data_rt         = p_move_data
	_current_frame        = 0
	_active               = true
	_current_active_index = -1
	_hit_log.clear()
	_despawn_shapes()

func tick() -> void:
	if not _active or _move_data_rt == null:
		return
	_current_frame += 1
	
	if _current_frame == 6:
		print(_active)
	_update_active_boxes()

func stop() -> void:
	_active = false
	_despawn_shapes()
	_hit_log.clear()
	_current_active_index = -1

func already_hit(hit_index : int, hurtbox_id : int) -> bool:
	if not _hit_log.has(hit_index):
		return false
	return hurtbox_id in _hit_log[hit_index]

func register_hit(hit_index : int, hurtbox_id : int) -> void:
	if not _hit_log.has(hit_index):
		_hit_log[hit_index] = []
	_hit_log[hit_index].append(hurtbox_id)

# =============================================================================
# Frame update — spawns/despawns shapes based on MoveData timeline
# =============================================================================

func _update_active_boxes() -> void:
	if _move_data_rt == null:
		return

	var startup      : int = _move_data_rt.startup
	var frame        : int = _current_frame
	var active_frame : int = frame - startup
	var new_index    : int = -1
	var cursor       : int = 0

	if frame <= startup:
		if _current_active_index != -1:
			_despawn_shapes()
			_current_active_index = -1
		return

	for i : int in _move_data_rt.active.size():
		var window_size : int = _move_data_rt.active[i]
		if active_frame > cursor and active_frame <= cursor + window_size:
			new_index = i
			break
		cursor += window_size
		if i < _move_data_rt.gaps.size():
			cursor += _move_data_rt.gaps[i]

	# Index changed — despawn old, spawn new
	if new_index != _current_active_index:
		_despawn_shapes()
		_current_active_index = new_index
		if new_index != -1:
			_spawn_shapes_for_index(new_index)

func _spawn_shapes_for_index(hit_index : int) -> void:
	var facing_right : bool = true
	if owner and owner.has_method("get") and owner.get("dir_facing") != null:
		facing_right = owner.dir_facing == "Right"

	for entry : Dictionary in _move_data_rt.hitbox_data:
		if entry.get("hit_index", 0) != hit_index:
			continue

		var shape_node : CollisionShape2D = CollisionShape2D.new()
		var rect       : RectangleShape2D = RectangleShape2D.new()
		var sz         : Dictionary       = entry.get("size",     { "x": 50.0, "y": 50.0 })
		var pos        : Dictionary       = entry.get("position", { "x": 0.0,  "y": 0.0  })

		var pos_x : float = pos["x"] if facing_right else -pos["x"]

		rect.size            = Vector2(sz["x"], sz["y"])
		shape_node.shape     = rect
		shape_node.position  = Vector2(pos_x, pos["y"])
		shape_node.name      = entry.get("name", "Hitbox_rt")
		shape_node.debug_color = Color(1.0, 0.2, 0.2, 0.35) if entry.get("box_type", 0) == FrameDataObject.BoxType.Hitbox else Color(0.0, 0.531, 0.852, 0.349)

		add_child(shape_node)
		_spawned_shapes.append(shape_node)

func _despawn_shapes() -> void:
	for shape in _spawned_shapes:
		if is_instance_valid(shape):
			shape.queue_free()
	_spawned_shapes.clear()

# =============================================================================
# Editor — Add / Remove
# =============================================================================

func AddFrame() -> void:
	var next_index : int = _get_next_hit_index()
	for i : int in hitboxes_to_add:
		var obj      : FrameDataObject = _make_frame_object_with_index(next_index, default_box_type)
		var box_num  : int             = i + 1
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

# =============================================================================
# Bake
# =============================================================================

func Bake() -> void:
	if move_data == null:
		push_error("[HFD] No MoveData assigned — cannot bake")
		return

	if not confirm_bake:
		push_warning("[HFD] Check 'Confirm Bake' in the Inspector before baking")
		return

	# Auto-backup current hitbox_data before overwriting
	if not move_data.hitbox_data.is_empty():
		move_data.hitbox_data_backup = move_data.hitbox_data.duplicate(true)
		print("[HFD] Backed up %d existing boxes" % move_data.hitbox_data_backup.size())

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
			"name":        obj.name,
			"hit_index":   obj.hit_index,
			"start_frame": obj.start_frame,
			"end_frame":   obj.end_frame,
			"box_type":    obj.box_type,
			"position":    { "x": position.x, "y": position.y },
			"size":        { "x": size.x,     "y": size.y     },
		})

	move_data.hitbox_data = baked

	# Remove children after baking
	ClearFrameData()

	if move_data.resource_path != "":
		ResourceSaver.save(move_data)

	confirm_bake = false
	print("[HFD] Baked %d boxes to %s" % [baked.size(), move_data.resource_path])

func RestoreFromBackup() -> void:
	if move_data == null:
		push_error("[HFD] No MoveData assigned")
		return
	if move_data.hitbox_data_backup.is_empty():
		push_warning("[HFD] No backup found — bake something first")
		return
	move_data.hitbox_data = move_data.hitbox_data_backup.duplicate(true)
	if move_data.resource_path != "":
		ResourceSaver.save(move_data)
	print("[HFD] Restored %d boxes from backup" % move_data.hitbox_data.size())

# =============================================================================
# Restore
# =============================================================================

func Restore() -> void:
	if move_data == null:
		push_error("[HFD] No MoveData assigned — cannot restore")
		return

	if move_data.hitbox_data.is_empty():
		push_warning("[HFD] No hitbox data found in MoveData")
		return

	ClearFrameData()

	for entry : Dictionary in move_data.hitbox_data:
		var obj          : FrameDataObject  = FrameDataObject.new()
		obj.name         = entry.get("name",         "Box_%d" % get_child_count())
		obj.hit_index    = entry.get("hit_index",    0)
		obj.start_frame  = entry.get("start_frame", -1)
		obj.end_frame    = entry.get("end_frame",   -1)
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
	# No children — start at 0
	if children.is_empty():
		return 0
	# Find the highest hit_index among existing FrameDataObjects
	var max_index : int = 0
	for child in children:
		if child is FrameDataObject:
			var idx : int = (child as FrameDataObject).hit_index
			if idx > max_index:
				max_index = idx
	# Increment from the highest found
	return max_index + 1

func _make_frame_object_with_index(hit_index : int, box_type : FrameDataObject.BoxType) -> FrameDataObject:
	var obj          : FrameDataObject  = FrameDataObject.new()
	obj.hit_index    = hit_index
	obj.start_frame  = -1
	obj.end_frame    = -1
	obj.box_type     = box_type

	var rect         : RectangleShape2D = RectangleShape2D.new()
	rect.size        = Vector2(50.0, 50.0)
	obj.shape        = rect

	return obj

func _refresh_index_viewer() -> void:
	var index_map : Dictionary = {}
	for child in get_children():
		if not child is FrameDataObject:
			continue
		var idx : int = (child as FrameDataObject).hit_index
		if not index_map.has(idx):
			index_map[idx] = 0
		index_map[idx] += 1

	index_viewer.clear()
	var sorted_keys : Array = index_map.keys()
	sorted_keys.sort()
	for key in sorted_keys:
		index_viewer.append("Index %d: %d box(es)" % [key, index_map[key]])
	notify_property_list_changed()
