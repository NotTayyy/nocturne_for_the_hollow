class_name FighterStateMachine extends Node

@export var initial_state: State

var current_state: State
var states: Dictionary[String, State] = {}
@onready var fighter: Fighter = get_parent()

func _ready() -> void:
	for child in get_children():
		if child is State:
			child.state_machine = self
			child.fighter = fighter
			states[child.name.to_lower()] = child
	
	if initial_state:
		initial_state.Enter()
		current_state = initial_state

func _process(delta: float) -> void:
	if current_state:
		current_state.Update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state._physics_process(delta)

func change_state(new_state_names: String) -> void:
	var new_state: State = states.get(new_state_names.to_lower())
	
	assert(new_state, "State not found: " + new_state_names)
	
	if current_state:
		current_state.Exit()
		
	new_state.Enter()
	
	current_state = new_state
