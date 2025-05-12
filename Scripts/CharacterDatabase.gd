extends Node

var characters := {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_characters()


func load_characters():
	characters["Kokonoe"] = preload("res://Characters/Tmp_Kokonoe/Data_Kokonoe.tres")
	characters["Byakuya"] = preload("res://Characters/Tmp_Byakuya/Data_Byakuya.tres")

func get_character_names() -> PackedStringArray:
	return characters.keys()
	
func get_data(name: String) -> CharacterData:
	return characters.get(name)
	
func get_fighter_scene(name: String) -> PackedScene:
	return get_data(name).fighter_scene
