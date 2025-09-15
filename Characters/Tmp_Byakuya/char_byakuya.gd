extends Fighter

func _ready() -> void:
	super._ready()
	
	

func _process(_delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_released():
		Anim_Player.play("Stand_IDLE")
	
	if event.is_action_pressed(move_left):
		Anim_Player.play("Bwd_Walk")
		
	
	if event.is_action_pressed(move_right):
		Anim_Player.play("Fwd_Walk")
	
