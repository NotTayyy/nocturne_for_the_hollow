extends Node2D

#There has to be a better way to Log all our Characters and Shit
@export var P1_Select: String
@export var P2_Select: String 

var game_manager: Node

var player1: Fighter
var player2: Fighter
const P1_START_POS := Vector2(-250, 400)
const P2_START_POS := Vector2(250, 400)

func _ready() -> void:
	await get_tree().process_frame
		
	game_manager = get_parent()
	G_Refrences.character_manager = self
	
	if not G_CharacterDB.get_data(P1_Select):
		push_warning("P1_Select invalid, defaulting to first character")
		P1_Select = G_CharacterDB.get_char_names()[1]
		
	if not G_CharacterDB.get_data(P2_Select):
		push_warning("P2_Select invalid, defaulting to second character")
		P2_Select = G_CharacterDB.get_char_names()[0]
		
	if P1_Select == P2_Select:
		print("Mirror Match") #Should Change Shader or skin or something
	
	spawn_players()

func spawn_players():
	player1 = spawn_character(P1_Select, 1, P1_START_POS)
	player2 = spawn_character(P2_Select, 2, P2_START_POS)
	
	if player1 and player2:
		if game_manager.Debug == true:
			print("Character Manager Loaded!")
		Opponent_Setup()
		
		
		if game_manager.camera_manager:
			if game_manager.Debug == true:
				print("Camera Found!")
		else:
			print("Cam Not Found")

func Opponent_Setup():
	#Easiest way to pass Opponent Data at the same time
		player1.opponent = player2
		player2.opponent = player1
		player1.enm_Collision = player2.collision_Box
		player2.enm_Collision = player1.collision_Box


func spawn_character(char_name: String, player_id: int, spawn_pos: Vector2) -> Fighter:
	var data: CharacterData = G_CharacterDB.get_data(char_name)
	if data == null:
		push_warning("Character data for '%s' not found!" % char_name)
		return
	
	var fighter = data.fighter_scene.instantiate()
	if fighter == null:
		push_error("Failed to instantiate fighter scene for '%s'" % char_name)
		return

	fighter.char_data = data
	fighter.player_id = player_id
	fighter.position = spawn_pos
	add_child(fighter)
	if game_manager.Debug == true:
		print("✅ Spawned %s as Player %d" % [data.character_name, player_id])
	
	return fighter
