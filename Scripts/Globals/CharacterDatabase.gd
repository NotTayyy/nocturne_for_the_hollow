extends Node

var characters : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_characters()

func load_characters():
	characters["Kokonoe"] = preload("res://Characters/Tmp_Kokonoe/Data_Kokonoe.tres")
	characters["Byakuya"] = preload("res://Characters/Tmp_Byakuya/Data_Byakuya.tres")
	characters["Jin"] = preload("res://Characters/Tmp_Jin/Data_Jin.tres")

func get_char_names() -> PackedStringArray:
	return PackedStringArray(characters.keys())
	
func get_data(char_name: String) -> CharacterData:
	return characters.get(char_name)
