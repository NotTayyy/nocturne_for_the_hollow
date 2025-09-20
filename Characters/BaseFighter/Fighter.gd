extends CharacterBody2D
class_name Fighter

@export_range(0, 2, 1) var player_id: int = 0
@onready var input_buffer: InputBuffer = %InputBuffer
@onready var collision_Box: CollisionShape2D = $Collision_Box
@onready var Anim_Player: AnimationPlayer = $AnimationPlayer
@onready var game_manager: Node = Global.game_manager
@onready var char_sprite: Node2D = $Char_Sprite

var char_data: CharacterData
var cmd_data: CommandData
var dir_facing: String
var last_facing: String

var enm_Collision: CollisionShape2D
var opponent: Fighter

@export var right_limit: int = 2080
@export var left_limit: int = -2080


#region State Tracking
var was_idle: bool = false
var prejump_timer: int = -1 #Remove Eventually
var move_dir: float = 0
var is_airborn: bool = false
#endregion

#region Controls
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

func _ready() -> void:
	if not char_data:
		push_error("Missing CharacterData!")
		return
	
	input_buffer.has_neg_edge = char_data.neg_edge
	input_buffer.command_list = char_data.command_list.command_list
	
	if char_data.neg_edge != false:
		input_buffer.release_command_list = char_data.command_list.relese_cmnd_list
	
	setup_input_actions()
	
	if player_id == 1:
		Global.P1 = self
	else:
		Global.P2 = self

func setup_input_actions() -> void:
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
	await get_tree().process_frame
	if not char_data:
		return
		
	#This is Fine For the most part, Might make it cleaner
	dir_facing = get_facing_dir() 
	handle_horizontal_movement(delta)
	##This should be Under Input Buffer in the Future, Its own State
	handle_jump_logic()
	## This Should be controlled by States, is_Airborn turned on and off in the state exit and enter Thus making gravity turn on and Off
	handle_gravity(delta)
	capture_input()
	move_and_slide()
	push_if_overlapping()
	
	if Input.is_action_just_pressed("Btn_Exit"):
		get_tree().quit()
		
func push_if_overlapping() -> void:
	var my_rect: Rect2 = Rect2(collision_Box.global_position - collision_Box.shape.extents, collision_Box.shape.extents * 2)
	var enemy_rect: Rect2 =  Rect2(enm_Collision.global_position - enm_Collision.shape.extents, enm_Collision.shape.extents * 2)
	
	##Problem: Bandaid on Stealing corner, Really Fix in the Future.
	##Make the Overlap move the players more, Its too slow walking from one corner to the other
	if my_rect.intersects(enemy_rect):
		var overlap = my_rect.intersection(enemy_rect)
		if overlap.size.x < overlap.size.y:
			var push_distance = overlap.size.x / 2
			if my_rect.position.x < enemy_rect.position.x:
				global_position.x = global_position.x - push_distance
			else:
				global_position.x = global_position.x + push_distance

func get_facing_dir() -> String:
	var dir: String
	
	dir = "Left" if self.global_position.x > opponent.global_position.x else "Right"
	if dir != dir_facing:
		if dir == "Right":
			char_sprite.scale.x = 1
		else:
			char_sprite.scale.x = -1
	
	return dir

func flip_sprite(_dir: String) -> void:
	pass

func get_move_speed(dir: float) -> float:
	##This Sprinting Stuff is Temportary, Will be removed in place of a State in the Future
	if dir_facing == "Right":
		return char_data.bwd_walk_speed if  dir == -1 else char_data.fwd_walk_speed
	else: # facing Left
		return char_data.fwd_walk_speed if dir == -1 else char_data.bwd_walk_speed

func capture_input() -> void:
	var current_directions := []
	var released_directions := []
	
	# Re Collect current held directions
	for action in [move_left, move_right, move_up, move_down]:
		if Input.is_action_pressed(action):
			current_directions.append(action)
	
	# Add Direction Just Pressed
	for action in [move_left, move_right, move_up, move_down]:
		if Input.is_action_just_pressed(action):
			var prev_direction = parse_direction(current_directions.filter(func(a): return a != action))
			var new_direction = parse_direction(current_directions)
			
			if was_idle:
				was_idle = false
			
			if prev_direction != "" and prev_direction != new_direction:
				input_buffer.register_input(prev_direction, "release")
			
			if new_direction != "":
				input_buffer.register_input(new_direction, "press")
			break  # One press is enough
	
	# Collect Direction Just Released
	for action in [move_left, move_right, move_up, move_down]:
		if Input.is_action_just_released(action):
			released_directions.append(action)
	
	#Delete Released Directions
	if released_directions.size() > 0:
		var release_dir = parse_direction(released_directions)
		if release_dir != "":
			input_buffer.register_input(release_dir, "release")
	
		# Re-evaluate what's currently being held
		current_directions.clear()
		for action in [move_left, move_right, move_up, move_down]:
			if Input.is_action_pressed(action):
				current_directions.append(action)
		var new_direction = parse_direction(current_directions)
		if new_direction != "":
			input_buffer.register_input(new_direction, "press")
	
	# Detect return to neutral (idle)
	if current_directions.size() == 0 and not was_idle:
		was_idle = true
	
	# Button inputs
	for action in [btn_a, btn_b, btn_c, btn_d]:
		var btn = parse_buttons(action)
		if Input.is_action_just_pressed(action):
			input_buffer.register_input(btn, "press")
		elif Input.is_action_just_released(action):
			input_buffer.register_input(btn, "release")

func parse_buttons(button: String) -> String:
	match button:
		btn_a:
			return "A"
		btn_b:
			return "B"
		btn_c:
			return "C"
		btn_d:
			return "D"
		_:
			return ""

func parse_direction(held: Array) -> String:
	var vertical : String = ""
	var horizontal : String = ""

	# Cancel opposing vertical inputs
	if move_up in held and move_down in held:
		vertical = ""
	elif move_up in held:
		vertical = "8"
	elif move_down in held:
		vertical = "2"

	# Cancel opposing horizontal inputs
	if dir_facing == "Left":
		if move_left in held and move_right in held:
			horizontal = ""
		elif move_left in held:
			horizontal = "6"
		elif move_right in held:
			horizontal = "4"
	else:
		if move_left in held and move_right in held:
			horizontal = ""
		elif move_left in held:
			horizontal = "4"
		elif move_right in held:
			horizontal = "6"

	# Combine if both are valid
	if vertical != "" and horizontal != "":
		if vertical == "8" and horizontal == "4":
			return "7"
		elif vertical == "8" and horizontal == "6":
			return "9"
		elif vertical == "2" and horizontal == "4":
			return "1"
		elif vertical == "2" and horizontal == "6":
			return "3"
	elif vertical != "":
		return vertical
	elif horizontal != "":
		return horizontal
		
	return "5"

func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += char_data.gravity * delta

func handle_jump_logic() -> void:
	if prejump_timer > 0:
		prejump_timer -= 1
		
		if Input.is_action_just_pressed(move_down):
			prejump_timer = -1
			
			
		elif prejump_timer == 0:
			velocity.y = char_data.jump_velocity
	
	elif Input.is_action_just_pressed(move_up):
		prejump_timer = char_data.prejump

func handle_horizontal_movement(_delta: float) -> void:
	move_dir = Input.get_axis(move_left, move_right)
	if move_dir != 0:
		velocity.x = move_dir * get_move_speed(move_dir)
	else:
		velocity.x = 0
