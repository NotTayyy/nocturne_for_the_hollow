extends Fighter
class_name Char_Byakuya

func _ready() -> void:
	super._ready()
	anim_Player.animation_finished.connect(_on_animation_finished)

func _process(_delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("P1_Btn_A") and not event.is_echo():
		var hit_log: HitLog = HitLog.new()
		var hitbox = Hitbox.new(1000, Hitbox.HitboxType.Projectile, 1, Vector2(100, 100), Vector2(200,-110), player_id, dir_facing, hit_log)
		add_child(hitbox)
	
	if event.is_action_pressed("P1_Btn_B") and not event.is_echo():
		var hit_log:HitLog = HitLog.new()
		var hitbox = Hitbox.new(1500, Hitbox.HitboxType.Throw, 1, Vector2(260, 100), Vector2(170, 45), player_id, dir_facing, hit_log)
		add_child(hitbox)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(move_left):
		anim_Player.play("Bwd_Walk")
	
	if event.is_action_pressed(move_right):
		anim_Player.play("Fwd_Walk")
	
	if event.is_action_pressed("P1_Btn_A"):
		anim_Player.play("Atck_A")
	if event.is_action_released("P1_Btn_A"):
		anim_Player.play("Stand_IDLE")
	
func _on_animation_finished() -> void:
	anim_Player.play("Stand_IDLE")
