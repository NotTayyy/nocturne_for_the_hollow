extends CharacterBody2D
class_name Fighter

@export_range(0, 2) var player_id: int = 0
var opponent: Fighter = null

var char_data: CharacterData

@export_enum("Left", "Right") var dir_facing: String

@onready var input_buffer := %InputBuffer

var move_left: String
var move_right: String
var move_up: String
var move_down: String
var exit: String
var menu: String
var btn_a: String
var btn_b: String
var btn_c: String
var btn_d: String
var debug: String

# State tracking
var is_running: bool = false
var is_jumping: bool = false
var prejump_timer: int = 0
var move_dir: float = 0.0

func _ready() -> void:
	if not char_data:
		push_error("Missing CharacterData!")
		return
		
	setup_input_actions()

func get_move_speed() -> float:
	return char_data.fwd_walk_speed

func _capture_input():
	var direction_changed : bool = false
	var held_directions = []
		
	for action in [move_left, move_right, move_up, move_down]:
		if Input.is_action_just_pressed(action) or Input.is_action_just_released(action):
			for actions in [move_left, move_right, move_up, move_down]:
				if Input.is_action_pressed(actions):
					held_directions.append(actions)
				if Input.is_action_just_released(actions):
					input_buffer.register_input(actions, "release")
		
	if direction_changed:
		for action in [move_left, move_right, move_up, move_down]:
			if Input.is_action_pressed(action):
				held_directions.append(action)
			if Input.is_action_just_released(action):
				input_buffer.register_input(action, "release")
				
	var direction = parse_direction(held_directions)
	if direction != "":
		input_buffer.register_input(direction, "press")
		
	for action in [btn_a, btn_b, btn_c, btn_d]:
		if Input.is_action_just_pressed(action):
			input_buffer.register_input(action, "press")
		elif Input.is_action_just_released(action):
			input_buffer.register_input(action, "release")

func parse_direction(held: Array) -> String:
	var vertical := ""
	var horizontal := ""

	# Cancel opposing vertical inputs
	if move_up in held and move_down in held:
		vertical = ""
	elif move_up in held:
		vertical = move_up
	elif move_down in held:
		vertical = move_down

	# Cancel opposing horizontal inputs
	if move_left in held and move_right in held:
		horizontal = ""
	elif move_left in held:
		horizontal = move_left
	elif move_right in held:
		horizontal = move_right

	# Combine if both are valid
	if vertical != "" and horizontal != "":
		return vertical + "-" + horizontal
	elif vertical != "":
		return vertical
	elif horizontal != "":
		return horizontal
	else:
		return ""

func setup_input_actions():
	match player_id:
		1:
			move_left = "P1_Left"
			move_right = "P1_Right"
			move_up = "P1_Up"
			move_down = "P1_Down"
			btn_a = "P1_Btn_A"
			btn_b = "P1_Btn_B"
			btn_c = "P1_Btn_C"
			btn_d = "P1_Btn_D"
		2:
			move_left = "P2_Left"
			move_right = "P2_Right"
			move_up = "P2_Up"
			move_down = "P2_Down"
			btn_a = "P2_Btn_A"
			btn_b = "P2_Btn_B"
			btn_c = "P2_Btn_C"
			btn_d = "P2_Btn_D"
		_:
			push_warning("Unhandled player_id: %d" % player_id)

func _physics_process(delta: float) -> void:
	if not char_data:
		return
	if self.global_position.x > opponent.global_position.x:
		dir_facing = "Left"
	else:
		dir_facing = "Right"
	
	_capture_input()
	handle_horizontal_movement(delta)
	handle_jump_logic()
	handle_gravity(delta)
	move_and_slide()
	
	if Input.is_action_just_pressed("Btn_Exit"):
		get_tree().quit()

func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += char_data.gravity * delta

func handle_jump_logic() -> void:
	if prejump_timer > 0:
		prejump_timer -= 1

		if Input.is_action_just_pressed(move_down):
			prejump_timer = -1
			print("⬇️ Jump canceled")

		elif prejump_timer == 0:
			velocity.y = char_data.jump_velocity

	elif Input.is_action_just_pressed(move_up) and is_on_floor():
		prejump_timer = char_data.prejump

func handle_horizontal_movement(_delta: float) -> void:
	move_dir = Input.get_axis(move_left, move_right)

	if move_dir != 0:
		velocity.x = move_dir * get_move_speed()
	else:
		velocity.x = 0
