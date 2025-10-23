extends Control

@onready var BGM_Dropdown: OptionButton = $CanvasLayer/VBoxContainer/BGM_Select_drop
@onready var Bgm_List = Global.audio_manager.get_bgm_list("Match")
@onready var Cur_lev_lbl: Label = $HBoxContainer/Sel_Level_Label
@onready var game_manager = Global.game_manager
@onready var levels_data = G_LevelDB.get_level_names()
	
func _ready() -> void:
	game_manager.change_Gamemode(game_manager.GameState.LEVEL_SELECT)
	
	if Global.Level_Select == "":
		Cur_lev_lbl.text = "None"
	else:
		Cur_lev_lbl.text = Global.Level_Select
	
	for Bgm in Bgm_List:
		BGM_Dropdown.add_item(Bgm)

func _on_back_btn_pressed() -> void:
	Global.ui_manager.Change_Gui_scene("Character_Select")

func _on_training_room_pressed() -> void:
	Global.Level_Select = "training"
	Cur_lev_lbl.text = Global.Level_Select

func _on_verdant_room_pressed() -> void:
	Global.Level_Select = "verdant_forest"
	Cur_lev_lbl.text = Global.Level_Select

func _on_begin_btn_pressed() -> void:
	Global.game_manager.change_Gamemode(game_manager.GameState.MID_MATCH)
	Global.audio_manager.play_bgm("Match", BGM_Dropdown.get_item_text(BGM_Dropdown.selected))
