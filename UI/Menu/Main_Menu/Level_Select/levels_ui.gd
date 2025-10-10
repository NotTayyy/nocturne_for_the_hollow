extends Control

@onready var BGM_Dropdown: OptionButton = $CanvasLayer/VBoxContainer/BGM_Select_drop
@onready var Bgm_List = Global.audio_manager.get_bgm_list("Match")
@onready var Cur_lev_lbl: Label = $HBoxContainer/Sel_Level_Label

var levels_data
var game_manager

func _ready() -> void:
	game_manager = Global.game_manager
	game_manager.change_Gamemode(game_manager.GameState.LEVEL_SELECT)
	levels_data = G_LevelDB.get_level_names()
	
	if Global.Level_Select == "":
		Cur_lev_lbl.text = "None"
	else:
		Cur_lev_lbl.text = Global.Level_Select
	
	print(levels_data)
	
	for Bgm in Bgm_List:
		BGM_Dropdown.add_item(Bgm)

func _physics_process(_delta: float) -> void:
	pass

func _on_back_btn_pressed() -> void:
	Global.ui_manager.Change_Gui_scene("res://UI/Menu/Main_Menu/Character_Select/Character_Select.tscn")

func _on_training_room_pressed() -> void:
	Global.Level_Select = "training"
	Cur_lev_lbl.text = Global.Level_Select

func _on_verdant_room_pressed() -> void:
	Global.Level_Select = "verdant_forest"
	Cur_lev_lbl.text = Global.Level_Select

func _on_begin_btn_pressed() -> void:
	Global.game_manager.change_Gamemode(game_manager.GameState.MID_MATCH)
	Global.audio_manager.play_bgm("Match", BGM_Dropdown.get_item_text(BGM_Dropdown.selected))
