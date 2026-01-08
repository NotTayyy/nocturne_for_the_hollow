extends Node
class_name FighterState

var state_name: String = "Base State" ## Name for Debuging purpouses
var fighter ## The Main Fighter
var state_machine ## The State Machine

func Enter() -> void: ## Runs when The State is Initially Entered
	pass

func physics_update(_delta): ## Runs Per-frame Physics Logic
	pass

func update(_delta): ## Runs Per-frame Non Physics Logic
	pass

func handle_input(_event): ## Handles Player Inputs and what it does for our States
	pass

func exit(): ## Runs when we Exit the State
	pass
