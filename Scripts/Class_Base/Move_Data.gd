@tool
extends Resource
class_name MoveData

# -----------------------------------------------------------------------------
# Cancel window — typed inner class
# No frame ranges — phase is determined by move state machine.
# Rules:
#   A. Nothing cancels during startup — enforced by _cancel_allowed()
#   B. On hit or block — opens cancel window
#   C. Whiff cancel only if on_whiff explicitly true
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# Attack level table — all values derived from here unless overridden
# Index = attack level (0–5)
# -----------------------------------------------------------------------------
const LEVEL_TABLE : Array[Dictionary] = [
	# Lvl 0
	{ "hitstop": 8,  "hitstop_ch": 0, "hitstun": 10, "hitstun_ch": 4,
	  "blockstun": 9,  "blockstop": 8,  "p1": 100, "p2": 75,
	  "airhit": 12, "airhit_ch": 11, "pushback": 0
	},
	# Lvl 1
	{ "hitstop": 9,  "hitstop_ch": 0, "hitstun": 12, "hitstun_ch": 4,
	  "blockstun": 11, "blockstop": 9,  "p1": 100, "p2": 80,
	  "airhit": 12, "airhit_ch": 12, "pushback": 1500
	},
	# Lvl 2
	{ "hitstop": 10, "hitstop_ch": 1, "hitstun": 14, "hitstun_ch": 4,
	  "blockstun": 13, "blockstop": 10, "p1": 100, "p2": 85,
	  "airhit": 14, "airhit_ch": 12, "pushback": 2200
	},
	# Lvl 3
	{ "hitstop": 11, "hitstop_ch": 2, "hitstun": 17, "hitstun_ch": 5,
	  "blockstun": 16, "blockstop": 11, "p1": 100, "p2": 89,
	  "airhit": 17, "airhit_ch": 14, "pushback": 3500
	},
	# Lvl 4
	{ "hitstop": 12, "hitstop_ch": 5, "hitstun": 19, "hitstun_ch": 5,
	  "blockstun": 18, "blockstop": 12, "p1": 100, "p2": 92,
	  "airhit": 19, "airhit_ch": 15,
	},
]

# Combo rate — system constant, everyone shares this
const COMBO_RATE : float = 0.60

# -----------------------------------------------------------------------------
# Enums
# -----------------------------------------------------------------------------
enum GuardType  { High, Mid, Low, All, Throw, GuardBreak }
enum Attribute  { Head, Body, Foot, Projectile, Throw, Doll }
enum HitEffect  { None, Launch, Crumple, WallBounce, GroundBounce, WallStick, Slide, Down, SpinFall, Crouch }
enum StarterType { Very_Short, Short, Normal, Long}
enum InvulType  { None, Head, Body, Foot, Throw, Projectile, Burst, Full, GuardPoint }

# -----------------------------------------------------------------------------
# Identity
# -----------------------------------------------------------------------------
@export var move_name : String = ""
@export var move_id   : String = ""

# -----------------------------------------------------------------------------
# Flags
# -----------------------------------------------------------------------------
@export var is_aerial    : bool = false   ## Aerial moves use 80% P1 proration
@export var is_doll_move : bool = false   ## Doll moves — full sequence handled character-side

# -----------------------------------------------------------------------------
# Frame data
# -----------------------------------------------------------------------------
@export_group("Frame Data")
@export var startup  : int        = 1
@export var active   : Array[int] = [1]   ## Per-hit active frames
@export var gaps     : Array[int] = []    ## Gaps between hits (size = active.size() - 1)
@export var recovery : int        = 1

## Superflash — only set for supers/distortions. All -1 if not a superflash move.
@export var startup_pre_flash  : int = -1
@export var flash_duration     : int = -1
@export var startup_post_flash : int = -1

# -----------------------------------------------------------------------------
# Damage
# -----------------------------------------------------------------------------
@export_group("Damage")
@export var damage              : Array[int]   = [0]    ## Per-hit damage values
@export var min_damage          : Array[int]   = [0]    ## Per-hit minimum damage floors
@export var chip_damage_percent : float        = 0.0    ## % of damage dealt on block (specials/supers only)

