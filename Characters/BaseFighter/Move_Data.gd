extends Resource
class_name MoveData

# -----------------------------------------------------------------------------
# Cancel window — typed inner class for intellisense + safety
# -----------------------------------------------------------------------------
class CancelWindow:
	var start    : int  = -1    # frame window opens. -1 = not available
	var end      : int  = -1    # frame window closes. -1 = open ended
	var on_hit   : bool = false
	var on_block : bool = false
	var on_whiff : bool = false

	func _init(
		p_start    : int  = -1,
		p_end      : int  = -1,
		p_on_hit   : bool = false,
		p_on_block : bool = false,
		p_on_whiff : bool = false
	) -> void:
		start    = p_start
		end      = p_end
		on_hit   = p_on_hit
		on_block = p_on_block
		on_whiff = p_on_whiff

	func is_available(frame: int, hit: bool, blocked: bool, whiffed: bool) -> bool:
		if start == -1:
			return false
		if frame < start:
			return false
		if end != -1 and frame > end:
			return false
		if hit     and on_hit:   return true
		if blocked and on_block: return true
		if whiffed and on_whiff: return true
		return false

# -----------------------------------------------------------------------------
# Attack level table — all values derived from here unless overridden
# Index = attack level (0–5)
# -----------------------------------------------------------------------------
const LEVEL_TABLE : Array[Dictionary] = [
	# Lvl 0
	{ "hitstop": 8,  "hitstop_ch": 0, "hitstun": 10, "hitstun_ch": 4,
	  "blockstun": 9,  "blockstop": 8,  "p1": 100, "p2": 75,
	  "untechable": 12, "untechable_ch": 11,
	  "crumple": 20, "crumple_fall": 53 },
	# Lvl 1
	{ "hitstop": 9,  "hitstop_ch": 0, "hitstun": 12, "hitstun_ch": 4,
	  "blockstun": 11, "blockstop": 9,  "p1": 100, "p2": 80,
	  "untechable": 12, "untechable_ch": 12,
	  "crumple": 22, "crumple_fall": 55 },
	# Lvl 2
	{ "hitstop": 10, "hitstop_ch": 1, "hitstun": 14, "hitstun_ch": 4,
	  "blockstun": 13, "blockstop": 10, "p1": 100, "p2": 85,
	  "untechable": 14, "untechable_ch": 12,
	  "crumple": 24, "crumple_fall": 57 },
	# Lvl 3
	{ "hitstop": 11, "hitstop_ch": 2, "hitstun": 17, "hitstun_ch": 5,
	  "blockstun": 16, "blockstop": 11, "p1": 100, "p2": 89,
	  "untechable": 17, "untechable_ch": 14,
	  "crumple": 27, "crumple_fall": 60 },
	# Lvl 4
	{ "hitstop": 12, "hitstop_ch": 5, "hitstun": 19, "hitstun_ch": 5,
	  "blockstun": 18, "blockstop": 12, "p1": 100, "p2": 92,
	  "untechable": 19, "untechable_ch": 15,
	  "crumple": 29, "crumple_fall": 62 },
	# Lvl 5
	{ "hitstop": 13, "hitstop_ch": 8, "hitstun": 21, "hitstun_ch": 6,
	  "blockstun": 20, "blockstop": 13, "p1": 100, "p2": 94,
	  "untechable": 21, "untechable_ch": 16,
	  "crumple": 31, "crumple_fall": 64 },
]

# Combo rate — system constant, everyone shares this
const COMBO_RATE : float = 0.60

# -----------------------------------------------------------------------------
# Enums
# -----------------------------------------------------------------------------
enum GuardType  { Mid, High, Low, All, Throw, GuardBreak, Barrier }
enum Attribute  { Head, Body, Foot, Projectile, Throw, Doll }
enum HitEffect  { None, Launch, Crumple, WallBounce, GroundBounce, WallStick, Slide, Down, SpinFall, Crouch }
enum StarterType { Normal, Long, Short, Very_Short }
enum InvulType  { None = 0, Strike = 1, Throw = 2, Projectile = 4, Full = 7 }

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
@export var guard     : Array[int] = [GuardType.Mid]   ## Per-hit guard type
@export var attribute : Array[int] = [Attribute.Body]  ## Per-hit attribute

# -----------------------------------------------------------------------------
# Attack level
# -----------------------------------------------------------------------------
@export_group("Attack Level")
@export_range(0, 5) var attack_level : int = 1

## Overrides — set to -1 to use table default
@export var override_hitstun   : int = -1
@export var override_blockstun : int = -1
@export var override_hitstop   : int = -1

## Asymmetric blockstop/hitstop — per hit. Empty = symmetric (use table)
@export var override_blockstop_attacker : Array[int] = []
@export var override_blockstop_defender : Array[int] = []
@export var override_hitstop_attacker   : Array[int] = []
@export var override_hitstop_defender   : Array[int] = []

# -----------------------------------------------------------------------------
# Hit effects
# -----------------------------------------------------------------------------
@export_group("Hit Effects")
@export var ground_hit_effect   : Array[int] = [HitEffect.None]
@export var ground_hit_duration : Array[int] = [-1]   ## -1 = use table hitstun
@export var air_hit_effect      : Array[int] = [HitEffect.None]
@export var air_hit_duration    : Array[int] = [-1]   ## -1 = use table untechable
@export var ground_ch_effect    : Array[int] = [HitEffect.None]
@export var ground_ch_duration  : Array[int] = [-1]
@export var air_ch_effect       : Array[int] = [HitEffect.None]
@export var air_ch_duration     : Array[int] = [-1]

