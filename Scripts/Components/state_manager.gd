class_name State_Manager extends Node

var current_state : FighterState = null
var fighter
var States : Dictionary = {}

func _ready():
	for child in get_children():
		if child is FighterState:
			States[child.name] = child

func change_state(new_state: FighterState) -> void:
	pass

func _process(delta: float) -> void:
	if current_state:
		current_state.Update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.Physics_Update(delta)
