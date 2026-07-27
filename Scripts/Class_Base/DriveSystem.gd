extends Resource
class_name DriveSystem

# =============================================================================
# DriveSystem - Base class for all character Drive mechanics.
# Each character has their own DriveSystem assigned in CharacterData.
# Subclasses override only what they need.
# =============================================================================

## Return false to block activation (no stocks, wrong state, etc)
func can_activate(fighter: Node) -> bool:
	return true

## Called after a Drive state is entered successfully.
func on_activate(fighter: Node, input: String) -> void:
	pass

## Called when a Drive attack is used.
func on_drive_attack(fighter: Node) -> void:
	pass

## Called when a normal move is used - many systems reset on this.
func on_normal_used(fighter: Node) -> void:
	pass

## Called when combo ends or fighter returns to neutral.
func on_reset(fighter: Node) -> void:
	pass

## Called every physics frame - for systems that tick over time.
func tick(fighter: Node, delta: float) -> void:
	pass

## Called when the fighter lands a hit with any move.
func on_hit(fighter: Node) -> void:
	pass

## Called when the fighter takes a hit.
func on_hit_taken(fighter: Node) -> void:
	pass

## Returns debug info for ImGui display.
func get_debug_info() -> Dictionary:
	return {}
