extends Node2D

@onready var bgm_streamer = %BGM_Music_Player

var current_bgm
var Volume : int = 10
var game_manager: Node

var bgm_list: Dictionary = {
	"Beat Eat Nest": preload("res://Assets/Music/Tmp_Beat_Eat_Nest.mp3"),
	"Holy Orders": preload("res://Assets/Music/Tmp_Holy.mp3"),
	"Lust Of Sin": preload("res://Assets/Music/Tmp_Lust.mp3"),
	"Marionette Purple": preload("res://Assets/Music/Tmp_Marionette.mp3"),
	"Queen Of Roses": preload("res://Assets/Music/Tmp_Queen.mp3"),
	"The Red Line": preload("res://Assets/Music/Tmp_Red_Line.mp3"),
	"Menu Theme": preload("res://Assets/Music/Menu_Tmp_Gather_of_Night.mp3")
}

func _ready() -> void:
	Global.audio_manager = self
	game_manager = get_parent()
	await get_tree().process_frame
	
	if game_manager and game_manager.Debug == true:
		print("Audio Manager Loaded!")
	randomize()
	
	update_volume(Volume)

func play_rndm_bgm():
	var keys = bgm_list.keys()
	var rndm_key = keys[randi() % keys.size()]
	var stream = bgm_list[rndm_key]
	
	bgm_streamer.stop()
	bgm_streamer.stream = stream
	current_bgm = stream
	bgm_streamer.play()
	if game_manager.Debug:
		print("Now Playing: ", stream)

func update_volume(Vol: int):
	Volume = Vol
	bgm_streamer.volume_db = linear_to_db(Vol / 100.0)

func play_bgm(new_bgm: String) -> void:
	bgm_streamer.stop()
	bgm_streamer.stream = bgm_list.get(new_bgm)
	current_bgm = new_bgm
	bgm_streamer.play()
	
	if game_manager.Debug == true:
		print("Now Playing: ", current_bgm)

func get_bgm_list() -> Array:
	return bgm_list.keys()
