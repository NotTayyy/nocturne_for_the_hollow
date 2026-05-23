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

## Animations this HFD is valid for — drives active_set dropdown
@export var valid_animations : Array[String] = [] :
	set(value):
		valid_animations = value
		notify_property_list_changed()

## Which animation set is currently being edited — shown as dropdown
var active_set : String = ""

## Hitbox data — baked from HitDO children, lives on HFD not MoveData
@export var hitbox_data  : Array[Dictionary] = []

## Hurtbox sets — keyed by animation name
@export var hurtbox_sets : Dictionary = {}

## Live preview
@export var preview_enabled          : bool     = false
@export var preview_animation_player : NodePath = NodePath("../../../Char_Sprite_Animator")
@export var preview_frame            : int      = 0

# =============================================================================
# Backups
# =============================================================================
@export var hitbox_data_backup  : Array[Dictionary] = []
@export var hurtbox_sets_backup : Dictionary        = {}

# =============================================================================
# HitState
# =============================================================================

enum HitState { NONE, HIT, BLOCK }
var hit_state : HitState = HitState.NONE

# =============================================================================
# Runtime vars
# =============================================================================

var _current_frame        : int             = 0
var _active               : bool            = false
var _move_data_rt         : MoveData        = null
var _current_active_index : int             = -1
var _current_anim_rt      : String          = ""
var _ap_rt                : AnimationPlayer = null
var _spawned_hit_shapes   : Array[CollisionShape2D] = []
var _spawned_hurt_shapes  : Array[CollisionShape2D] = []
var _hurt_shape_map       : Dictionary      = {}
var _hit_log              : Dictionary      = {}

# =============================================================================
# Tool buttons
# =============================================================================

func _get_tool_buttons() -> Array:
	return [
		{ displayName = "Add Frame",           call = "AddFrame"          },
		{ displayName = "Clear",               call = "ClearMode"         },
		{ displayName = "Clear All",           call = "ClearAll"          },
		{ displayName = "Bake",                call = "Bake"              },
		{ displayName = "Restore",             call = "Restore"           },
		{ displayName = "Restore from Backup", call = "RestoreFromBackup" },
	]

func _get_property_list() -> Array:
	var props : Array = []
	if valid_animations.is_empty():
		props.append({
			"name": "active_set", "type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_NONE, "hint_string": "",
		})
	else:
		props.append({
			"name": "active_set", "type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(valid_animations),
		})
	return props

func _get(property: StringName):
	if property == "active_set": return active_set
	return null

func _set(property: StringName, value) -> bool:
	if property == "active_set":
		active_set = value
		return true
	return false

# =============================================================================
# Ready / Process
# =============================================================================

func _ready() -> void:
	_apply_collision_layers()
	if not Engine.is_editor_hint():
		area_entered.connect(_on_area_entered)

func _on_area_entered(area : Area2D) -> void:
	if not area is Hurtbox:
		return
	if area.owner == owner:
		return
	var h_index : int = _current_active_index
	if already_hit(h_index, area.get_instance_id()):
		return
	register_hit(h_index, area.get_instance_id())

	var attacker : Fighter = owner as Fighter
	var defender : Fighter = area.owner as Fighter
	if attacker == null or defender == null:
		return

	var result         : HitResult = HitResult.new()
	result.attacker    = attacker
	result.defender    = defender
	result.move_data   = move_data
	result.hit_index   = h_index
	result.is_airborne = defender.is_airborne
	result.is_counter  = defender.state_machine.active_state != null \
						 and defender.state_machine.active_state.state_id == "Attack"

	if move_data != null:
		var g_idx : int = min(h_index, move_data.guard.size() - 1)
		var a_idx : int = min(h_index, move_data.attribute.size() - 1)
		if not move_data.guard.is_empty():
			result.guard_type = move_data.guard[g_idx]
		if not move_data.attribute.is_empty():
			result.attribute  = move_data.attribute[a_idx]

	# --- Block check ---
	result.is_blocked = _check_block(defender, result.guard_type)

	# Set hit state on HFD
	hit_state = HitState.BLOCK if result.is_blocked else HitState.HIT

	Global.combo_manager.register_hit(result)

