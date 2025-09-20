extends Node

var levels : Dictionary = {}

func _ready() -> void:
	load_levels()

func load_levels():
	levels["training"] = {
		"scene": preload("res://Levels/Training Level/Training_Level.tscn"),
		"Thumbnail": preload("res://Levels/Training Level/Training_Level_thumb.jpg"),
		"description": "... The training room",
		"name": "Training"
		}
	levels["verdant_forest"] = {
		"scene": preload("res://Levels/Verdant Forest/Verdant_Forest.tscn"),
		"Thumbnail": preload("res://Levels/Verdant Forest/Verdant_Forest_Thumb.jpg"),
		"description": "A small forest where goblins and gremlins live",
		"name": "Verdant Forest"
	}

func get_level_names() -> PackedStringArray:
	return PackedStringArray(levels.keys())

func get_level_property(level: String, prop: String) -> Variant:
	if not levels.has(level):
		push_warning("Level %s not found!" % level)
		return null
	return levels[level].get(prop, null)
