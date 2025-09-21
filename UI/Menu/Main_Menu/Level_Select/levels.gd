extends Control

@onready var Training_label = $CanvasLayer/Training/Label

var tmp_selected_level: String = ""
var levels_data
var game_manager

func _ready() -> void:
	levels_data = G_LevelDB.get_level_names()
	print(levels_data)
	game_manager = Global.game_manager
	pass

func _physics_process(_delta: float) -> void:
	pass


func _on_back_btn_pressed() -> void:
	Global.ui_manager.Change_Gui_scene("res://UI/Menu/Main_Menu/Character_Select/Character_Select.tscn")

func _on_training_room_pressed() -> void:
	tmp_selected_level = "training"

func _on_verdant_room_pressed() -> void:
	tmp_selected_level = "verdant_forest"

func _on_begin_btn_pressed() -> void:
	if tmp_selected_level == "":
		print("No Selected Level")
		return
	else:
		print(tmp_selected_level)
		Global.Level_Select = tmp_selected_level
		Global.game_manager.change_Gamemode(game_manager.GameState.MID_MATCH)
