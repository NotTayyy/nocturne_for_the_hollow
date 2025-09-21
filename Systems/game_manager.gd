extends Node

@export var Debug: bool = false

@onready var camera_manager: Node2D = $Camera_Manager
@onready var audio_manager: Node2D = $Audio_Manager
@onready var character_manager: Node2D = $Character_Manager
@onready var level_manager: Node2D = $Level_Manager
@onready var ui_manager: Node2D = $Ui_Manager

enum GameState { MAIN_MENU, CHAR_SELECT, LEVEL_SELECT, MID_MATCH, RESULTS, PAUSE }
var current_state: GameState

func _ready() -> void:
	Global.game_manager = self
	var all_good: bool = true
	for m in [character_manager, camera_manager, audio_manager, level_manager, ui_manager]:
		if m == null:
			push_warning("GameManager: A required manager is missing!")
			all_good = false
		
	if all_good and Debug == true:
		print("Managers Loaded!")
	await get_tree().physics_frame
	change_Gamemode(GameState.MAIN_MENU)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Toggle_Debug"):
		Debug = not Debug
	if event.is_action_pressed("Btn_Select"):
		get_tree().reload_current_scene()
	if event.is_action_pressed("Btn_Exit"):
		get_tree().quit()

func _physics_process(_delta: float) -> void:
	pass

func change_Gamemode(new_state: GameState) -> void:
	current_state = new_state
	match new_state:
		GameState.MAIN_MENU:
			audio_manager.play_bgm("Menu Theme")
			ui_manager.Change_Gui_scene("res://UI/Menu/Main_Menu/Menu/Main_menu.tscn")
		GameState.MID_MATCH:
			#Spawn in the Selected Level
			var level = G_LevelDB.get_level_property(Global.Level_Select, "scene")
			level_manager.Change_Level_scene(level)
			#Add Actors
			character_manager.game_start()
			#Switch To Mid Match UI
			ui_manager.Change_Gui_scene("res://UI/Ingame/Ingame_UI.tscn")
			#Switch To Mid Match Music
			
			pass
		
