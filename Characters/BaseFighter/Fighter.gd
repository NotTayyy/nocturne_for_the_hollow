extends CharacterBody2D
class_name Fighter

@export_range(0, 2) var player_id: int = 0
var char_data: CharacterData
var opponent: Fighter = null

#region Input Actions 
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
#endregion

# State tracking
var is_running: bool = false
var is_jumping: bool = false
var prejump_timer: int = 0
var move_dir: float = 0.0

func get_move_speed() -> float:
	return char_data.fwd_walk_speed

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

func _ready() -> void:
	if not char_data:
		push_error("Missing CharacterData!")
		return
		
	setup_input_actions()

func _physics_process(delta: float) -> void:
	if not char_data:
		return

	handle_gravity(delta)
	handle_jump_logic()
	handle_horizontal_movement(delta)

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
			is_jumping = true

	elif Input.is_action_just_pressed(move_up) and is_on_floor():
		prejump_timer = char_data.prejump

func handle_horizontal_movement(delta: float) -> void:
	move_dir = Input.get_axis(move_left, move_right)

	if move_dir != 0:
		velocity.x = move_dir * get_move_speed()
	else:
		velocity.x = 0
