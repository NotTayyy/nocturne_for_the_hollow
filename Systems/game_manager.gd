extends Node

#Tmp to be removed
@export var P1: String = ""
@export var P2: String = ""
@export var Level: String = ""
@export var Debug: bool
@onready var camera_manager: Node2D = $Camera_Manager
@onready var audio_manager: Node2D = $Audio_Manager
@onready var character_manager: Node2D = $Character_Manager
@onready var level_manager: Node2D = $LevelManager

func _ready() -> void:
	G_Refrences.game_manager = self
	if character_manager and camera_manager and audio_manager and level_manager:
		if Debug == true:
			print("Managers Loaded!")
	else:
		print("GM Buggered")
	
	#Tmp to be removed
	character_manager.P1_Select = P1
	character_manager.P2_Select = P2
	
	level_manager.Level_Select = Level #Should spawn everything under the Game manager

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("Toggle_Debug"):
		Debug = not Debug
	if Input.is_action_just_pressed("Btn_Select"):
		get_tree().reload_current_scene()
