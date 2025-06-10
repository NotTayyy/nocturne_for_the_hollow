class_name FighterStateMachine 
extends Node

@export var initial_state: State
@onready var label: Label = %State
@onready var fighter: Fighter = get_parent()
var current_state: State
var queue_frame_timer: int = 0
var queue_frame_limit: int = 5 #The move will repeat itself for this many frames till it can exexute
#For stuff like dash cancels or landing into an attack

var states: Dictionary[String, State] = {}
var allowed_cmnds: Array[String] = []
var queue: String


func _ready() -> void:
	for child in get_children(true):
		if child is State:
			child.state_machine = self
			child.fighter = fighter
			states[child.name.to_lower()] = child
	
	if initial_state:
		initial_state.Enter()
		current_state = initial_state
		label.text = current_state.name
 
func _process(delta: float) -> void:
	if current_state:
		current_state.Update(delta)
	
	execute_queue(queue)
	

func set_queue(command):
	queue_frame_timer = queue_frame_limit
	queue = command #Make this Only last a Few frames but get checked every frame till its overriden or Executed

func execute_queue(queue):
	if queue_frame_timer == 0:
		return
	if queue_frame_timer <= queue_frame_limit:
		queue_frame_timer -= 1
		if queue in allowed_cmnds:
			print("Valid command in ", current_state.name, " -> ", queue)
			#change_state(queue)
		else:
			print("Invalid command in ", current_state.name, " -> ", queue)

func change_state(new_state_names: String) -> void:
	var new_state: State = states.get(new_state_names.to_lower())
	
	assert(new_state, "State not found: " + new_state_names)
	
	if current_state:
		current_state.Exit()
		
	current_state = new_state
	allowed_cmnds = current_state.possible_commands
	label.text = current_state.name
	
	current_state.Enter()
