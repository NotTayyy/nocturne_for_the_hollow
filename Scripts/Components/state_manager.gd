extends Node
class_name FighterStateMachine

var states : Dictionary = {}
var current_state
@export var initial_state: State

func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_transition.connect(change_state)
	
	if initial_state:
		initial_state.Enter()
		current_state = initial_state


func change_state(new_state_names: String):
	
	var new_state = states.get(new_state_names.to_lower())
	
	if current_state:
		current_state.Exit()
		
	new_state.Enter()
	
	current_state = new_state
