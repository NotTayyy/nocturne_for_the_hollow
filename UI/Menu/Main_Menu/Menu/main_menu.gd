extends Control

var game_manager

func _ready() -> void:
	game_manager = Global.game_manager

func _on_single_player_pressed() -> void:
	Global.Level_Select = " "
	Global.game_manager.change_Gamemode(game_manager.GameState.MID_MATCH)
	Global.audio_manager.play_bgm(Global.audio_manager.get_bgm_list()[0])

func _on_training_pressed() -> void:
	Global.ui_manager.Change_Gui_scene("res://UI/Menu/Main_Menu/Character_Select/Character_Select.tscn")


func _on_options_pressed() -> void:
	Global.ui_manager.Change_Gui_scene("res://UI/Menu/Main_Menu/Options/Options.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
