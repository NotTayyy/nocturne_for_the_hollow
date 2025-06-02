extends Node2D

@export_enum("Kokonoe", "Byakuya", "Jin") var P1_Select: String
@export_enum("Kokonoe", "Byakuya", "Jin") var P2_Select: String

var game_manager: Node

var player1: Fighter
var player2: Fighter
const P1_START_POS := Vector2(200, 400)
const P2_START_POS := Vector2(600, 400)

func _ready() -> void:
	await get_tree().process_frame
	
	game_manager = get_parent()
	
	if P1_Select == P2_Select:
		print("Mirror Match")
	
	spawn_players()

func spawn_players():
	player1 = spawn_character(P1_Select, 1, P1_START_POS)
	player2 = spawn_character(P2_Select, 2, P2_START_POS)
	
	if player1 and player2:
		print("Character Manager Loaded!")
		player1.opponent = player2
		player2.opponent = player1
		
		if game_manager.camera_manager:
			print("Camera Found!")
			game_manager.camera_manager.set_targets(player1, player2)
		else:
			print("Cam Not Found")


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
	print("✅ Spawned %s as Player %d" % [data.character_name, player_id])
	
	return fighter
