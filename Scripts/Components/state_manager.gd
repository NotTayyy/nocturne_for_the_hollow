extends Node
class_name State_Manager 

@export var Initial_State: FighterState ## The State the player Starts in, Idle

var current_state : FighterState = null ## The Current State the Player Is In
var States : Dictionary = {} ## All The States Under The Character

func _ready():
	for child in get_children():
		if child is FighterState:
			States[child.name] = child
			child.fighter = owner
			child.state_machine = self
	
	if Initial_State:
		Initial_State.Enter()

func change_state(new_state: FighterState) -> void:
	if current_state:
		current_state.Exit()
	current_state = new_state
	current_state.Enter()

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _process(delta) -> void:
	if current_state:
		current_state.update(delta)

func _input(event):
	if current_state:
		current_state.handle_input(event)
