extends Control

func _on_single_player_pressed() -> void:
	Global.ui_manager.Change_Gui_scene("res://Levels/Training Level/Training_Level.tscn")

func _on_training_pressed() -> void:
	Global.ui_manager.Change_Gui_scene("res://UI/Menu/Main_Menu/Character_Select/Character_Select.tscn")


func _on_options_pressed() -> void:
	Global.ui_manager.Change_Gui_scene("res://UI/Menu/Main_Menu/Options/Options.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
