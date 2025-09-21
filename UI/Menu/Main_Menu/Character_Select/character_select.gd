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

func _on_level_select_pressed() -> void:
	Global.P1_Select = p1_dropdown.get_item_text(p1_dropdown.selected)
	Global.P2_Select = p2_dropdown.get_item_text(p2_dropdown.selected)
	print("P1: ", p1_dropdown.get_item_text(p1_dropdown.selected), " / ", "P2: ", p2_dropdown.get_item_text(p2_dropdown.selected))
	Global.ui_manager.Change_Gui_scene("res://UI/Menu/Main_Menu/Level_Select/Level_select.tscn")

func _on_back_btn_pressed() -> void:
	Global.ui_manager.Change_Gui_scene("res://UI/Menu/Main_Menu/Menu/Main_menu.tscn")
