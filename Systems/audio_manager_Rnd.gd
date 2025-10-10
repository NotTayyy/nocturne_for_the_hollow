extends Node2D

@onready var bgm_streamer = %BGM_Music_Player

var current_bgm
var game_manager: Node

#Lists
var Menu_list: Dictionary = {
	"Menu Theme": preload("res://Assets/Music/Menus/Menu_Tmp_Gather_of_Night.mp3"),
	"Character Select Theme": preload("res://Assets/Music/Menus/CICADA DAYS.mp3")
}

var bgm_list: Dictionary = {
	"Beat Eat Nest": preload("res://Assets/Music/BGM/Tmp_Beat_Eat_Nest.mp3"),
	"Holy Orders": preload("res://Assets/Music/BGM/Tmp_Holy.mp3"),
	"Lust Of Sin": preload("res://Assets/Music/BGM/Tmp_Lust.mp3"),
	"Marionette Purple": preload("res://Assets/Music/BGM/Tmp_Marionette.mp3"),
	"Queen Of Roses": preload("res://Assets/Music/BGM/Tmp_Queen.mp3"),
	"The Red Line": preload("res://Assets/Music/BGM/Tmp_Red_Line.mp3")
}

func _ready() -> void:
	Global.audio_manager = self
	await get_tree().process_frame
	
	if Global.game_manager.Debug == true:
		print("Audio Manager Loaded!")
	
	update_volume("master", 10)

#Match Lists
func get_Lists(List: String) -> Dictionary:
	match List:
		"Menu": 
			return Menu_list
		"Match": 
			return bgm_list
		_:
			push_error("List Not Found, Defaulting to Match List")
			return bgm_list

func get_Sources(Source: String) -> int:
	match Source:
		"Master":
			return Global.Volume["master"]
		"BGM":
			return Global.Volume["bgm"]
		"SFX":
			return Global.Volume["sfx"]
		"Voices":
			return Global.Volume["voice"]
		"BgSfx":
			return Global.Volume["bgsfx"]
		_:
			push_error("Source Not Found, Defaulting to Match List")
			return Global.Volume["master"]

#region All Audio Sorces
func update_volume(Source: String, Vol: int) -> void:
	if not Global.Volume.has(Source):
		push_warning("Nope")
		return
	Global.Volume[Source] = clamp(Vol, 0, 100)
	bgm_streamer.volume_db = linear_to_db(Global.Volume[Source] / 100.0)
#endregion

#region BGM Stuffs
func play_rndm_bgm(List: String) -> void:
	var keys = get_Lists(List).keys()
	var rndm_key = keys[randi() % keys.size()]
	var stream = get_Lists(List)[rndm_key]
	
	bgm_streamer.stop()
	bgm_streamer.stream = stream
	current_bgm = stream
	bgm_streamer.play()
	if Global.game_manager.Debug:
		print("Now Playing: ", stream)

func play_bgm(List: String, new_bgm: String, ) -> void:
	if new_bgm == current_bgm:
		return
		
	bgm_streamer.stop()
	bgm_streamer.stream = get_Lists(List).get(new_bgm)
	current_bgm = new_bgm
	bgm_streamer.play()
	
	if Global.game_manager.Debug == true:
		print("Now Playing: ", current_bgm)

func get_bgm_list(List: String) -> Array:
	return get_Lists(List).keys()
#endregion
