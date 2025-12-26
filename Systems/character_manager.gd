extends Node2D

var player1: Fighter
var player2: Fighter
var game_manager

const P1_START_POS : Vector2 = Vector2(-250, 400)
const P2_START_POS : Vector2 = Vector2(250, 400)

func _ready() -> void:
	await get_tree().process_frame
	game_manager = get_parent()
	
	Global.character_manager = self
	
	if Global.game_manager.Debug == true:
		print("Character Manager Loaded!")
		if Global.camera_manager:
			print("Camera Found!")
		else:
			print("Cam Not Found")

func game_start() -> void: #Call this To Spawn the Characters
	var P1_Select = Global.P1_Select
	var P2_Select = Global.P2_Select
	
	if not G_CharacterDB.get_data(P1_Select):
		push_warning("P1_Select invalid, defaulting to first character")
		P1_Select = G_CharacterDB.get_char_names()[1]
		
	if not G_CharacterDB.get_data(P2_Select):
		push_warning("P2_Select invalid, defaulting to second character")
		P2_Select = G_CharacterDB.get_char_names()[0]
	
	if P1_Select == P2_Select:
		print("Mirror Match") #Should Change Shader or skin or something
	
	player1 = spawn_character(P1_Select, 1, P1_START_POS)
	player2 = spawn_character(P2_Select, 2, P2_START_POS)
	
	Opponent_Setup()

func spawn_character(char_name: String, player_id: int, spawn_pos: Vector2) -> Fighter:
	var data: CharacterData = G_CharacterDB.get_data(char_name)
	if data == null:
		push_warning("Character data for '%s' not found!" % char_name)
		return
	
	var fighter = data.fighter_scene.instantiate()
	if fighter == null:
		push_error("Failed to instantiate fighter scene for '%s'" % char_name)
		return
	
	if player_id == 1:
		Global.P1 = fighter
	else:
		Global.P2 = fighter
	
	fighter.char_data = data
	fighter.player_id = player_id
	fighter.position = spawn_pos
	add_child(fighter)
	if Global.game_manager.Debug == true:
		print("✅ Spawned %s as Player %d" % [data.character_name, player_id])
	
	return fighter

func Opponent_Setup() -> void:
	#Easiest way to pass Opponent Data at the same time
		player1.opponent = player2
		player2.opponent = player1
		player1.pushbox.enemy_collision = player2.collision_Box
		player2.pushbox.enemy_collision = player1.collision_Box
