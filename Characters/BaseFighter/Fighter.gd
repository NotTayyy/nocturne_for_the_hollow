extends CharacterBody2D
class_name Fighter

signal knocked_out

@export var player_id : int           = 1
@export var char_data : CharacterData

@onready var state_machine : State_Manager    = $Components/State_Manager
@onready var input_buffer  : InputBuffer      = $Components/InputBuffer
@onready var anim_player   : AnimationPlayer  = $Char_Sprite_Animator
@onready var char_sprite   : Sprite2D         = $Char_Sprite
@onready var pushbox       : Area2D           = $Components/Pushbox
@onready var collision_Box : CollisionShape2D = $Components/Pushbox/CollisionShape2D

# Blackboard
var opponent         : Fighter
var dir_facing       : String = "Right"
var is_airborne      : bool   = false
var is_on_wall_left  : bool   = false
var is_on_wall_right : bool   = false
var jumps_remaining  : int    = 0
var dashes_remaining : int    = 0
var facing_updated   : bool   = false

## All Active Properties
var properties : Array[Property] = []

# Input action strings — kept for any state that needs to query them directly
var move_left  : String
var move_right : String
var move_up    : String
var move_down  : String
var btn_a      : String
var btn_b      : String
var btn_c      : String
var btn_d      : String

func _ready() -> void:
	char_data.setup_char()
	_setup_input_actions()
	_setup_input_buffer()
	state_machine.initialise(self)
	char_data.health_depleted.connect(_on_health_depleted)
	anim_player.play("Idle/Idle")

func _physics_process(delta: float) -> void:
	update_facing()
	state_machine.tick(delta)
	_tick_properties()
	move_and_slide()
	_update_post_slide_flags()
	char_data.tick_grey_health_decay(delta, self)

# -----------------------------------------------------------------------------
# Facing
# -----------------------------------------------------------------------------
func update_facing() -> void:
	var target := "Right" if global_position.x <= opponent.global_position.x else "Left"
	if target == dir_facing or is_airborne or is_on_wall_left or is_on_wall_right:
		facing_updated = false
		return 
	dir_facing = target
	char_sprite.scale.x = 1.0 if dir_facing == "Right" else -1.0
	input_buffer.facing_right = (dir_facing == "Right")
	input_buffer.flip_held_directions()
	facing_updated = true
	return

# -----------------------------------------------------------------------------
# Post-slide flags
# -----------------------------------------------------------------------------
func _update_post_slide_flags() -> void:
	var on_floor := is_on_floor()
	is_airborne  = not on_floor
 
	if on_floor:
		remove_property(Property.Type.Airborne)
	else:
		if not has_property(Property.Type.Airborne):
			add_property(Property.new(Property.Type.Airborne, -1, "system"))
 
	is_on_wall_left  = false
	is_on_wall_right = false
	for i in get_slide_collision_count():
		var n := get_slide_collision(i).get_normal()
		if   n.x >  0.5: is_on_wall_left  = true
		elif n.x < -0.5: is_on_wall_right = true

# -----------------------------------------------------------------------------
# Helpers for states
# -----------------------------------------------------------------------------
func get_walk_speed(forward: bool) -> float:
	return char_data.fwd_walk_speed if forward else char_data.bwd_walk_speed

func is_aerial() -> bool:
	return is_airborne or has_property(Property.Type.PAirborne)

# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------
func _setup_input_actions() -> void:
	var p      := "P%d_" % player_id
	move_left  = p + "Left"
	move_right = p + "Right"
	move_up    = p + "Up"
	move_down  = p + "Down"
	btn_a      = p + "Btn_A"
	btn_b      = p + "Btn_B"
	btn_c      = p + "Btn_C"
	btn_d      = p + "Btn_D"

func _setup_input_buffer() -> void:
	input_buffer.character        = self
	input_buffer.facing_right     = (dir_facing == "Right")
	input_buffer.neg_edge_enabled = char_data.neg_edge
	input_buffer.setup_actions(player_id)
	input_buffer.set_commands(
		char_data.command_list.command_list,
		char_data.command_list.release_cmnd_list if char_data.neg_edge else []
	)

func _on_health_depleted() -> void:
	knocked_out.emit()

func notify_proximity_block(_in_range : bool) -> void:
	# Placeholder — wire to block state when built
	pass

func recieve_hit(result : HitResult) -> void:
	add_property(Property.new(Property.Type.Hitstun, result.hitstun, "system"))
	if result.pushback != 0.0 or result.air_pushback != 0.0:
		var dir : float = 1.0 if result.attacker.global_position.x < global_position.x else -1.0
		if is_airborne:
			velocity.x += result.pushback * dir
			velocity.y += result.air_pushback
		else:
			velocity.x += result.pushback * dir

func _is_actionable() -> bool:
	return not has_property(Property.Type.Hitstun)  \
		and not has_property(Property.Type.Blockstun) \
		and not has_property(Property.Type.Frozen)    \
		and not has_property(Property.Type.Stunned)

# =============================================================================
# Property system
# =============================================================================
 
## Add a property. Respects stacking and refresh rules.
func add_property(prop: Property) -> void:
	if not prop.does_stack:
		# Non-stacking — refresh duration if already exists, otherwise append
		for p in properties:
			if p.type == prop.type and p.sub_id == prop.sub_id:
				p.duration = prop.duration
				return
		properties.append(prop)
	else:
		# Stacking — refresh existing OR append new, not both
		if prop.refresh:
			for p in properties:
				if p.type == prop.type and p.sub_id == prop.sub_id:
					p.duration = prop.duration
					return
		properties.append(prop)
 
## Remove all instances of a property by type.
func remove_property(type: Property.Type, sub_id: String = "") -> void:
	properties = properties.filter(func(p): return not (p.type == type and p.sub_id == sub_id))
 
## True if any instance of this property is active.
func has_property(type: Property.Type, sub_id: String = "") -> bool:
	for p in properties:
		if p.type == type and p.sub_id == sub_id: return true
	return false
 
## Get first instance of a property, or null if not present.
func get_property(type: Property.Type, sub_id: String = "") -> Property:
	for p in properties:
		if p.type == type and p.sub_id == sub_id: return p
	return null
 
## Get all instances of a property (for stacking properties).
func get_properties(type: Property.Type, sub_id: String = "") -> Array[Property]:
	var result : Array[Property] = []
	for p in properties:
		if p.type == type and p.sub_id == sub_id: result.append(p)
	return result
 
## Tick all properties — removes expired ones each frame.
func _tick_properties() -> void:
	var i := properties.size() - 1
	while i >= 0:
		if properties[i].tick():
			properties.remove_at(i)
		i -= 1
