extends Node
class_name State

var state_machine: FighterStateMachine
var fighter: Fighter
var opponent: Fighter
var possible_commands: Array[String]

signal state_transition

func Enter() -> void:
	state_machine.allowed_cmnds = possible_commands

func Update(_delta:float) -> void:
	pass

func Exit() -> void:
	pass
