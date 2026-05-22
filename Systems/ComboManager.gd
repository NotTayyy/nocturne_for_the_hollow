extends Node2D
class_name ComboManager

# =============================================================================
# Hitstun Decay Table
# combo_duration_frames determines the decay tier.
# Starter type adds virtual frames at combo start.
# =============================================================================

const DECAY_TABLE : Array[Dictionary] = [
	{ "threshold": 660, "decay": -999 },  # Reduced to 1f
	{ "threshold": 480, "decay": -10  },
	{ "threshold": 300, "decay": -5   },
	{ "threshold": 120, "decay": -2   },
	{ "threshold": 0,   "decay": 0    },
]

const STARTER_OFFSET : Dictionary = {
	MoveData.StarterType.Long:       0,
	MoveData.StarterType.Normal:     60,
	MoveData.StarterType.Short:      120,
	MoveData.StarterType.Very_Short: 240,
}

# =============================================================================
# Combo State
# =============================================================================

var is_active             : bool    = false
var attacker              : Fighter = null
var defender              : Fighter = null

var hit_count             : int     = 0
var is_first_hit          : bool    = true
var first_hit_p1          : float   = 1.0
var accumulated_p2        : float   = 1.0
var bonus_applied         : bool    = false
var limit_built           : float   = 0.0
var combo_duration_frames : int     = 0   ## Counts UP — drives hitstun decay
var combo_timer           : int     = 0   ## Counts DOWN from hitstun — combo ends at -1

# -----------------------------------------------------------------------------
# [OPTIONAL — mark for deletion if unused]
# Move history — stores move_id strings of every move that landed this combo.
# Used for conditional move upgrades (e.g. Carl/Nirvana follow-ups).
# To remove: delete move_history, the append line in register_hit, and has_move_hit().
# -----------------------------------------------------------------------------
var move_history : Array[String] = []

# =============================================================================
# Signals
# =============================================================================

signal combo_started(attacker: Fighter, defender: Fighter)
signal combo_updated(hit_count: int)
signal combo_ended(hit_count: int, total_damage: int)

var _total_damage : int = 0

func _ready() -> void:
	Global.combo_manager = self
# =============================================================================
# Process — ticks combo duration every physics frame
# =============================================================================

func _physics_process(_delta: float) -> void:
	if not is_active:
		return
	combo_duration_frames += 1
	combo_timer -= 1
	if combo_timer < 0:
		reset()

# =============================================================================
# API
# =============================================================================

## Called by HFD when a hit lands. Resolves all scaling, fills HitResult, passes to defender.
func register_hit(result : HitResult) -> void:
	var md : MoveData = result.move_data
	var hi : int      = result.hit_index

	# Start or continue combo
	if not is_active:
		_start_combo(result)
	else:
		if result.attacker != attacker or result.defender != defender:
			reset()
			_start_combo(result)

	hit_count += 1

	if md != null:
		# --- Damage ---
		result.damage = md.calculate_damage(
			hi, is_first_hit, first_hit_p1, accumulated_p2, bonus_applied
		)
		_total_damage += result.damage
		result.defender.char_data.curr_health -= result.damage
		result.defender.char_data.add_grey_health(result.damage)

		# Accumulate P2 AFTER damage — applies to next hit
		accumulated_p2 = md.next_accumulated_p2(accumulated_p2, hi)

		if md.bonus_proration > 0 and not bonus_applied:
			bonus_applied = true

		# --- Hitstun with decay and crouching bonus ---
		var base_hitstun : int = md.get_hitstun_ch(hi) if result.is_counter else md.get_hitstun(hi)
		base_hitstun = _apply_decay(base_hitstun)
		if result.defender != null and result.defender.has_property(Property.Type.Crouching):
			base_hitstun += 2
		result.hitstun = base_hitstun
		# Refresh combo timer to new hitstun — extends combo window
		combo_timer = base_hitstun

		# --- Hitstop ---
		result.hitstop   = md.get_hitstop_ch(hi) if result.is_counter else md.get_hitstop(hi)

		# --- Blockstun / Blockstop ---
		result.blockstun = md.get_blockstun(hi)
		result.blockstop = md.get_blockstop_defender(hi)

		# --- Hit Effect ---
		if result.is_airborne:
			var eff_idx : int = min(hi, md.air_hit_effect.size() - 1)
			var dur_idx : int = min(hi, md.air_hit_duration.size() - 1)
			if not md.air_hit_effect.is_empty():
				result.hit_effect = md.air_hit_effect[eff_idx]
			if not md.air_hit_duration.is_empty():
				result.hit_duration = md.air_hit_duration[dur_idx]
				result.hit_duration = _apply_decay(result.hit_duration)
		else:
			var eff_idx : int = min(hi, md.ground_hit_effect.size() - 1)
			var dur_idx : int = min(hi, md.ground_hit_duration.size() - 1)
			if not md.ground_hit_effect.is_empty():
				result.hit_effect = md.ground_hit_effect[eff_idx]
			if not md.ground_hit_duration.is_empty():
				result.hit_duration = md.ground_hit_duration[dur_idx]
				result.hit_duration = _apply_decay(result.hit_duration)

		# --- Pushback ---
		var pb_idx : int = min(hi, md.pushback.size() - 1)
		if result.is_airborne:
			if not md.air_pushback_x.is_empty():
				var ax_idx : int = min(hi, md.air_pushback_x.size() - 1)
				result.pushback = md.air_pushback_x[ax_idx]
			if not md.air_pushback_y.is_empty():
				var ay_idx : int = min(hi, md.air_pushback_y.size() - 1)
				result.air_pushback = md.air_pushback_y[ay_idx]
		else:
			if not md.pushback.is_empty():
				result.pushback = md.pushback[pb_idx]

		# --- Impulse ---
		if md.impulse_x != 0.0 or md.impulse_y != 0.0:
			result.impulse = { "x": md.impulse_x, "y": md.impulse_y, "start": md.impulse_start, "end": md.impulse_end, "falloff": md.impulse_falloff }

		# --- Limit ---
		result.limit_contribution = _calc_limit(md, hi)
		limit_built += result.limit_contribution

		# --- Move history [optional — see header comment] ---
		if md.move_id != "":
			move_history.append("%s(%d)" % [md.move_id, result.damage])

	is_first_hit = false
	emit_signal("combo_updated", hit_count)
	result.defender.recieve_hit(result)

