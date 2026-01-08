extends FighterState


func Enter() -> void:
	fighter.velocity.x = 0
	fighter.animation_player.play("idle")

func physics_update(delta):
	var dir = Input.get_axis("move_left", "move_right")

	if dir != 0:
		state_machine.change_state()
		return

	if Input.is_action_just_pressed("jump"):
		state_machine.change_state("JumpState")
		return

	if Input.is_action_just_pressed("attack"):
		state_machine.change_state("AttackState")
		return
