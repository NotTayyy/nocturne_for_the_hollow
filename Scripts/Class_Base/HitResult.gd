class_name HitResult

# =============================================================================
# Context — who and what
# =============================================================================
var attacker    : Fighter  = null
var defender    : Fighter  = null
var move_data   : MoveData = null   ## Full move reference — for anything not pre-resolved
var hit_index   : int      = 0
var is_counter  : bool     = false
var is_airborne : bool     = false
var is_blocked       : bool = false
var is_instant_block : bool = false  ## Placeholder — wire when instant block is implemented

# =============================================================================
# Damage
# =============================================================================
var damage : int = 0

# =============================================================================
# Stun
# =============================================================================
var hitstun   : int = 0   ## Frames of hitstun
var hitstop   : int = 0   ## Frames both freeze (shared)
var blockstun : int = 0   ## Frames of blockstun if blocked
var blockstop : int = 0   ## Frames both freeze on block

# =============================================================================
# Hit Effect
# =============================================================================
var hit_effect   : MoveData.HitEffect = MoveData.HitEffect.None
var hit_duration : int                = -1   ## -1 = use table default

# =============================================================================
# Physics
# =============================================================================
var pushback     : float      = 0.0   ## Ground pushback
var air_pushback : float      = 0.0   ## Air pushback
var impulse      : Dictionary = {}    ## { x, y, falloff } — resolved per hit_index

# =============================================================================
# Guard / Attribute
# =============================================================================
var guard_type : MoveData.GuardType = MoveData.GuardType.Mid
var attribute  : MoveData.Attribute = MoveData.Attribute.Body

# =============================================================================
# Limit
# =============================================================================
var limit_contribution : float = 0.0   ## How much limit this hit builds on defender

# =============================================================================
# Debug
# =============================================================================
func debug_print() -> String:
	var attack_lvl    : int = 0
	if move_data != null:
		attack_lvl = move_data._get_level(hit_index)
	var hit_advantage : int = hitstun - hitstop
	var base : String = "[HitResult] %s -> %s | Move: %s | Index: %d | Level: %d | Dmg: %d | Hitstun: %d | Hitstop: %d | Hit Adv: %+d | Pushback: %.0f | Effect: %s | CH: %s | Air: %s" % [
		attacker.name       if attacker  != null else "?",
		defender.name       if defender  != null else "?",
		move_data.move_name if move_data != null else "?",
		hit_index,
		attack_lvl,
		damage,
		hitstun,
		hitstop,
		hit_advantage,
		pushback,
		MoveData.HitEffect.find_key(hit_effect) if move_data != null else "?",
		str(is_counter),
		str(is_airborne),
	]
	if is_blocked:
		var block_advantage : int = blockstun - blockstop
		base += " | BLOCKED | Blockstun: %d | Blockstop: %d | Block Adv: %+d" % [blockstun, blockstop, block_advantage]
	return base
