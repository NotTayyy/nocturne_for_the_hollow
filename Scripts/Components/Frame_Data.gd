@tool
extends Area2D
class_name HitboxFrameData

# =============================================================================
# Exports
# =============================================================================

## MoveData for attack moves. Leave null for state hurtbox-only HFDs
@export var move_data : MoveData

## How many HitDO shapes to add per index when clicking Add Hitbox Frame
@export var hitboxes_to_add : int = 1

## Check this before clicking Bake to confirm — auto-unchecks after bake
@export var confirm_bake : bool = false

## Controls which box type all buttons affect
enum Mode { Hitbox, Hurtbox }
@export var mode : Mode = Mode.Hitbox

## Read-only index viewer — shows all hit indices and HitDO box counts
@export var index_viewer : Array[String] = []

## State hurtbox data — baked here when move_data is null
@export var state_hurtbox_data        : Array[Dictionary] = []
var state_hurtbox_data_backup         : Array[Dictionary] = []

## State hurtbox data backup — not shown in Inspector
var _hurtbox_data_backup              : Array[Dictionary] = []

## Live preview
@export var preview_enabled : bool = false
@export var preview_animation_player : NodePath = NodePath("../../../Char_Sprite_Animator")
@export var preview_frame : int = 0

# =============================================================================
# Runtime vars
# =============================================================================

var _current_frame        : int   = 0
var _active               : bool  = false
var _move_data_rt         : MoveData = null
var _current_active_index : int   = -1
var _spawned_hit_shapes   : Array[CollisionShape2D] = []
var _spawned_hurt_shapes  : Array[CollisionShape2D] = []
## Maps entry name → spawned shape node for individual lifecycle management
var _hurt_shape_map       : Dictionary = {}
var _hit_log              : Dictionary = {}

# =============================================================================
# Tool buttons
# =============================================================================

func _get_tool_buttons() -> Array:
	return [
		{ displayName = "Add Frame",          call = "AddFrame"          },
		{ displayName = "Clear",              call = "ClearMode"         },
		{ displayName = "Clear All",          call = "ClearAll"          },
		{ displayName = "Bake",               call = "Bake"              },
		{ displayName = "Restore",            call = "Restore"           },
		{ displayName = "Restore from Backup",call = "RestoreFromBackup" },
	]

# =============================================================================
# Ready / Process
# =============================================================================

func _ready() -> void:
	_apply_collision_layers()
	if not Engine.is_editor_hint():
		area_entered.connect(_on_area_entered)

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if not preview_enabled:
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

# =============================================================================
# Editor preview
# =============================================================================

func _preview_update(frame : int) -> void:
	# HitDO preview — needs MoveData timeline
	if move_data != null:
		var startup      : int = move_data.startup
		var active_frame : int = frame - startup
		var current_index : int = -1
		var cursor       : int = 0

		if frame > startup:
			for i : int in move_data.active.size():
				var window : int = move_data.active[i]
				if active_frame > cursor and active_frame <= cursor + window:
					current_index = i
					break
				cursor += window
				if i < move_data.gaps.size():
					cursor += move_data.gaps[i]

		for child in get_children():
			if child is HitboxDataObject:
				var obj : HitboxDataObject = child
				obj.disabled = obj.hit_index != current_index

	# HurtDO preview — frame window based
	for child in get_children():
		if not child is HurtboxDataObject:
			continue
		var obj    : HurtboxDataObject = child
		var active : bool = true
		if obj.start_frame != -1 and frame < obj.start_frame:
			active = false
		if obj.end_frame != -1 and frame > obj.end_frame:
			active = false
		obj.disabled = not active

func _preview_disable_all() -> void:
	for child in get_children():
		if child is HitboxDataObject:
			(child as HitboxDataObject).disabled = true
		elif child is HurtboxDataObject:
			(child as HurtboxDataObject).disabled = true

# =============================================================================
# Hit detection (tmp)
# =============================================================================

