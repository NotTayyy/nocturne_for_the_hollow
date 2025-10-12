extends Node

@export var Debug: bool = false

@onready var camera_manager: Node2D = $Camera_Manager
@onready var audio_manager: Node2D = $Audio_Manager
@onready var character_manager: Node2D = $Character_Manager
@onready var level_manager: Node2D = $Level_Manager
@onready var ui_manager: Node2D = $Ui_Manager

enum GameState { LOADING, MAIN_MENU, CHAR_SELECT, LEVEL_SELECT, MID_MATCH, PAUSE, OPTION_SELECT }
var current_state: GameState

func _ready() -> void:
	#Load Everything
	change_Gamemode(GameState.LOADING)
	Global.game_manager = self
	var all_good: bool = true
	for m in [character_manager, camera_manager, audio_manager, level_manager, ui_manager]:
		if m == null:
			push_error("GameManager: " + str(m) + " is missing!")
			all_good = false
	if all_good and Debug == true:
		print("Managers Loaded!")
	await get_tree().physics_frame
	#When Everything Is Loaded
	randomize()
	change_Gamemode(GameState.MAIN_MENU)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Toggle_Debug"):
		Debug = not Debug
		print("Debug Mode: ", Debug)
	if event.is_action_pressed("Btn_Select"):
		get_tree().reload_current_scene()
	if event.is_action_pressed("Btn_Exit"):
		get_tree().quit()

func _physics_process(_delta: float) -> void:
	pass

func change_Gamemode(new_state: GameState) -> void:
	await get_tree().process_frame
	if new_state == current_state:
		return
	
	current_state = new_state
	match new_state:
		GameState.LOADING:
			if Debug == true:
				print("Managers Loading")
		GameState.MAIN_MENU:
			audio_manager.play_bgm("Menu", "Menu Theme")
			ui_manager.Change_Gui_scene("Main_menu")
		GameState.CHAR_SELECT:
			audio_manager.play_bgm("Menu", "Character Select Theme")
			if Debug == true:
				print("Please Select your Character")
		GameState.LEVEL_SELECT:
			if Debug == true:
				print("Please Select your Level")
		GameState.MID_MATCH:
			#Spawn in the Selected Level
			level_manager.Change_Level_scene(Global.Level_Select)
			#Add Actors
			character_manager.game_start()
			#Switch To Mid Match UI
			ui_manager.Change_Gui_scene("Ingame_UI")
			#Switch To Mid Match Music
			
			pass
		
