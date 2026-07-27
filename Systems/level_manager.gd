extends Node2D
class_name Level_Manager

var Levels = G_LevelDB.get_level_names()
var current_level: Node

func _ready() -> void:
	Global.level_manager = self

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Btn_Select"):
		get_tree().reload_current_scene()

func spawn_level(Level: String) -> void:
	if current_level: 
		current_level.queue_free()
	
	var scene = G_LevelDB.get_level_property(Level, "scene")
	if scene:
		current_level = scene.instantiate()
		add_child(current_level)
	else:
		push_warning("Level %s not found in LevelDatabase" % Level)

func Change_Level_scene(new_scene, delete: bool = true, keep_running: bool = false) -> void:
	if current_level != null:
		if delete:
			current_level.queue_free()
		elif keep_running:
			current_level.visible = false
		else:
			remove_child(current_level)
	
	var scene: PackedScene = G_LevelDB.get_level_property(new_scene, "scene")
	if scene == null: #If level is no selected, 
		if Global.game_manager.Debug == true:
			push_warning("Level not selected, defaulting to first Level")# Return the First level
		scene = G_LevelDB.get_level_property(G_LevelDB.get_level_names()[0], "scene")
	
	current_level = scene.instantiate()
	add_child(current_level)