## Reset combo state — call when combo ends.
func reset() -> void:
	if is_active:
		emit_signal("combo_ended", hit_count, _total_damage)
	is_active             = false
	attacker              = null
	defender              = null
	hit_count             = 0
	is_first_hit          = true
	first_hit_p1          = 1.0
	accumulated_p2        = 1.0
	bonus_applied         = false
	limit_built           = 0.0
	combo_duration_frames = 0
	combo_timer           = 0
	_total_damage         = 0
	move_history.clear()   ## [optional — see header comment]

## Returns true if a move with the given ID landed this combo.
## [optional — see header comment, delete if unused]
func has_move_hit(move_id : String) -> bool:
	return move_id in move_history

# =============================================================================
# Internals
# =============================================================================

func _start_combo(result : HitResult) -> void:
	is_active      = true
	attacker       = result.attacker
	defender       = result.defender
	is_first_hit   = true
	accumulated_p2 = 1.0
	bonus_applied  = false
	limit_built    = 0.0
	_total_damage  = 0
	move_history.clear()
	# Wipe all existing grey health — previous combo's grey is gone
	result.defender.char_data.wipe_grey_health()

	# Lock in P1 and apply starter offset
	if result.move_data != null:
		first_hit_p1          = float(result.move_data.p1) / 100.0
		combo_duration_frames = STARTER_OFFSET.get(result.move_data.starter, 60)
	else:
		first_hit_p1          = 1.0
		combo_duration_frames = 0

	emit_signal("combo_started", attacker, defender)

## Returns hitstun/untechable after applying decay for current combo duration.
func _apply_decay(base_frames : int) -> int:
	if base_frames <= 0:
		return base_frames
	for entry : Dictionary in DECAY_TABLE:
		if combo_duration_frames >= entry["threshold"]:
			var decay : int = entry["decay"]
			if decay <= -999:
				return 1
			return maxi(1, base_frames + decay)
	return base_frames

func _calc_limit(md : MoveData, hi : int) -> float:
	var base_dmg : float = float(md.damage[min(hi, md.damage.size() - 1)])
	return base_dmg * 0.05

func _decay_tier_label() -> String:
	if combo_duration_frames >= 660: return "1f (max decay)"
	if combo_duration_frames >= 480:
		return "-10f | next tier in %df" % (660 - combo_duration_frames)
	if combo_duration_frames >= 300:
		return "-5f | next tier in %df" % (480 - combo_duration_frames)
	if combo_duration_frames >= 120:
		return "-2f | next tier in %df" % (300 - combo_duration_frames)
	return "none | decay starts in %df" % (120 - combo_duration_frames)
