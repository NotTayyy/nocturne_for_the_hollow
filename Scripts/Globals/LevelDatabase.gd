extends Node

var levels : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_levels()

func load_levels():
	levels["Training Level"] = preload("res://Levels/Training Level/Training_Level.tscn")

func get_level_names() -> Array:
	return levels.keys()
	
func get_level_scene(level: String) -> PackedScene:
	return levels.get(level, null)
