extends Node2D

@export_enum("Training Level") var Level_Select: String

var game_manager: Node

var Levels

func _ready() -> void:
	await get_tree().process_frame
	game_manager = get_parent()

	spawn_level(Level_Select)

func spawn_level(Level: String) -> void:
	pass
	#var data = CharacterDB.get_data(char_name)
