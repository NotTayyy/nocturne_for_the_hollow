extends DriveSystem
class_name Kag_DriveSystem

# =============================================================================
# Kagura Mutsuki - Drive: Black Onslaught
# - 3 stances: 5D, 2D, 6D
# - Each stance can only be entered once per chain
# - Max 3 drive attacks per chain across all stances
# - Chain resets when a normal is used
# - Overdrive removes the attack cap
# - Cannot enter a stance that has already been consumed this chain
# =============================================================================

const STANCES : Array[String] = ["Button D", "2D", "6D"]
const MAX_ATTACKS : int = 3

var stances_used   : Array[String] = []
var attacks_used   : int           = 0

func can_activate(fighter: Node) -> bool:
	if fighter.char_data.in_overdrive:
		return true
	var cmd : String = fighter.state_manager.last_command.get("Command", "")
	return cmd not in stances_used

func on_activate(fighter: Node, input: String) -> void:
	if input not in stances_used:
		stances_used.append(input)

func on_drive_attack(fighter: Node) -> void:
	attacks_used += 1

func can_attack(fighter: Node) -> bool:
	if fighter.char_data.in_overdrive:
		return true
	return attacks_used < MAX_ATTACKS

func on_normal_used(fighter: Node) -> void:
	_reset_chain()

func on_reset(fighter: Node) -> void:
	_reset_chain()

func _reset_chain() -> void:
	stances_used.clear()
	attacks_used = 0

func get_debug_info() -> Dictionary:
	return {
		"Stances Used" : stances_used,
		"Attacks Used" : "%d / %d" % [attacks_used, MAX_ATTACKS],
	}