# -----------------------------------------------------------------------------
# Proration
# -----------------------------------------------------------------------------
@export_group("Proration")
@export var p1              : int        = 100   ## Route proration — first hit of combo only
@export var p2              : Array[int] = [100] ## Per-hit combo proration
@export var p2_once         : bool       = false ## Multi-hit: apply P2 only once total
@export var bonus_proration : int        = 0     ## Extra proration >100%. 0 = none. Only one active per combo.

# -----------------------------------------------------------------------------
# Starter
# -----------------------------------------------------------------------------
@export_group("Starter")
@export var starter : StarterType = StarterType.Normal

# -----------------------------------------------------------------------------
# Guard / Attribute
# -----------------------------------------------------------------------------
@export_group("Guard and Attribute")
@export var guard     : Array[GuardType] = [GuardType.Mid]   ## Per-hit guard type
@export var attribute : Array[Attribute] = [Attribute.Body]  ## Per-hit attribute

# -----------------------------------------------------------------------------
# Attack level
# -----------------------------------------------------------------------------
@export_group("Attack Level")
@export var attack_level : Array[int] = [1]   ## Per-hit attack level (0-5). Falls back to last entry.

## Overrides — set to -1 to use table default.[br]
## [br]
## override_hitstun:    Lvl0:10  Lvl1:12  Lvl2:14  Lvl3:17  Lvl4:19   [br]
## Counter Hit Added:  Lvl0:+4  Lvl1:+4  Lvl2:+4  Lvl3:+5  Lvl4:+5 
@export var override_hitstun   : Array[int] = []
## [br]
## override_hitstop:    Lvl0:8   Lvl1:9   Lvl2:10  Lvl3:11  Lvl4:12  [br]
## Counter Hit Added:  Lvl0:+0  Lvl1:+0  Lvl2:+1  Lvl3:+2  Lvl4:+5 
@export var override_hitstop   : Array[int] = []
## [br]
## override_blockstun:  Lvl0:9   Lvl1:11  Lvl2:13  Lvl3:16  Lvl4:18  
@export var override_blockstun : Array[int] = []
## [br]
## override_blockstop:  Lvl0:8   Lvl1:9  Lvl2:10  Lvl3:11  Lvl4:12
@export var override_blockstop : Array[int] = []
## [br]
## override_airhit:     Lvl0:12  Lvl1:12  Lvl2:14  Lvl3:17  Lvl4:19  [br]
## Counter Hit Added:  Lvl0:+0  Lvl1:+0  Lvl2:+0  Lvl3:+3  Lvl4:+4 
@export var override_airhit    : Array[int] = []
@export var override_airhit_ch : Array[int] = []

## Asymmetric blockstop/hitstop — per hit. Empty = symmetric (use table)[br]
## [br]
## blockstop attacker/defender: Lvl0:8  Lvl1:9  Lvl2:10  Lvl3:11  Lvl4:12  
@export var override_blockstop_attacker : Array[int] = []
@export var override_blockstop_defender : Array[int] = []
## [br]
## hitstop attacker/defender:   Lvl0:8  Lvl1:9  Lvl2:10  Lvl3:11  Lvl4:12  [br]
## Counter Hit Added:           Lvl0:+0 Lvl1:+0 Lvl2:+1  Lvl3:+2  Lvl4:+5 
@export var override_hitstop_attacker   : Array[int] = []
@export var override_hitstop_defender   : Array[int] = []

# -----------------------------------------------------------------------------
# Cancel Windows
# -----------------------------------------------------------------------------
@export_group("Cancel Windows")
@export var cancel_normal    : CancelWindow = CancelWindow.new()
@export var cancel_special   : CancelWindow = CancelWindow.new()
@export var cancel_drive     : CancelWindow = CancelWindow.new()
@export var cancel_overdrive : CancelWindow = CancelWindow.new()
@export var cancel_jump      : CancelWindow = CancelWindow.new()
@export var cancel_rapid     : CancelWindow = CancelWindow.new()
@export var cancel_dash      : CancelWindow = CancelWindow.new()
@export var cancel_backdash  : CancelWindow = CancelWindow.new()
@export var cancel_burst     : CancelWindow = CancelWindow.new()

