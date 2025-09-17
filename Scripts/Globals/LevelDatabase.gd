extends Node

var levels : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_levels()

func load_levels():
	levels["training"] = {
		"scene": preload("res://Levels/Training Level/Training_Level.tscn"),
		"Thumbnail": null,
		"description": "... The training room",
		"name": "Training"
		}
	levels["verdant_forest"] = {
		"scene": preload("res://Levels/Verdant Forest/Verdant_Forest.tscn"),
		"Thumbnail": null,
		"description": "A small forest where goblins and gremlins live",
		"name": "Verdant Forest"
	}

func get_level_names() -> PackedStringArray:
	return PackedStringArray(levels.keys())
	
func get_level_scene(level: String) -> PackedScene:
	return levels.get(level, {}).get("scene", null)
