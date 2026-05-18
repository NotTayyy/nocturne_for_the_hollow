# =============================================================================
# Property.gd
# A single active property instance on a Fighter.
# Properties are tags with optional duration, value, and stacking rules.
# =============================================================================
class_name Property
extends RefCounted

## A List of all the Possible Attributes applied to players
enum Type {
	# --- Physics / State ---
	
	Airborne,    ## Marks the Player as Airborne
	PAirborne,
	Crouching,   ## Marks the Player as Crouching — applies crouching hitstun bonus

	# --- Buffs (self-applied) ---
	Cyclone,        ## Akihiko's Install

	# --- Debuffs (opponent-applied) ---
	Poisoned,       ## Damage over Time
	Frozen,         ## Frozen
	Stunned,        ## Stunned

	# --- Meter / Resource ---
	Flow_State,    ## Flow State

	# --- System ---
	HitStop,        ## both fighters frozen on hit
	BlockStop,      ## both fighters frozen on block
	Hitstun,        ## defender in hitstun — cannot act
	Blockstun       ## defender in blockstun
}

## Display name per type — used in debug overlay
const TYPE_NAMES : Dictionary = {
	Type.Airborne:   "Airborne",
	Type.PAirborne:  "Pseudo Airborne",
	Type.Crouching:  "Crouching",
	Type.Frozen:     "Frozen",
	Type.Stunned:    "Stunned",
	Type.HitStop:    "HitStop",
	Type.BlockStop:  "BlockStop",
	Type.Hitstun:    "Hitstun",
	Type.Blockstun:  "Blockstun",
}

## Debug colour per type
const TYPE_COLORS : Dictionary = {
	Type.Airborne:   Color(0.4, 0.8, 1.0),
	Type.PAirborne:  Color(0.28, 0.154, 1.0, 1.0),
	Type.Crouching:  Color(0.4, 0.9, 0.4),
	Type.Poisoned:   Color(0.5, 1.0, 0.3),
	Type.Frozen:     Color(0.6, 0.9, 1.0),
	Type.Stunned:    Color(1.0, 1.0, 0.3),
	Type.HitStop:    Color(0.7, 0.7, 0.7),
	Type.BlockStop:  Color(0.6, 0.6, 0.6),
	Type.Hitstun:    Color(1.0, 0.3, 0.3),
	Type.Blockstun:  Color(0.9, 0.5, 0.3),
}

## The type of this property
var type         : Type 

## Optional sub-id for Custom or Install types e.g. "Install_Azure"
var sub_id       : String  = ""

## Frames remaining. -1 = permanent until manually removed.
var duration     : int     = -1

## Who applied this property — "self", "opponent", "system"
var owner        : String  = "system"

## Optional modifier value — meaning depends on property type
var value        : float   = 0.0

## Stacking rules
var does_stack   : bool    = false
var refresh      : bool    = true

func _init(
	p_type     : Type,
	p_duration : int    = -1,
	p_owner    : String = "system",
	p_value    : float  = 1.0,
	p_stack    : bool   = false,
	p_refresh  : bool   = true,
	p_sub_id   : String = ""
) -> void:
	type       = p_type
	duration   = p_duration
	owner      = p_owner
	value      = p_value
	does_stack = p_stack
	refresh    = p_refresh
	sub_id     = p_sub_id

func get_name() -> String:
	var base : String = TYPE_NAMES.get(type, "Unknown")
	return "%s_%s" % [base, sub_id] if sub_id != "" else base

func get_color() -> Color:
	return TYPE_COLORS.get(type, Color.WHITE)

## Tick down duration by one frame. Returns true if expired.
func tick() -> bool:
	if duration == -1:
		return false
	duration -= 1
	return duration <= 0
