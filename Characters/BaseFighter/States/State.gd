extends Node
class_name State

var state_machine: FighterStateMachine
var fighter: Fighter
var opponent: Fighter

signal state_transition

func Enter() -> void:
	pass

func Update(_delta:float) -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func Exit() -> void:
	pass
