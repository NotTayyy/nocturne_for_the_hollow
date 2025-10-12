extends Control

@onready var p1_dropdown = $CanvasLayer/P1_Char_select
@onready var p2_dropdown = $CanvasLayer/P2_Char_select
@onready var Characters = G_CharacterDB.get_char_names()

func _ready():
	Global.game_manager.change_Gamemode(Global.game_manager.GameState.CHAR_SELECT)
	
	for char_name in Characters:
		p1_dropdown.add_item(char_name)
		p2_dropdown.add_item(char_name)
	
	if Global.P1_Select != "" and Global.P1_Select in Characters:
		var idx := Characters.find(Global.P1_Select)
		p1_dropdown.select(idx)
	else:
		p1_dropdown.select(0)
		Global.P1_Select = p1_dropdown.get_item_text(0)
	
	if Global.P2_Select != "" and Global.P2_Select in Characters:
		var idx := Characters.find(Global.P2_Select)
		p2_dropdown.select(idx)
	else:
		p2_dropdown.select(1)
		Global.P2_Select = p2_dropdown.get_item_text(1)

func _on_level_select_pressed() -> void:
	print("P1: ", Global.P1_Select, " / ", "P2: ", Global.P2_Select)
	Global.ui_manager.Change_Gui_scene("Level_Select")

func _on_back_btn_pressed() -> void:
	Global.ui_manager.Change_Gui_scene("Main_menu")

func _on_p_2_char_select_item_selected(index) -> void:
	Global.P2_Select = p2_dropdown.get_item_text(index)

func _on_p_1_char_select_item_selected(index: int) -> void:
	Global.P1_Select = p1_dropdown.get_item_text(index)
