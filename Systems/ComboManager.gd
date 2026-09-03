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

var _total_damage   : int   = 0
var _hitstop_timer  : int   = 0
var _hitstop_fighters : Array[Fighter] = []

func _ready() -> void:
	Global.combo_manager = self
# =============================================================================
# Process — ticks combo duration every physics frame
# =============================================================================

func _physics_process(_delta: float) -> void:
	# Tick hitstop
	if _hitstop_timer > 0:
		_hitstop_timer -= 1
		if _hitstop_timer <= 0:
			_end_hitstop()
		return
	# Tick heat cooldowns every frame regardless of combo state
	_tick_heat_cooldowns()
	# Auto heat gain for low HP — works outside combos too
	_tick_auto_heat()
	# Tick combo timer
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
		if not result.is_blocked:
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

		# --- Move history [optional — see header comment] ---
		if md.move_id != "":
			move_history.append("%s(%d)" % [md.move_id, result.damage])

		# --- Heat gains ---
		_apply_heat_gains(result)

	is_first_hit = false
	emit_signal("combo_updated", hit_count)
	result.defender.recieve_hit(result)
	# Apply hitstop or blockstop to both fighters
	if result.is_blocked:
		apply_hitstop(result.attacker, result.defender, result.blockstop)
	else:
		apply_hitstop(result.attacker, result.defender, result.hitstop)

## Apply hitstop to both fighters
func apply_hitstop(atk: Fighter, def: Fighter, frames: int) -> void:
	if frames <= 0:
		return
	_hitstop_timer    = frames
	_hitstop_fighters = [atk, def]
	for f : Fighter in _hitstop_fighters:
		f.process_mode              = Node.PROCESS_MODE_DISABLED
		f.anim_player.pause()
		f.input_buffer.process_mode = Node.PROCESS_MODE_ALWAYS

func _end_hitstop() -> void:
	for f in _hitstop_fighters:
		if is_instance_valid(f):
			f.process_mode              = Node.PROCESS_MODE_INHERIT
			f.anim_player.play()
			f.input_buffer.process_mode = Node.PROCESS_MODE_INHERIT
	_hitstop_fighters.clear()

## Reset combo state
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

# =============================================================================
# Heat (Limit) Gain System
# Heat Gauge = 10,000 units. 100 units = 1 Heat displayed.
# All values truncated (floor) after calculation.
# =============================================================================

## Multiplier: attacker gains heat from scaled damage dealt
@export var heat_on_hit_mult           : float = 0.72
## Multiplier: defender gains heat from scaled damage taken (before combo scale)
@export var heat_on_damage_mult        : float = 0.50
## Multiplier: attacker gains heat when attack is blocked
@export var heat_on_blocked_mult       : float = 0.18
## Multiplier: defender gains heat from normal block
@export var heat_on_block_mult         : float = 0.10
## Multiplier: defender gains heat from instant block
@export var heat_on_instant_block_mult : float = 0.20
## Flat bonus units for instant block
@export var heat_instant_block_bonus   : int   = 100
## After spending Heat — reduced gain duration in frames
@export var heat_cooldown_frames       : int   = 60
## Heat gain reduction during cooldown (0.75 = 75% less)
@export var heat_cooldown_reduction    : float = 0.75
## Auto Heat gain per frame when HP < 35%
@export var heat_auto_gain_per_frame   : int   = 1
## HP threshold for auto heat gain (0.35 = 35%)
@export var heat_auto_hp_threshold     : float = 0.35

## Combo length scale table for defender heat gain
const HEAT_COMBO_SCALE_TABLE : Array[Dictionary] = [
	{ "threshold": 660, "scale": 2.6 },
	{ "threshold": 480, "scale": 2.0 },
	{ "threshold": 300, "scale": 1.6 },
	{ "threshold": 120, "scale": 1.2 },
	{ "threshold": 0,   "scale": 0.6 },
]

## Per-fighter cooldown timers — keyed by fighter instance
var _heat_cooldown_timers : Dictionary = {}  ## Fighter -> int

func _get_combo_heat_scale() -> float:
	for entry : Dictionary in HEAT_COMBO_SCALE_TABLE:
		if combo_duration_frames >= entry["threshold"]:
			return entry["scale"]
	return 0.6

func _is_in_heat_cooldown(fighter : Fighter) -> bool:
	return _heat_cooldown_timers.get(fighter, 0) > 0

func start_heat_cooldown(fighter : Fighter) -> void:
	_heat_cooldown_timers[fighter] = heat_cooldown_frames

func _grant_heat(fighter : Fighter, amount_f : float) -> void:
	if fighter == null:
		return
	var amount : int = int(amount_f)  ## Truncate — no rounding
	if amount <= 0:
		return
	if _is_in_heat_cooldown(fighter):
		amount = int(float(amount) * (1.0 - heat_cooldown_reduction))
	if amount <= 0:
		return
	fighter.char_data.curr_Limit = mini(
		fighter.char_data.base_max_Limit,
		fighter.char_data.curr_Limit + amount
	)

func _apply_heat_gains(result : HitResult) -> void:
	var md        : MoveData = result.move_data
	var scaled    : int      = result.damage
	var base      : int      = md.damage[min(result.hit_index, md.damage.size() - 1)] if md != null else scaled

	if result.is_blocked:
		# Attacker blocked — gains from base damage
		_grant_heat(result.attacker, float(base) * heat_on_blocked_mult)
		if result.is_instant_block:
			# Defender instant blocked — bonus heat
			_grant_heat(result.defender, float(base) * heat_on_instant_block_mult + float(heat_instant_block_bonus))
		else:
			# Defender normal blocked
			_grant_heat(result.defender, float(base) * heat_on_block_mult)
	else:
		# Attacker hit — gains from scaled damage
		_grant_heat(result.attacker, float(scaled) * heat_on_hit_mult)
		# Defender takes damage — gains with combo length scale
		var combo_scale : float = _get_combo_heat_scale()
		_grant_heat(result.defender, float(scaled) * heat_on_damage_mult * combo_scale)

func _tick_heat_cooldowns() -> void:
	for fighter in _heat_cooldown_timers.keys():
		_heat_cooldown_timers[fighter] -= 1
		if _heat_cooldown_timers[fighter] <= 0:
			_heat_cooldown_timers.erase(fighter)

func _tick_auto_heat() -> void:
	var fighters : Array = [Global.P1, Global.P2]
	for fighter in fighters:
		if fighter == null:
			continue
		if _is_in_heat_cooldown(fighter):
			continue
		var cd  : CharacterData = fighter.char_data
		var pct : float         = float(cd.curr_health) / float(cd.base_max_health)
		if pct < heat_auto_hp_threshold:
			_grant_heat(fighter, float(heat_auto_gain_per_frame))

func _decay_tier_label() -> String:
	if combo_duration_frames >= 660: return "1f (max decay)"
	if combo_duration_frames >= 480:
		return "-10f | next tier in %df" % (660 - combo_duration_frames)
	if combo_duration_frames >= 300:
		return "-5f | next tier in %df" % (480 - combo_duration_frames)
	if combo_duration_frames >= 120:
		return "-2f | next tier in %df" % (300 - combo_duration_frames)
	return "none | decay starts in %df" % (120 - combo_duration_frames)
