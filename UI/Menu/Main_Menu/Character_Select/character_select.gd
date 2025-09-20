extends Control

@onready var p1_dropdown = $CanvasLayer/P1_Char_select
@onready var p2_dropdown = $CanvasLayer/P2_Char_select
@onready var Characters = G_CharacterDB.get_char_names()


func _ready():
	for char_name in Characters:
		p1_dropdown.add_item(char_name)
		p2_dropdown.add_item(char_name)

func _on_quick_button_pressed() -> void:
	pass # Replace with function body.


func _on_level_select_pressed() -> void: ##
	Global.ui_manager.Change_Gui_scene("res://UI/Menu/Main_Menu/Level_Select/Levels.tscn")


func _on_back_btn_pressed() -> void:
	Global.ui_manager.Change_Gui_scene("res://UI/Menu/Main_Menu/Menu/Main_menu.tscn")