func _on_area_entered(area : Area2D) -> void:
	if area.owner == owner:
		return
	if not area.has_method("recieve_hit"):
		return
	var hit_index : int = _current_active_index
	if already_hit(hit_index, area.get_instance_id()):
		return
	register_hit(hit_index, area.get_instance_id())
	print("HIT! ", owner.name, " hit ", area.owner.name, " with index ", hit_index)

# =============================================================================
# Collision layers
# =============================================================================

func _apply_collision_layers() -> void:
	# HFD itself is always a hitbox Area2D — Layer 5, Mask 1
	collision_layer = 16
	collision_mask  = 1

# =============================================================================
# Runtime API
# =============================================================================

func begin(p_move_data : MoveData) -> void:
	_move_data_rt         = p_move_data
	_current_frame        = 0
	_active               = true
	_current_active_index = -1
	_hit_log.clear()
	_despawn_hit_shapes()
	_despawn_hurt_shapes()
	# Spawn state hurtboxes immediately if no move_data
	if _move_data_rt == null:
		_spawn_state_hurtboxes(0)

func tick() -> void:
	if not _active:
		return
	_current_frame += 1
	if _move_data_rt != null:
		_update_hitboxes()
	_update_hurtboxes()

func stop() -> void:
	_active = false
	_despawn_hit_shapes()
	_despawn_hurt_shapes()
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
# Frame update — hitboxes
# =============================================================================

func _update_hitboxes() -> void:
	var startup      : int = _move_data_rt.startup
	var frame        : int = _current_frame
	var active_frame : int = frame - startup
	var new_index    : int = -1
	var cursor       : int = 0

	if frame <= startup:
		if _current_active_index != -1:
			_despawn_hit_shapes()
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

	if new_index != _current_active_index:
		_despawn_hit_shapes()
		_current_active_index = new_index
		if new_index != -1:
			_spawn_hit_shapes_for_index(new_index)

# =============================================================================
# Frame update — hurtboxes
# =============================================================================

func _update_hurtboxes() -> void:
	var frame    : int = _current_frame
	var data_src : Array[Dictionary]

	if _move_data_rt != null and not _move_data_rt.hurtbox_data.is_empty():
		data_src = _move_data_rt.hurtbox_data
	else:
		data_src = state_hurtbox_data

	for entry : Dictionary in data_src:
		var name_key : String = entry.get("name", "")
		var sf       : int    = entry.get("start_frame", -1)
		var ef       : int    = entry.get("end_frame",   -1)

		# Should this shape be alive?
		var should_exist : bool = true
		if sf != -1 and frame < sf:
			should_exist = false
		if ef != -1 and frame > ef:
			should_exist = false

		var already_spawned : bool = _hurt_shape_map.has(name_key) and is_instance_valid(_hurt_shape_map[name_key])

		if should_exist and not already_spawned:
			# Spawn it
			var shape_node : CollisionShape2D = _spawn_hurt_shape(entry)
			if shape_node != null:
				_hurt_shape_map[name_key] = shape_node
		elif not should_exist and already_spawned:
			# Free it
			var shape : CollisionShape2D = _hurt_shape_map[name_key]
			_spawned_hurt_shapes.erase(shape)
			_hurt_shape_map.erase(name_key)
			shape.queue_free()

func _spawn_state_hurtboxes(frame : int) -> void:
	_despawn_hurt_shapes()
	for entry : Dictionary in state_hurtbox_data:
		var sf : int = entry.get("start_frame", -1)
		var ef : int = entry.get("end_frame",   -1)
		var active : bool = true
		if sf != -1 and frame < sf:
			active = false
		if ef != -1 and frame > ef:
			active = false
		if active:
			_spawn_hurt_shape(entry)

# =============================================================================
# Spawn / despawn
# =============================================================================

