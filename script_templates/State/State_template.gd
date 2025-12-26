extends Node
class_name FighterState

signal state_transition

var fighter
var state_name: String = "Base State"

func Enter() -> void:
	pass

func Update(_delta:float) -> void:
	pass

func Physics_Update(_delta: float) -> void:
	pass

func Exit() -> void:
	pass 
