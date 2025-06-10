class_name FighterStateMachine extends Node

@export var initial_state: State

var current_state: State
@onready var label: Label = %State
var states: Dictionary[String, State] = {}
@onready var fighter: Fighter = get_parent()
var queue

var allowed_cmnds: Array[String]

func _ready() -> void:
	for child in get_children(true):
		if child is State:
			child.state_machine = self
			child.fighter = fighter
			states[child.name.to_lower()] = child
	
	if initial_state:
		initial_state.Enter()
		current_state = initial_state
 
func _process(delta: float) -> void:
	if current_state:
		label.text = current_state.name
		current_state.Update(delta)
	
	execute_queue(queue)
	

func set_queue(command):
	#Each state has a Array of commands that they can perform, Send the list whenever the state changes to the input manager
	#Then check all commands, then send the highest priority move here, Then we execute it and move to that moves state!
	queue = command #Make this Only last a Few frames but get checked every frame till its overriden or Executed

func execute_queue(queue):
	if queue in allowed_cmnds:
		change_state(queue)
	else:
		print("Invalid command in this state:", queue)

func change_state(new_state_names: String) -> void:
	var new_state: State = states.get(new_state_names.to_lower())
	
	assert(new_state, "State not found: " + new_state_names)
	
	if current_state:
		current_state.Exit()
		
	new_state.Enter()
	
	current_state = new_state