func _spawn_hit_shapes_for_index(hit_index : int) -> void:
	var facing_right : bool = true
	if owner and owner.get("dir_facing") != null:
		facing_right = owner.dir_facing == "Right"

	for entry : Dictionary in _move_data_rt.hitbox_data:
		if entry.get("hit_index", 0) != hit_index:
			continue
		var sf : int = entry.get("start_frame", -1)
		var ef : int = entry.get("end_frame",   -1)
		if sf != -1 and _current_frame < sf:
			continue
		if ef != -1 and _current_frame > ef:
			continue

		var shape_node : CollisionShape2D = CollisionShape2D.new()
		var rect       : RectangleShape2D = RectangleShape2D.new()
		var sz         : Dictionary       = entry.get("size",     { "x": 50.0, "y": 50.0 })
		var pos        : Dictionary       = entry.get("position", { "x": 0.0,  "y": 0.0  })
		var pos_x      : float            = pos["x"] if facing_right else -pos["x"]

		rect.size              = Vector2(sz["x"], sz["y"])
		shape_node.shape       = rect
		shape_node.position    = Vector2(pos_x, pos["y"])
		shape_node.name        = entry.get("name", "HitDO_rt")
		shape_node.debug_color = Color(1.0, 0.2, 0.2, 0.35)

		add_child(shape_node)
		_spawned_hit_shapes.append(shape_node)

func _spawn_hurt_shape(entry : Dictionary) -> CollisionShape2D:
	var facing_right : bool = true
	if owner and owner.get("dir_facing") != null:
		facing_right = owner.dir_facing == "Right"

	# Hurtboxes use a separate Area2D on Layer 1
	# We spawn them on the fighter's Hurtbox Area2D if available
	# For now spawn as CollisionShape2D children of a hurtbox node
	var shape_node : CollisionShape2D = CollisionShape2D.new()
	var rect       : RectangleShape2D = RectangleShape2D.new()
	var sz         : Dictionary       = entry.get("size",     { "x": 50.0, "y": 50.0 })
	var pos        : Dictionary       = entry.get("position", { "x": 0.0,  "y": 0.0  })
	var pos_x      : float            = pos["x"] if facing_right else -pos["x"]

	rect.size              = Vector2(sz["x"], sz["y"])
	shape_node.shape       = rect
	shape_node.position    = Vector2(pos_x, pos["y"])
	shape_node.name        = entry.get("name", "HurtDO_rt")
	shape_node.debug_color = Color(0.0, 0.531, 0.852, 0.35)

	# Add to fighter's hurtbox node if it exists, otherwise add here
	var hurtbox_node : Node = null
	if owner:
		hurtbox_node = owner.get_node_or_null("Components/Hurtbox")
	if hurtbox_node != null:
		hurtbox_node.add_child(shape_node)
	else:
		add_child(shape_node)
	_spawned_hurt_shapes.append(shape_node)
	return shape_node

func _despawn_hit_shapes() -> void:
	for shape in _spawned_hit_shapes:
		if is_instance_valid(shape):
			shape.queue_free()
	_spawned_hit_shapes.clear()

func _despawn_hurt_shapes() -> void:
	for shape in _spawned_hurt_shapes:
		if is_instance_valid(shape):
			shape.queue_free()
	_spawned_hurt_shapes.clear()
	_hurt_shape_map.clear()

# =============================================================================
# Editor buttons — all routed through mode
# =============================================================================

func AddFrame() -> void:
	if mode == Mode.Hitbox:
		var next_index : int = _get_next_hit_index()
		for i : int in hitboxes_to_add:
			var obj : HitboxDataObject = _make_hitdo(next_index)
			obj.name = "HitDO_%d_index_%d" % [i + 1, next_index]
			add_child(obj)
			obj.owner = get_tree().edited_scene_root
		_refresh_index_viewer()
	else:
		var count : int = 0
		for child in get_children():
			if child is HurtboxDataObject:
				count += 1
		var obj : HurtboxDataObject = _make_hurtdo()
		obj.name        = "HurtDO_%d" % (count + 1)
		obj.start_frame = preview_frame
		add_child(obj)
		obj.owner = get_tree().edited_scene_root

## Clears only the current mode's children
func ClearMode() -> void:
	for child in get_children():
		if mode == Mode.Hitbox and child is HitboxDataObject:
			child.free()
		elif mode == Mode.Hurtbox and child is HurtboxDataObject:
			child.free()
	_refresh_index_viewer()

