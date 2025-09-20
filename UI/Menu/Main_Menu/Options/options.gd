extends Control

@onready var slider = $CanvasLayer/HSlider

func _ready() -> void:
	Global.Volume = Global.audio_manager.Volume
	slider.value = Global.Volume

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_h_slider_value_changed(value: int) -> void:
	Global.audio_manager.update_volume(value)
	Global.Volume = value

func _on_back_btn_pressed() -> void:
	Global.ui_manager.Change_Gui_scene("res://UI/Menu/Main_Menu/Menu/Main_menu.tscn")