# -----------------------------------------------------------------------------
# Hit effects
# -----------------------------------------------------------------------------
@export_group("Hit Effects")
@export var ground_hit_effect   : Array[HitEffect] = [HitEffect.None]
@export var ground_hit_duration : Array[int]       = [-1]   ## -1 = use table hitstun
@export var air_hit_effect      : Array[HitEffect] = [HitEffect.None]
@export var air_hit_duration    : Array[int]       = [-1]   ## -1 = use table untechable
@export var ground_ch_effect    : Array[HitEffect] = [HitEffect.None]
@export var ground_ch_duration  : Array[int]       = [-1]
@export var air_ch_effect       : Array[HitEffect] = [HitEffect.None]
@export var air_ch_duration     : Array[int]       = [-1]

# -----------------------------------------------------------------------------
# Invulnerability
# -----------------------------------------------------------------------------
@export_group("Invulnerability")
@export var invul_type  : Array[InvulType] = []   ## Active invul types — empty = none
@export var invul_start : int = -1
@export var invul_end   : int = -1

## Doll-specific invul
@export var doll_invul_start : int = -1
@export var doll_invul_end   : int = -1
@export var doll_invul_type  : Array[InvulType] = []

# -----------------------------------------------------------------------------
# Hitbox / Hurtbox shape data
# Populated by HitboxFrameData.Bake() — do not edit manually
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# Physics Impulses
# Each entry: { "x": float, "y": float, "start": int, "end": int, "falloff": float }
# start/end in frames. -1 = whole move duration.
# falloff: velocity multiplier per frame (e.g. 0.85). 1.0 = no falloff.
# -----------------------------------------------------------------------------
@export_group("Physics Impulses")
@export var impulse_x       : float = 0.0
@export var impulse_y       : float = 0.0
@export var impulse_start   : int   = -1
@export var impulse_end     : int   = -1
@export var impulse_falloff : float = 1.0

# -----------------------------------------------------------------------------
# Pushback
# Applied along the X axis — positive = away from attacker.
# Corner reversal handled by hit resolution system.
# -1 = no pushback.
# Attack Level 1 = 1500, 
# -----------------------------------------------------------------------------
@export_group("Pushback")
## Empty = use attack level default (to be added). Positive = away from attacker.[br]
## Ground defaults by level: Lvl0:800  Lvl1:1000  Lvl2:1200  Lvl3:1400  Lvl4:1600  Lvl5:1800[br]
## Air defaults by level:    Lvl0:600  Lvl1:800   Lvl2:1000  Lvl3:1200  Lvl4:1400  Lvl5:1600
@export var pushback       : Array[float] = []   ## Ground pushback X per hit index
@export var air_pushback_x : Array[float] = []   ## Air pushback X per hit index
@export var air_pushback_y : Array[float] = []   ## Air pushback Y per hit index

# -----------------------------------------------------------------------------
# Counter hit
# -----------------------------------------------------------------------------
@export_group("Counter Hit")
@export var is_counterhitable : bool = true

# -----------------------------------------------------------------------------
# Cancel Routes — per-move cancel routing
# Each entry maps a command string to an HFD node path.
# Checked by ST_Attack.on_command() after cancel window validation.
# -----------------------------------------------------------------------------
@export_group("Cancel Routes")
@export var cancel_routes : Array[CancelRoute] = []

# -----------------------------------------------------------------------------
# Table query API
# Call these from the hit resolution system — never read table directly.
# All respect overrides first, fall back to table.
# -----------------------------------------------------------------------------

func _get_level(hit_index : int) -> int:
	if attack_level.is_empty(): return 1
	return attack_level[min(hit_index, attack_level.size() - 1)]

func get_hitstun(hit_index : int = 0) -> int:
	if not override_hitstun.is_empty():
		return override_hitstun[min(hit_index, override_hitstun.size() - 1)]
	return LEVEL_TABLE[_get_level(hit_index)]["hitstun"]

func get_hitstun_crouch(hit_index : int = 0) -> int:
	return get_hitstun(hit_index) + 2

func get_hitstun_ch(hit_index : int = 0) -> int:
	return get_hitstun(hit_index) + LEVEL_TABLE[_get_level(hit_index)]["hitstun_ch"]

func get_blockstun(hit_index : int = 0) -> int:
	if not override_blockstun.is_empty():
		return override_blockstun[min(hit_index, override_blockstun.size() - 1)]
	return LEVEL_TABLE[_get_level(hit_index)]["blockstun"]

func get_blockstop(hit_index : int = 0) -> int:
	if not override_blockstop.is_empty():
		return override_blockstop[min(hit_index, override_blockstop.size() - 1)]
	return LEVEL_TABLE[_get_level(hit_index)]["blockstop"]

