extends Control

func _ready() -> void:
	Global.game_manager.change_Gamemode(Global.game_manager.GameState.MAIN_MENU)

func _on_single_player_pressed() -> void:
	Global.Level_Select = ""
	Global.P1_Select = "Kagura"
	Global.P2_Select = "Kagura"
	Global.game_manager.change_Gamemode(Global.game_manager.GameState.MID_MATCH)
	Global.audio_manager.play_rndm_bgm("Match")

func _on_training_pressed() -> void:
	Global.ui_manager.Change_Gui_scene("Character_Select")

func _on_options_pressed() -> void:
	Global.ui_manager.Change_Gui_scene("MM_Options")

func _on_exit_pressed() -> void:
	get_tree().quit()