## Check if the defender is blocking this attack correctly
func _check_block(defender : Fighter, guard_type : MoveData.GuardType) -> bool:
	# Carryover — auto-block regardless of direction or state
	if defender.block_carryover:
		return _check_guard_type(defender, guard_type, true)
	# Normal block — must be holding back AND in a neutral state
	if not defender.wants_to_block:
		return false
	var state_id   : String = defender.state_machine.active_state.state_id if defender.state_machine.active_state else ""
	var is_neutral : bool   = state_id in ["Idle", "Walk", "Airborne", "Crouch"]
	if not is_neutral:
		return false
	return _check_guard_type(defender, guard_type, false)

## Check if the held direction is correct for the guard type
func _check_guard_type(defender : Fighter, guard_type : MoveData.GuardType, carryover : bool) -> bool:
	var held       := defender.input_buffer.held_inputs
	var block_type : String = defender.get_block_type()

	# Carryover with no explicit block direction — auto-block high/mid, check low
	if carryover and block_type == "":
		if guard_type == MoveData.GuardType.Low:
			var low_held : bool = "1" in held or "2" in held or "3" in held
			if not low_held:
				print("[BLOCK] %s wrong block — Low attack needs downward direction (carryover)" % defender.name)
				return false
		print("[BLOCK] %s blocked via carryover" % defender.name)
		return true

	match guard_type:
		MoveData.GuardType.Low:
			if block_type == "Crouch" or (carryover and ("1" in held or "2" in held or "3" in held)):
				print("[BLOCK] %s blocked Low" % defender.name)
				return true
			print("[BLOCK] %s wrong block — Low requires Crouch (1)" % defender.name)
			return false
		MoveData.GuardType.High:
			if block_type == "Stand" or block_type == "Crouch" or block_type == "Air":
				print("[BLOCK] %s blocked High" % defender.name)
				return true
			print("[BLOCK] %s wrong block — High requires back direction" % defender.name)
			return false
		MoveData.GuardType.Mid:
			if block_type != "":
				print("[BLOCK] %s blocked Mid" % defender.name)
				return true
			print("[BLOCK] %s wrong block — Mid requires back direction" % defender.name)
			return false
		_:
			return false

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
	_preview_update(preview_frame, ap.current_animation)

# =============================================================================
# Editor preview
# =============================================================================

func _preview_update(frame : int, current_anim : String) -> void:
	if move_data != null and not hitbox_data.is_empty():
		var startup       : int = move_data.startup
		var active_frame  : int = frame - startup
		var current_index : int = -1
		var cursor        : int = 0
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
				(child as HitboxDataObject).disabled = (child as HitboxDataObject).hit_index != current_index

	for child in get_children():
		if not child is HurtboxDataObject:
			continue
		var obj    : HurtboxDataObject = child
		var active : bool = true
		if obj.start_frame != -1 and frame < obj.start_frame: active = false
		if obj.end_frame   != -1 and frame > obj.end_frame:   active = false
		obj.disabled = not active

	var _anim : String = current_anim

func _preview_disable_all() -> void:
	for child in get_children():
		if child is HitboxDataObject:
			(child as HitboxDataObject).disabled = true
		elif child is HurtboxDataObject:
			(child as HurtboxDataObject).disabled = true

# =============================================================================
# Collision layers
# =============================================================================

func _apply_collision_layers() -> void:
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
	hit_state             = HitState.NONE
	_hit_log.clear()
	_despawn_hit_shapes()
	_despawn_hurt_shapes()
	_current_anim_rt      = ""
	_ap_rt = get_node_or_null(preview_animation_player) as AnimationPlayer

func tick() -> void:
	if not _active:
		return
	_current_frame += 1
	if _move_data_rt != null:
		_update_hitboxes()
	_update_hurtboxes()

func stop() -> void:
	_active               = false
	hit_state             = HitState.NONE
	_despawn_hit_shapes()
	_despawn_hurt_shapes()
	_hit_log.clear()
	_current_active_index = -1
	_current_anim_rt      = ""
	_ap_rt                = null

func already_hit(h_index : int, hurtbox_id : int) -> bool:
	if not _hit_log.has(h_index): return false
	return hurtbox_id in _hit_log[h_index]

