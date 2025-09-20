extends Control

@onready var Training_label = $CanvasLayer/Training/Label

var levels_data

func _ready() -> void:
	levels_data = G_LevelDB.get_level_names()
	print(levels_data)
	print(G_LevelDB.get_level_property("training", "scene"))
	pass

func _physics_process(_delta: float) -> void:
	pass