## Clears all HitDO and HurtDO children regardless of mode
func ClearAll() -> void:
	for child in get_children():
		if child is HitboxDataObject or child is HurtboxDataObject:
			child.free()
	_refresh_index_viewer()

func ClearFrameData() -> void:
	ClearAll()

func Bake() -> void:
	if not confirm_bake:
		push_warning("[HFD] Check 'Confirm Bake' before baking")
		return
	if mode == Mode.Hitbox:
		_bake_hitboxes()
	else:
		_bake_hurtboxes()
	confirm_bake = false

func Restore() -> void:
	if mode == Mode.Hitbox:
		_restore_hitboxes()
	else:
		_restore_hurtboxes()

func RestoreFromBackup() -> void:
	if mode == Mode.Hitbox:
		_restore_hitbox_backup()
	else:
		_restore_hurtbox_backup()

# =============================================================================
# Bake / Restore internals
# =============================================================================

func _bake_hitboxes() -> void:
	if move_data == null:
		push_error("[HFD] No MoveData assigned — cannot bake hitboxes")
		return
	var baked : Array[Dictionary] = []
	for child in get_children():
		if not child is HitboxDataObject:
			continue
		var obj : HitboxDataObject = child
		if obj.shape == null:
			continue
		var size : Vector2 = Vector2.ZERO
		if obj.shape is RectangleShape2D:
			size = (obj.shape as RectangleShape2D).size
		baked.append({
			"name":        obj.name,
			"hit_index":   obj.hit_index,
			"start_frame": obj.start_frame,
			"end_frame":   obj.end_frame,
			"position":    { "x": obj.position.x, "y": obj.position.y },
			"size":        { "x": size.x, "y": size.y },
		})
	if not move_data.hitbox_data.is_empty():
		move_data.hitbox_data_backup = move_data.hitbox_data.duplicate(true)
	move_data.hitbox_data = baked
	if move_data.resource_path != "":
		ResourceSaver.save(move_data)
	for child in get_children():
		if child is HitboxDataObject:
			child.free()
	_refresh_index_viewer()
	print("[HFD] Baked %d hitboxes" % baked.size())

func _bake_hurtboxes() -> void:
	var baked : Array[Dictionary] = []
	for child in get_children():
		if not child is HurtboxDataObject:
			continue
		var obj : HurtboxDataObject = child
		if obj.shape == null:
			continue
		var size : Vector2 = Vector2.ZERO
		if obj.shape is RectangleShape2D:
			size = (obj.shape as RectangleShape2D).size
		baked.append({
			"name":        obj.name,
			"start_frame": obj.start_frame,
			"end_frame":   obj.end_frame,
			"position":    { "x": obj.position.x, "y": obj.position.y },
			"size":        { "x": size.x, "y": size.y },
		})
	if move_data != null:
		_hurtbox_data_backup    = move_data.hurtbox_data.duplicate(true)
		move_data.hurtbox_data  = baked
		if move_data.resource_path != "":
			ResourceSaver.save(move_data)
		print("[HFD] Baked %d hurtboxes to MoveData" % baked.size())
	else:
		state_hurtbox_data_backup = state_hurtbox_data.duplicate(true)
		state_hurtbox_data        = baked
		print("[HFD] Baked %d state hurtboxes to node" % baked.size())
	for child in get_children():
		if child is HurtboxDataObject:
			child.free()

func _restore_hitboxes() -> void:
	if move_data == null:
		push_error("[HFD] No MoveData assigned")
		return
	if move_data.hitbox_data.is_empty():
		push_warning("[HFD] No hitbox data in MoveData")
		return
	for child in get_children():
		if child is HitboxDataObject:
			child.free()
	for entry : Dictionary in move_data.hitbox_data:
		var obj : HitboxDataObject = _make_hitdo(entry.get("hit_index", 0))
		obj.name        = entry.get("name", "HitDO")
		obj.start_frame = entry.get("start_frame", -1)
		obj.end_frame   = entry.get("end_frame",   -1)
		_apply_entry_shape(obj, entry)
		add_child(obj)
		obj.owner = get_tree().edited_scene_root
	_refresh_index_viewer()
	print("[HFD] Restored %d hitboxes" % move_data.hitbox_data.size())

