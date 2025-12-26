extends CanvasLayer

@onready var p1_name: Label = $P1_Name
@onready var p2_name: Label = $P2_Name

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.game_manager.change_Gamemode(Global.game_manager.GameState.MID_MATCH)
	
	_load_Character_Data(Global.P1, Global.P2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _load_Character_Data(P1, P2):
	p1_name.text = P1.char_data.character_name
	p2_name.text = P2.char_data.character_name
