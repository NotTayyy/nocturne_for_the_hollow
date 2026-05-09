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

# Input action strings
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
	anim_player.play("Idle")

func _physics_process(delta: float) -> void:
	update_facing()
	_stage_input()
	state_machine.tick(delta)
	_tick_properties()
	move_and_slide()
	_update_post_slide_flags()

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
# Input staging — collect raw hardware inputs, pass to InputBuffer
# Does NOT run command matching — that happens in State_Manager.tick()
# -----------------------------------------------------------------------------
func _stage_input() -> void:
	var current_directions : Array = []
	for action in [move_left, move_right, move_up, move_down]:
		if Input.is_action_pressed(action):
			current_directions.append(action)

	# Direction just pressed — release previous, press new
	for action in [move_left, move_right, move_up, move_down]:
		if Input.is_action_just_pressed(action):
			var prev := _held_to_numpad(current_directions.filter(func(a): return a != action))
			var curr := _held_to_numpad(current_directions)
			if prev != curr:
				input_buffer.stage(prev, "release")
			input_buffer.stage(curr, "press")
			break

	# Direction just released — release it, re-register what remains
	for action in [move_left, move_right, move_up, move_down]:
		if Input.is_action_just_released(action):
			var released_dir := _held_to_numpad([action])
			if released_dir != "":
				input_buffer.stage(released_dir, "release")
			current_directions = []
			for a in [move_left, move_right, move_up, move_down]:
				if Input.is_action_pressed(a):
					current_directions.append(a)
			var remaining := _held_to_numpad(current_directions)
			input_buffer.stage(remaining, "press")
			break

	# Buttons — each independent
	for pair in [[btn_a,"A"],[btn_b,"B"],[btn_c,"C"],[btn_d,"D"]]:
		if   Input.is_action_just_pressed(pair[0]):
			input_buffer.stage(pair[1], "press")
		elif Input.is_action_just_released(pair[0]):
			input_buffer.stage(pair[1], "release")

func _held_to_numpad(held: Array) -> String:
	var v := ""
	var h := ""

	if move_up in held and move_down in held:
		v = ""
	elif move_up in held:
		v = "8"
	elif move_down in held:
		v = "2"

	if move_left in held and move_right in held:
		h = ""
	elif dir_facing == "Right":
		if   move_left  in held: h = "4"
		elif move_right in held: h = "6"
	else:
		if   move_left  in held: h = "6"
		elif move_right in held: h = "4"

	if   v == "8" and h == "4": return "7"
	elif v == "8" and h == "6": return "9"
	elif v == "2" and h == "4": return "1"
	elif v == "2" and h == "6": return "3"
	elif v != "":                return v
	elif h != "":                return h
	return "5"

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
	input_buffer.set_commands(
		char_data.command_list.command_list,
		char_data.command_list.release_cmnd_list if char_data.neg_edge else []
	)

func _on_health_depleted() -> void:
	knocked_out.emit()

# =============================================================================
# Property system
# =============================================================================
 
## Add a property. Respects stacking and refresh rules.
func add_property(prop: Property) -> void:
	if not prop.does_stack:
		for p in properties:
			if p.type == prop.type and p.sub_id == prop.sub_id:
				p.duration = prop.duration
				return
		properties.append(prop)
	else:
		if prop.refresh:
			for p in properties:
				if p.type == prop.type and p.sub_id == prop.sub_id:
					p.duration = prop.duration
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
