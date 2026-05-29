extends Control

enum MeterType { Limit, Burst, Barrier, Flow }

@export var bar_value  : TextureProgressBar
@export var bar_label  : Label
@export var is_P1      : bool       = false
@export var meter_type : MeterType  = MeterType.Limit

var Player

func _ready() -> void:
	Player = Global.P1 if is_P1 else Global.P2
	if Player == null:
		return

	var cd : CharacterData = Player.char_data

	match meter_type:
		MeterType.Limit:
			bar_value.max_value = cd.base_max_Limit
			bar_value.value     = cd.curr_Limit
			cd.limit_changed.connect(_on_value_changed)
		MeterType.Burst:
			bar_value.max_value = cd.base_max_burst
			bar_value.value     = cd.curr_burst
			cd.burst_changed.connect(_on_value_changed)
		MeterType.Barrier:
			bar_value.max_value = cd.base_max_barrier
			bar_value.value     = cd.curr_barrier
			cd.barrier_changed.connect(_on_value_changed)
		MeterType.Flow:
			bar_value.max_value = cd.base_max_flow
			bar_value.value     = cd.curr_flow
			cd.flow_changed.connect(_on_value_changed)

	_update_label(bar_value.value)

func _on_value_changed(current: int, _max: int) -> void:
	bar_value.value = current
	_update_label(current)

func _update_label(current: int) -> void:
	if bar_label == null:
		return
	match meter_type:
		MeterType.Limit:
			# Display as Heat (0-100), raw units are 0-10000
			bar_label.text = "%d" % (current / 100)
		_:
			bar_label.text = "%d" % current
