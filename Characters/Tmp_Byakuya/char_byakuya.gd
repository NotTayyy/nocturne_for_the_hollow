extends Fighter

func _ready() -> void:
	super._ready()

func _process(_delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("P1_Btn_A") and not event.is_echo():
		var hit_log: HitLog = HitLog.new()
		var hitbox = Hitbox.new(1000, 1, Vector2(100, 100), Vector2(200,-110), player_id, hit_log)
		add_child(hitbox)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_released():
		anim_Player.play("Stand_IDLE")
	
	if event.is_action_pressed(move_left):
		anim_Player.play("Bwd_Walk")
	
	if event.is_action_pressed(move_right):
		anim_Player.play("Fwd_Walk")
	