func register_hit(h_index : int, hurtbox_id : int) -> void:
	if not _hit_log.has(h_index):
		_hit_log[h_index] = []
	_hit_log[h_index].append(hurtbox_id)

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
	var current_anim : String = ""
	if _ap_rt != null:
		current_anim = _ap_rt.current_animation

	# Animation changed — reset frame counter and flush hurt shapes immediately
	if current_anim != _current_anim_rt:
		_despawn_hurt_shapes()
		_current_anim_rt = current_anim
		_current_frame   = 0

	var data_src : Array = []
	if hurtbox_sets.has(current_anim):
		data_src = hurtbox_sets[current_anim]

	# Free shapes whose frame window has closed
	for name_key in _hurt_shape_map.keys():
		var shape : CollisionShape2D = _hurt_shape_map[name_key]
		if not is_instance_valid(shape):
			_hurt_shape_map.erase(name_key)
			continue
		var still_valid : bool = false
		for entry in data_src:
			if entry.get("name", "") == name_key:
				var sf : int = entry.get("start_frame", -1)
				var ef : int = entry.get("end_frame",   -1)
				var in_window : bool = true
				if sf != -1 and _current_frame < sf: in_window = false
				if ef != -1 and _current_frame > ef: in_window = false
				if in_window: still_valid = true
				break
		if not still_valid:
			_spawned_hurt_shapes.erase(shape)
			_hurt_shape_map.erase(name_key)
			shape.free()

	# Spawn shapes whose frame window has opened
	for entry : Dictionary in data_src:
		var name_key  : String = entry.get("name", "")
		var sf        : int    = entry.get("start_frame", -1)
		var ef        : int    = entry.get("end_frame",   -1)
		var in_window : bool   = true
		if sf != -1 and _current_frame < sf: in_window = false
		if ef != -1 and _current_frame > ef: in_window = false
		var already_spawned : bool = _hurt_shape_map.has(name_key) and is_instance_valid(_hurt_shape_map[name_key])
		if in_window and not already_spawned:
			var shape_node : CollisionShape2D = _spawn_hurt_shape(entry)
			if shape_node != null:
				_hurt_shape_map[name_key] = shape_node

# =============================================================================
# Spawn / despawn
# =============================================================================

func _spawn_hit_shapes_for_index(hit_index : int) -> void:
	var facing_right : bool = true
	if owner and owner.get("dir_facing") != null:
		facing_right = owner.dir_facing == "Right"

	for entry : Dictionary in hitbox_data:
		if entry.get("hit_index", 0) != hit_index:
			continue
		var sf : int = entry.get("start_frame", -1)
		var ef : int = entry.get("end_frame",   -1)
		if sf != -1 and _current_frame < sf: continue
		if ef != -1 and _current_frame > ef: continue

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
		if is_instance_valid(shape): shape.free()
	_spawned_hit_shapes.clear()

func _despawn_hurt_shapes() -> void:
	for shape in _spawned_hurt_shapes:
		if is_instance_valid(shape): shape.free()
	_spawned_hurt_shapes.clear()
	_hurt_shape_map.clear()

# =============================================================================
# Editor buttons
# =============================================================================

func AddFrame() -> void:
	if mode == Mode.Hitbox:
		var next_index : int = _get_next_hit_index()
		for i : int in hitboxes_to_add:
			var obj : HitboxDataObject = _make_hitdo(next_index)
			obj.name        = "HitDO_%d_index_%d" % [i + 1, next_index]
			obj.start_frame = preview_frame
			add_child(obj)
			obj.owner = get_tree().edited_scene_root
	else:
		var count : int = 0
		for child in get_children():
			if child is HurtboxDataObject: count += 1
		var obj : HurtboxDataObject = _make_hurtdo()
		obj.name        = "HurtDO_%d" % (count + 1)
		obj.start_frame = preview_frame
		add_child(obj)
		obj.owner = get_tree().edited_scene_root

func ClearMode() -> void:
	for child in get_children():
		if mode == Mode.Hitbox and child is HitboxDataObject:     child.free()
		elif mode == Mode.Hurtbox and child is HurtboxDataObject: child.free()

func ClearAll() -> void:
	for child in get_children():
		if child is HitboxDataObject or child is HurtboxDataObject:
			child.free()

func ClearFrameData() -> void:
	ClearAll()

