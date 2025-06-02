extends Node

var levels := {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_levels()

func load_levels():
	levels["Training Room"] = preload("res://Levels/Test Level/test_level.tscn")

func get_character_names() -> PackedStringArray:
	return levels.keys()
	
func get_data(level: String) -> CharacterData:
	return levels.get(level)