# -----------------------------------------------------------------------------
# Invulnerability
# -----------------------------------------------------------------------------
@export_group("Invulnerability")
@export var invul_start : int = -1   ## -1 = no invul
@export var invul_end   : int = -1
@export var invul_type  : int = InvulType.None   ## Bitmask

## Doll-specific invul (e.g. Ignis in Duo Bios) — handled character-side
@export var doll_invul_start : int = -1
@export var doll_invul_end   : int = -1
@export var doll_invul_type  : int = InvulType.None

# -----------------------------------------------------------------------------
# Counter hit
# -----------------------------------------------------------------------------
@export_group("Counter Hit")
@export var is_counterhitable : bool = true

# -----------------------------------------------------------------------------
# Cancel windows
# -----------------------------------------------------------------------------
@export_group("Cancel Windows")
var cancel_self      : CancelWindow = CancelWindow.new()
var cancel_special   : CancelWindow = CancelWindow.new()
var cancel_drive     : CancelWindow = CancelWindow.new()
var cancel_overdrive : CancelWindow = CancelWindow.new()
var cancel_jump      : CancelWindow = CancelWindow.new()
var cancel_rapid     : CancelWindow = CancelWindow.new()
var cancel_dash      : CancelWindow = CancelWindow.new()
var cancel_backdash  : CancelWindow = CancelWindow.new()

# -----------------------------------------------------------------------------
# Table query API
# Call these from the hit resolution system — never read table directly.
# All respect overrides first, fall back to table.
# -----------------------------------------------------------------------------

func get_hitstun() -> int:
	return override_hitstun if override_hitstun != -1 \
		else LEVEL_TABLE[attack_level]["hitstun"]

func get_hitstun_crouch() -> int:
	return get_hitstun() + 2

func get_hitstun_ch() -> int:
	return get_hitstun() + LEVEL_TABLE[attack_level]["hitstun_ch"]

func get_blockstun() -> int:
	return override_blockstun if override_blockstun != -1 \
		else LEVEL_TABLE[attack_level]["blockstun"]

func get_blockstun_air() -> int:
	return get_blockstun() + 2

func get_blockstun_instant_block() -> int:
	return get_blockstun() - 3

func get_blockstun_instant_block_air() -> int:
	return get_blockstun_air() - 6

func get_blockstun_barrier() -> int:
	return get_blockstun() + 1

func get_hitstop() -> int:
	return override_hitstop if override_hitstop != -1 \
		else LEVEL_TABLE[attack_level]["hitstop"]

func get_hitstop_ch() -> int:
	return get_hitstop() + LEVEL_TABLE[attack_level]["hitstop_ch"]

func get_untechable() -> int:
	return LEVEL_TABLE[attack_level]["untechable"]

func get_untechable_ch() -> int:
	return get_untechable() + LEVEL_TABLE[attack_level]["untechable_ch"]

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

	# Get this hit's P2 (as decimal)
	var this_p2 := 1.0
	if not p2_once or hit_index == 0:
		var p2_index = min(hit_index, p2.size() - 1)
		this_p2 = float(p2[p2_index]) / 100.0

	# Bonus proration — only if not already applied this combo
	var bonus := float(bonus_proration) / 100.0 if bonus_proration > 0 and not bonus_applied else 1.0

	# Final damage = base × combo_rate × P1 × accumulated_P2 × this_P2 × bonus
	var scaled := base * COMBO_RATE * first_hit_p1 * accumulated_p2 * this_p2 * bonus

	# Apply minimum damage floor — before bonus per BBCF rules
	var floor_val := float(min_damage[min(hit_index, min_damage.size() - 1)])
	scaled = maxf(scaled, floor_val)

	return int(scaled)

## Returns the new accumulated_p2 after this hit.
## Pass hit_index = 0 for the first hit of this move.
func next_accumulated_p2(current: float, hit_index: int) -> float:
	if p2_once and hit_index > 0:
		return current   # multi-hit with p2_once — only first hit of move contributes
	var p2_index = min(hit_index, p2.size() - 1)
	return current * (float(p2[p2_index]) / 100.0)

# -----------------------------------------------------------------------------
# Phase queries — used by ST_Attack
# -----------------------------------------------------------------------------

func is_startup_frame(frame: int)  -> bool: return frame < startup
func is_active_frame(frame: int)   -> bool: return frame >= startup and frame < startup + _total_active()
func is_recovery_frame(frame: int) -> bool: return frame >= startup + _total_active()
func total_frames()                -> int:  return startup + _total_active() + recovery

## Static difference (frame advantage on block, first active frame)
func static_difference() -> int:
	return get_blockstun() - ((active[0] - 1) + recovery)

## Real frame advantage given remaining active frames
func real_frame_advantage(remaining_active: int) -> int:
	return get_blockstun() - (remaining_active + recovery)

func _total_active() -> int:
	var total := 0
	for a in active: total += a
	for g in gaps:   total += g
	return total

# -----------------------------------------------------------------------------
# Cancel query — pass to state machine cancel gate check
# -----------------------------------------------------------------------------
func can_cancel(window: CancelWindow, frame: int, hit: bool, blocked: bool, whiffed: bool) -> bool:
	return window.is_available(frame, hit, blocked, whiffed)
