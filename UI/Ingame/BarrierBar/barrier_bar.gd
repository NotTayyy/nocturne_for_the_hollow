extends Control

@export var bar_back   : TextureProgressBar
@export var bar_front  : TextureProgressBar
@export var bar_border : TextureProgressBar
@export var is_P1      : bool = false

# Colors
const COLOR_NORMAL  : Color = Color(0.20, 0.85, 0.45)   # Green — idle regen
const COLOR_ACTIVE  : Color = Color(0.25, 0.65, 1.00)   # Blue — barrier held
const COLOR_BROKEN  : Color = Color(0.90, 0.15, 0.15)   # Red — broken state

var Player

func _ready() -> void:
	Player = Global.P1 if is_P1 else Global.P2
	if Player == null:
		return
	var cd : CharacterData = Player.char_data
	bar_back.max_value  = cd.base_max_barrier
	bar_front.max_value = cd.base_max_barrier
	bar_back.value      = cd.base_max_barrier
	bar_front.value     = cd.curr_barrier
	cd.barrier_changed.connect(_on_barrier_changed)

func _process(_delta: float) -> void:
	if Player == null:
		return
	var cd         : CharacterData = Player.char_data
	var sm                         = Player.state_machine
	var is_active  : bool          = sm != null and sm.active_state != null \
		and "barrier_active" in sm.active_state \
		and sm.active_state.barrier_active

	# Tint front bar based on state
	if cd.in_broken:
		bar_front.modulate = COLOR_BROKEN
	elif is_active:
		bar_front.modulate = COLOR_ACTIVE
	else:
		bar_front.modulate = COLOR_NORMAL

func _on_barrier_changed(current: int, _max: int) -> void:
	bar_front.value = current
