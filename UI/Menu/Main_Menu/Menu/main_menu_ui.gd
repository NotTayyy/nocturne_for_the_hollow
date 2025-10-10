extends Control

func _ready() -> void:
	Global.game_manager.change_Gamemode(Global.game_manager.GameState.MAIN_MENU)

func _on_single_player_pressed() -> void:
	Global.Level_Select = ""
	Global.P1_Select = "Byakuya"
	Global.P2_Select = "Kokonoe"
	Global.game_manager.change_Gamemode(Global.game_manager.GameState.MID_MATCH)
	Global.audio_manager.play_rndm_bgm("Match")

func _on_training_pressed() -> void:
	Global.ui_manager.Change_Gui_scene("res://UI/Menu/Main_Menu/Character_Select/Character_Select.tscn")

func _on_options_pressed() -> void:
	Global.ui_manager.Change_Gui_scene("res://UI/Menu/Main_Menu/Options/Options.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
