extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.game_manager.change_Gamemode(Global.game_manager.GameState.MID_MATCH)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
