extends Control

@export var bar_back  : TextureProgressBar   ## Empty bar background
@export var bar_grey  : TextureProgressBar   ## Grey health (recoverable)
@export var bar_front : TextureProgressBar   ## Red health (current)
@export var is_P1     : bool = false

var Player

var front_tween : Tween
var back_tween  : Tween

func _ready() -> void:
	Player = Global.P1 if is_P1 else Global.P2

	var max_hp : int = Player.char_data.base_max_health
	bar_back.max_value  = max_hp
	bar_grey.max_value  = max_hp
	bar_front.max_value = max_hp
	bar_back.value  = max_hp
	bar_grey.value  = max_hp
	bar_front.value = max_hp

	Player.char_data.health_changed.connect(_on_health_changed)
	Player.char_data.grey_health_changed.connect(_on_grey_health_changed)

# =============================================================================
# Health signals
# =============================================================================

func _on_health_changed(current: int, _max_hp: int) -> void:
	_kill_tweens()

	var is_damage : bool = current < bar_front.value

	# Red bar updates immediately
	bar_front.value = current

	if is_damage:
		_flash(Color(0.873, 0.048, 0.284, 1.0))
	else:
		# Healing — snap grey bar down too
		bar_grey.value = current + Player.char_data.curr_grey_health
		_flash(Color(0.0, 0.844, 0.529, 1.0))

func _on_grey_health_changed(curr_grey: int) -> void:
	var curr_hp   : int   = Player.char_data.curr_health
	var target    : float = float(curr_hp + curr_grey)

	_kill_tweens()

	if curr_grey == 0:
		# Grey wiped instantly (new combo or Limit Break)
		bar_grey.value = bar_front.value
	else:
		# Grey bar sits above red bar — no tween, just track it
		bar_grey.value = target

# =============================================================================
# Helpers
# =============================================================================

func _kill_tweens() -> void:
	if front_tween and front_tween.is_running(): front_tween.kill()
	if back_tween  and back_tween.is_running():  back_tween.kill()

func _flash(flash_color: Color) -> void:
	modulate = flash_color
	var t := create_tween()
	t.tween_property(self, "modulate", Color(1, 1, 1), 0.25)
