extends Node

@onready var camera_manager: Node2D = $Camera_Manager
@onready var audio_manager: Node2D = $Audio_Manager
@onready var character_manager: Node2D = $Character_Manager
@onready var level_manager: Node2D = $LevelManager

func _ready() -> void:
	if character_manager and camera_manager and audio_manager and level_manager:
		print("Managers Loaded!")
	else:
		print("GM Buggered")

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("Toggle_Debug"):
		G_HitboxTypes.Debug != G_HitboxTypes.Debug