func get_hitstop(hit_index : int = 0) -> int:
	if not override_hitstop.is_empty():
		return override_hitstop[min(hit_index, override_hitstop.size() - 1)]
	return LEVEL_TABLE[_get_level(hit_index)]["hitstop"]

func get_hitstop_ch(hit_index : int = 0) -> int:
	return get_hitstop(hit_index) + LEVEL_TABLE[_get_level(hit_index)]["hitstop_ch"]

func get_airhit(hit_index : int = 0) -> int:
	if not override_airhit.is_empty():
		return override_airhit[min(hit_index, override_airhit.size() - 1)]
	return LEVEL_TABLE[_get_level(hit_index)]["airhit"]

func get_airhit_ch(hit_index : int = 0) -> int:
	if not override_airhit_ch.is_empty():
		return override_airhit_ch[min(hit_index, override_airhit_ch.size() - 1)]
	return get_airhit(hit_index) + LEVEL_TABLE[_get_level(hit_index)]["airhit_ch"]

func get_blockstop_attacker(hit_index: int) -> int:
	if override_blockstop_attacker.size() > hit_index:
		return override_blockstop_attacker[hit_index]
	return get_hitstop()

func get_blockstop_defender(hit_index: int) -> int:
	if override_blockstop_defender.size() > hit_index:
		return override_blockstop_defender[hit_index]
	return get_hitstop()

# -----------------------------------------------------------------------------
# Damage calculation
# -----------------------------------------------------------------------------

## Calculate final damage for a single hit in a combo.
## hit_index       : which hit of THIS move (0-based)
## is_first_hit    : true if this is the very first hit of the entire combo
## first_hit_p1    : p1 of the combo opener (as decimal e.g. 0.80)
## accumulated_p2  : running product of all previous hits' p2 (as decimal)
## bonus_applied   : whether bonus proration has already been used this combo
func calculate_damage(
	hit_index      : int,
	is_first_hit   : bool,
	first_hit_p1   : float,
	accumulated_p2 : float,
	bonus_applied  : bool
) -> int:
	var base := float(damage[min(hit_index, damage.size() - 1)])

	# First hit — no scaling applied
	if is_first_hit:
		return int(base)

	# Bonus proration — only if not already applied this combo
	var bonus := float(bonus_proration) / 100.0 if bonus_proration > 0 and not bonus_applied else 1.0

	# Final damage = base × combo_rate × P1 × accumulated_P2 (from previous hits only) × bonus
	var scaled := base * COMBO_RATE * first_hit_p1 * accumulated_p2 * bonus

	# Apply minimum damage floor
	var floor_val : float
	if min_damage.is_empty():
		floor_val = base * 0.05
	else:
		floor_val = float(min_damage[min(hit_index, min_damage.size() - 1)])
	scaled = maxf(scaled, floor_val)

	return int(scaled)

## Returns the new accumulated_p2 after this hit — includes this hit's P2 for next hit.
func next_accumulated_p2(current: float, hit_index: int) -> float:
	if p2_once and hit_index > 0:
		return current
	var p2_index : int = min(hit_index, p2.size() - 1)
	return current * (float(p2[p2_index]) / 100.0)

# -----------------------------------------------------------------------------
# Phase queries — used by ST_Attack
# -----------------------------------------------------------------------------

func is_startup_frame(frame: int)  -> bool: return frame < startup
func is_active_frame(frame: int)   -> bool: return frame >= startup and frame < startup + _total_active()
func is_recovery_frame(frame: int) -> bool: return frame >= startup + _total_active()
func total_frames()                -> int:  return startup + _total_active() + recovery

func static_difference() -> int:
	return get_blockstun(0) - ((active[0] - 1) + recovery)

## Real frame advantage given remaining active frames
func real_frame_advantage(remaining_active: int) -> int:
	return get_blockstun(0) - (remaining_active + recovery)

func _total_active() -> int:
	var total := 0
	for a in active: total += a
	for g in gaps:   total += g
	return total

# -----------------------------------------------------------------------------
# Cancel query — pass to state machine cancel gate check
# -----------------------------------------------------------------------------
func can_cancel(window: CancelWindow, hit: bool, blocked: bool) -> bool:
	return window.is_available(hit, blocked)