func Bake() -> void:
	if not confirm_bake:
		push_warning("[HFD] Check 'Confirm Bake' before baking")
		return
	if mode == Mode.Hitbox: _bake_hitboxes()
	else:                   _bake_hurtboxes()
	confirm_bake = false
	preview_enabled = false

func Restore() -> void:
	if mode == Mode.Hitbox: _restore_hitboxes()
	else:                   _restore_hurtboxes()

func RestoreFromBackup() -> void:
	if mode == Mode.Hitbox: _restore_hitbox_backup()
	else:                   _restore_hurtbox_backup()

# =============================================================================
# Bake / Restore internals
# =============================================================================

func _bake_hitboxes() -> void:
	var baked : Array[Dictionary] = []
	for child in get_children():
		if not child is HitboxDataObject: continue
		var obj : HitboxDataObject = child
		if obj.shape == null: continue
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
	if not hitbox_data.is_empty():
		hitbox_data_backup = hitbox_data.duplicate(true)
	hitbox_data = baked
	for child in get_children():
		if child is HitboxDataObject: child.free()
	print("[HFD] Baked %d hitboxes" % baked.size())

func _bake_hurtboxes() -> void:
	if active_set == "":
		push_warning("[HFD] No active_set selected — pick an animation from the dropdown before baking")
		return
	var baked : Array[Dictionary] = []
	for child in get_children():
		if not child is HurtboxDataObject: continue
		var obj : HurtboxDataObject = child
		if obj.shape == null: continue
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
	hurtbox_sets_backup      = hurtbox_sets.duplicate(true)
	hurtbox_sets[active_set] = baked
	for child in get_children():
		if child is HurtboxDataObject: child.free()
	print("[HFD] Baked %d hurtboxes to set '%s'" % [baked.size(), active_set])

func _restore_hitboxes() -> void:
	if hitbox_data.is_empty():
		push_warning("[HFD] No hitbox data to restore")
		return
	for child in get_children():
		if child is HitboxDataObject: child.free()
	for entry : Dictionary in hitbox_data:
		var obj : HitboxDataObject = _make_hitdo(entry.get("hit_index", 0))
		obj.name        = entry.get("name", "HitDO")
		obj.start_frame = entry.get("start_frame", -1)
		obj.end_frame   = entry.get("end_frame",   -1)
		_apply_entry_shape(obj, entry)
		add_child(obj)
		obj.owner = get_tree().edited_scene_root
	print("[HFD] Restored %d hitboxes" % hitbox_data.size())

func _restore_hurtboxes() -> void:
	if active_set == "":
		push_warning("[HFD] No active_set selected")
		return
	if not hurtbox_sets.has(active_set):
		push_warning("[HFD] No hurtbox data for set '%s'" % active_set)
		return
	for child in get_children():
		if child is HurtboxDataObject: child.free()
	for entry : Dictionary in hurtbox_sets[active_set]:
		var obj : HurtboxDataObject = _make_hurtdo()
		obj.name        = entry.get("name", "HurtDO")
		obj.start_frame = entry.get("start_frame", -1)
		obj.end_frame   = entry.get("end_frame",   -1)
		_apply_entry_shape(obj, entry)
		add_child(obj)
		obj.owner = get_tree().edited_scene_root
	print("[HFD] Restored hurtboxes for set '%s'" % active_set)

func _restore_hitbox_backup() -> void:
	if hitbox_data_backup.is_empty():
		push_warning("[HFD] No hitbox backup found")
		return
	hitbox_data = hitbox_data_backup.duplicate(true)
	print("[HFD] Restored hitboxes from backup")

func _restore_hurtbox_backup() -> void:
	if hurtbox_sets_backup.is_empty():
		push_warning("[HFD] No hurtbox sets backup found")
		return
	hurtbox_sets = hurtbox_sets_backup.duplicate(true)
	print("[HFD] Restored hurtbox sets from backup")

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
	obj.start_frame = preview_frame
	obj.end_frame   = -1
	var rect        : RectangleShape2D = RectangleShape2D.new()
	rect.size       = Vector2(50.0, 50.0)
	obj.shape       = rect
	return obj

func _make_hurtdo() -> HurtboxDataObject:
	var obj         : HurtboxDataObject = HurtboxDataObject.new()
	obj.start_frame = preview_frame
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
			if idx > max_index: max_index = idx
	return max_index + 1
