extends Control

@export var bar_back: TextureProgressBar
@export var bar_front: TextureProgressBar
@export var is_health: bool = false
@export var is_P1: bool = false

var Player

var pending_back_value: float =  -1.0
var current_health_pct : float = 1.0
var front_tween: Tween
var back_tween: Tween
var combo_drop_timer: Timer

func _ready() -> void:
	Player = Global.P1 if is_P1 else Global.P2
	
	var max_health : int = Player.char_data.base_max_health
	bar_front.max_value = max_health
	bar_back.max_value = max_health
	bar_front.value = max_health
	bar_back.value = max_health
	
	Player.char_data.health_changed.connect(update_bar)
	
	#Combo Timer
	combo_drop_timer = Timer.new()
	combo_drop_timer.wait_time = 1
	combo_drop_timer.one_shot = true
	combo_drop_timer.timeout.connect(_on_combo_drop)
	add_child(combo_drop_timer)

func update_bar(current: float, max_value: float):
	var pct = clamp(current / max_value, 0.0, 1.0)
	
	var is_damage = pct < current_health_pct
	var is_heal = pct > current_health_pct
	
	#We want to make this Go down if Combo is Dropped, And stay still if combo is ongoing
	if is_damage:
		_kill_tweens()

		# Front bar updates immediately
		bar_front.value = current
		_on_damage()

		# Store final value for delayed drain
		pending_back_value = current
		combo_drop_timer.stop()
		combo_drop_timer.start()
		
	elif is_heal:
		_kill_tweens()
		
		combo_drop_timer.stop()
		pending_back_value = -1.0
		
		front_tween = create_tween().set_parallel()
		front_tween.tween_property(bar_front, "value", current, 0.25)
		front_tween.tween_property(bar_back, "value", current, 0.25)
		_on_heal()
	
	current_health_pct = pct

func _on_combo_drop():
	if pending_back_value < 0.0:
		return

	back_tween = create_tween()
	back_tween.tween_property(bar_back, "value", pending_back_value, 0.45)

	pending_back_value = -1.0

#Temp Functions
func _kill_tweens() -> void:
	if front_tween and front_tween.is_running():
		front_tween.kill()
	if back_tween and back_tween.is_running():
		back_tween.kill()

func _Flash(flash_color: Color):
	modulate = flash_color
	var t = create_tween()
	t.tween_property(self, "modulate", Color(1,1,1), 0.25)

func _on_damage():
	_Flash(Color(0.873, 0.048, 0.284, 1.0))

func _on_heal():
	_Flash(Color(0.0, 0.844, 0.529, 1.0))
