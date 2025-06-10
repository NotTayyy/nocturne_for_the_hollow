extends Node
class_name State

var state_machine: FighterStateMachine
var fighter: Fighter
var opponent: Fighter
var possible_commands: Array[String]

signal state_transition

func Enter() -> void:
	pass

func Update(_delta:float) -> void:
	pass

func Exit() -> void:
	pass
