extends Node

@onready var camera_manager = $Camera_Manager
@onready var audio_manager = $Audio_Manager
@onready var character_manager = $Character_Manager

func _ready() -> void:
	if character_manager and camera_manager and audio_manager:
		print("Managers Loaded!")
	else:
		print("GM Buggered")