func _restore_hurtboxes() -> void:
	var src : Array[Dictionary] = move_data.hurtbox_data if move_data != null else state_hurtbox_data
	if src.is_empty():
		push_warning("[HFD] No hurtbox data to restore")
		return
	for child in get_children():
		if child is HurtboxDataObject:
			child.free()
	for entry : Dictionary in src:
		var obj : HurtboxDataObject = _make_hurtdo()
		obj.name        = entry.get("name", "HurtDO")
		obj.start_frame = entry.get("start_frame", -1)
		obj.end_frame   = entry.get("end_frame",   -1)
		_apply_entry_shape(obj, entry)
		add_child(obj)
		obj.owner = get_tree().edited_scene_root
	print("[HFD] Restored %d hurtboxes" % src.size())

func _restore_hitbox_backup() -> void:
	if move_data == null:
		push_error("[HFD] No MoveData assigned")
		return
	if move_data.hitbox_data_backup.is_empty():
		push_warning("[HFD] No hitbox backup found")
		return
	move_data.hitbox_data = move_data.hitbox_data_backup.duplicate(true)
	if move_data.resource_path != "":
		ResourceSaver.save(move_data)
	print("[HFD] Restored hitboxes from backup")

func _restore_hurtbox_backup() -> void:
	if move_data != null:
		if _hurtbox_data_backup.is_empty():
			push_warning("[HFD] No hurtbox backup found")
			return
		move_data.hurtbox_data = _hurtbox_data_backup.duplicate(true)
		if move_data.resource_path != "":
			ResourceSaver.save(move_data)
		print("[HFD] Restored MoveData hurtboxes from backup")
	else:
		if state_hurtbox_data_backup.is_empty():
			push_warning("[HFD] No state hurtbox backup found")
			return
		state_hurtbox_data = state_hurtbox_data_backup.duplicate(true)
		print("[HFD] Restored state hurtboxes from backup")

# =============================================================================
# Helpers
# =============================================================================

func _apply_entry_shape(node : CollisionShape2D, entry : Dictionary) -> void:
	var pos  : Dictionary       = entry.get("position", { "x": 0.0,  "y": 0.0  })
	var sz   : Dictionary       = entry.get("size",     { "x": 50.0, "y": 50.0 })
	node.position               = Vector2(pos["x"], pos["y"])
	var rect : RectangleShape2D = RectangleShape2D.new()
	rect.size                   = Vector2(sz["x"], sz["y"])
	node.shape                  = rect

func _make_hitdo(hit_index : int) -> HitboxDataObject:
	var obj         : HitboxDataObject = HitboxDataObject.new()
	obj.hit_index   = hit_index
	obj.start_frame = -1
	obj.end_frame   = -1
	var rect        : RectangleShape2D = RectangleShape2D.new()
	rect.size       = Vector2(50.0, 50.0)
	obj.shape       = rect
	return obj

func _make_hurtdo() -> HurtboxDataObject:
	var obj         : HurtboxDataObject = HurtboxDataObject.new()
	obj.start_frame = -1
	obj.end_frame   = -1
	var rect        : RectangleShape2D  = RectangleShape2D.new()
	rect.size       = Vector2(50.0, 50.0)
	obj.shape       = rect
	return obj

func _get_next_hit_index() -> int:
	var max_index : int = -1
	for child in get_children():
		if child is HitboxDataObject:
			var idx : int = (child as HitboxDataObject).hit_index
			if idx > max_index:
				max_index = idx
	return max_index + 1

func _refresh_index_viewer() -> void:
	var index_map : Dictionary = {}
	for child in get_children():
		if child is HitboxDataObject:
			var idx : int = (child as HitboxDataObject).hit_index
			if not index_map.has(idx):
				index_map[idx] = 0
			index_map[idx] += 1
	index_viewer.clear()
	var sorted_keys : Array = index_map.keys()
	sorted_keys.sort()
	for key in sorted_keys:
		index_viewer.append("Index %d: %d HitDO(s)" % [key, index_map[key]])
	notify_property_list_changed()
