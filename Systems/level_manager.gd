extends Node2D

var game_manager: Node
var Levels = G_LevelDB.get_level_names()
var current_level: Node

func _ready() -> void:
	Global.level_manager = self
	await get_tree().process_frame
	game_manager = get_parent()


func spawn_level(Level: String) -> void:
	if current_level:
		current_level.queue_free()
	
	var scene = G_LevelDB.get_level_property("verdant_forest", "scene")
	if scene:
		current_level = scene.instantiate()
		add_child(current_level)
	else:
		push_warning("Level %s not found in LevelDatabase" % Level)
