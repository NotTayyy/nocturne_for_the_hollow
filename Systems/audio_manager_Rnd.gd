extends Node2D

@onready var bgm_streamer = %AudioStreamPlayer

@export_range(0, 100, 1) var Volume : int = 75

var game_manager: Node

var bgm_list: Dictionary = {
	"Beat Eat Nest": preload("res://Assets/Music/Tmp_Beat_Eat_Nest.mp3"),
	"Holy Orders": preload("res://Assets/Music/Tmp_Holy.mp3"),
	"Lust Of Sin": preload("res://Assets/Music/Tmp_Lust.mp3"),
	"Marionette Purple": preload("res://Assets/Music/Tmp_Marionette.mp3"),
	"Queen Of Roses": preload("res://Assets/Music/Tmp_Queen.mp3"),
	"The Red Line": preload("res://Assets/Music/Tmp_Red_Line.mp3")
}

func _ready() -> void:
	await get_tree().process_frame
	game_manager = get_parent()
	if game_manager:
		print("Audio Manager Loaded!")
	randomize()
	update_volume()
	play_rndm_bgm()


func play_rndm_bgm():
	var keys = bgm_list.keys()
	var rndm_key = keys[randi() % keys.size()]
	var stream = bgm_list[rndm_key]
	
	bgm_streamer.stream = stream
	bgm_streamer.play()
	
	print("Now Playing: ", rndm_key)

func update_volume():
	bgm_streamer.volume_db = linear_to_db(Volume / 100.0)
