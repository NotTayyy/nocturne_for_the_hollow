extends Control

#@onready var Training_label = $CanvasLayer/Training/Label
@onready var BGM_Dropdown= $CanvasLayer/BGM_Select_drop
@onready var Bgm_List = Global.audio_manager.get_bgm_list()

var tmp_selected_level: String = ""
var levels_data
var game_manager

func _ready() -> void:
	levels_data = G_LevelDB.get_level_names()
	print(levels_data)
	game_manager = Global.game_manager
	
	for Bgm in Bgm_List:
		BGM_Dropdown.add_item(Bgm)

func _physics_process(_delta: float) -> void:
	pass

func _on_back_btn_pressed() -> void:
	Global.ui_manager.Change_Gui_scene("res://UI/Menu/Main_Menu/Character_Select/Character_Select.tscn")

func _on_training_room_pressed() -> void:
	tmp_selected_level = "training"

func _on_verdant_room_pressed() -> void:
	tmp_selected_level = "verdant_forest"

func _on_begin_btn_pressed() -> void:
	if tmp_selected_level == "":
		return
	else:
		Global.Level_Select = tmp_selected_level
		Global.game_manager.change_Gamemode(game_manager.GameState.MID_MATCH)
		Global.audio_manager.play_bgm(BGM_Dropdown.get_item_text(BGM_Dropdown.selected))
