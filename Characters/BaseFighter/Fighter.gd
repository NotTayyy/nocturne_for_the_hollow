extends CharacterBody2D
class_name Fighter

signal knocked_out

@export var player_id : int           = 0
@export var char_data : CharacterData

@onready var state_manager : State_Manager   = $Components/State_Manager
@onready var input_buffer  : InputBuffer     = $Components/InputBuffer
@onready var anim_player   : AnimationPlayer = $Char_Sprite_Animator
@onready var char_sprite   : Node2D          = $Char_Sprite
@onready var pushbox       : Area2D          = $Components/Pushbox
@onready var collision_Box : CollisionShape2D = $Components/Pushbox/CollisionShape2D

var opponent         : Fighter
var dir_facing       : String = "Right"
var is_airborne      : bool   = false
var is_on_Wall_Left  : bool   = false
var is_on_Wall_Right : bool   = false

var move_left  : String
var move_right : String
var move_up    : String
var move_down  : String
var btn_a      : String
var btn_b      : String
var btn_c      : String
var btn_d      : String

const BUTTON_MAP : Dictionary = {
	"btn_a": "A", "btn_b": "B", "btn_c": "C", "btn_d": "D"
}

func _ready() -> void:
	char_data.setup_char()
	_setup_input_actions()
	_setup_input_buffer()
	state_manager.initialise(self)
	char_data.health_depleted.connect(_on_health_depleted)

# -----------------------------------------------------------------------------
# Main loop
# -----------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	_update_facing()
	_capture_input()
	state_manager.tick(delta)
	move_and_slide()
	_update_post_slide_flags()

# -----------------------------------------------------------------------------
# Facing
# -----------------------------------------------------------------------------
func update_facing() -> void:
	if is_airborne or is_on_Wall_Left or is_on_Wall_Right:
		return
	_update_facing()

func _update_facing() -> void:
	var target := "Right" if global_position.x <= opponent.global_position.x else "Left"
	if target == dir_facing:
		return
	dir_facing = target
	char_sprite.scale.x = 1.0 if dir_facing == "Right" else -1.0
	input_buffer.facing_right = (dir_facing == "Right")
	input_buffer.flip_held_directions()

# -----------------------------------------------------------------------------
# Input capture
# -----------------------------------------------------------------------------
func _capture_input() -> void:
	var current_directions : Array = []

	for action in [move_left, move_right, move_up, move_down]:
		if Input.is_action_pressed(action):
			current_directions.append(action)

	# Direction just pressed — register previous direction as release, new as press
	for action in [move_left, move_right, move_up, move_down]:
		if Input.is_action_just_pressed(action):
			var prev := _held_to_numpad(current_directions.filter(func(a): return a != action))
			var curr := _held_to_numpad(current_directions)
			if prev != curr:
				input_buffer.register_input(prev, "release")
			input_buffer.register_input(curr, "press")
			break  # one directional press per frame

	# Direction just released — register release, then re-register what remains
	for action in [move_left, move_right, move_up, move_down]:
		if Input.is_action_just_released(action):
			var released_dir := _held_to_numpad([action])
			if released_dir != "":
				input_buffer.register_input(released_dir, "release")

			current_directions = []
			for a in [move_left, move_right, move_up, move_down]:
				if Input.is_action_pressed(a):
					current_directions.append(a)

			var remaining := _held_to_numpad(current_directions)
			input_buffer.register_input(remaining, "press")
			break  # one release per frame

	# Buttons
	for pair in [[btn_a,"A"],[btn_b,"B"],[btn_c,"C"],[btn_d,"D"]]:
		if   Input.is_action_just_pressed(pair[0]):
			input_buffer.register_input(pair[1], "press")
		elif Input.is_action_just_released(pair[0]):
			input_buffer.register_input(pair[1], "release")

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
		if move_left  in held: h = "4"
		elif move_right in held: h = "6"
	else:
		if move_left  in held: h = "6"
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
	is_airborne      = not is_on_floor()
	is_on_Wall_Left  = false
	is_on_Wall_Right = false
	for i in get_slide_collision_count():
		var n := get_slide_collision(i).get_normal()
		if   n.x >  0.5: is_on_Wall_Left  = true
		elif n.x < -0.5: is_on_Wall_Right = true

# -----------------------------------------------------------------------------
# Helpers for states
# -----------------------------------------------------------------------------
func get_walk_speed(forward: bool) -> float:
	return char_data.fwd_walk_speed if forward else char_data.bwd_walk_speed

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

# -----------------------------------------------------------------------------
# Callbacks
# -----------------------------------------------------------------------------
func _on_health_depleted() -> void:
	knocked_out.emit()
