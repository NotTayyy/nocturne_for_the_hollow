extends Control

@onready var slider = $CanvasLayer/VBoxContainer/HSlider

func _ready() -> void:
	Global.game_manager.change_Gamemode(Global.game_manager.GameState.OPTION_SELECT)
	slider.value = Global.Volume["master"]

func _on_h_slider_value_changed(value: int) -> void:
	Global.audio_manager.update_volume("master", value)

func _on_back_btn_pressed() -> void:
	Global.ui_manager.Change_Gui_scene("res://UI/Menu/Main_Menu/Menu/Main_menu.tscn")
