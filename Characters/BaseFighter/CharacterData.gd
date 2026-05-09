extends Resource
class_name CharacterData

enum DashType { Step, Dash, Teleport, None }
enum BackDashType { Step, Dash, Teleport}

@export_category("Lore Data")
@export var character_name: String = "Default Fighter"

@export_category("Meta Data")
@export var fighter_scene: PackedScene
#The CommandData holds Neg and Regular Commands
@export var command_list: CommandData
@export var neg_edge: bool = false
@export var charge_moves: bool = false

@export_category("Basics Data")
# Basic Important Stats
## The Base Max Hp of the Characters.[br]
##[br]
## 12500 Should be the median HP, With Thicker Characters being around 1500,
## and thinner characters to be down at 1100
@export var base_max_health: int = 12500 

##The Characters Base Limit
@export var base_max_Limit: int = 100 

## The Characters Burst Buildup, Functionally the same thing as Burst.
@export var base_max_burst: int = 100

## This will be the Barrier, It will go down when the player takes attacks [br]
## or when the Player uses their Barrier Most of the time this isnt that important [br]
## and it regenerates over time But with certain moves and it reaches 0, [br]
## it will cause the character to lose Access the the Barrier Gauge [br]
@export var base_max_barrier: int = 100

## The Secret Hidden Meter called Flow state[br]
## [br]
## When entering the flow state, 2x burst and meter gain, 2x damage, [br]
## shorten recovery and startups and make new combos possible [br]
## [br]
## There will be a List of actions that Make the Character Gain Flow, there will [br]
## also be Specific actions that Proc the Flow state.
@export var base_max_flow: int = 1000

## If the player moves back to much or isn't attacking we will give them a neg Debuff[br]
## Some characters need to backup more than others so they get more resistance to the Debuff [br]
@export_range(1, 5, 1) var negative_Penalty_Resistance: int = 3
## This is like Defense? Take less damage the tougher they are
@export_range(0, 5, 1) var toughness: int = 3 
@export_range(0, 5, 1) var willpower: int = 3 ## More Defense and maybe More Meter gain lower the HP
@export var ground_throw_range: int = 70 #99% of peeps will be The default
@export var air_throw_range: int = 120 #99% of peeps will be The default
@export var landing_recovery: int = 5 ## All Characters Experience 5 Frames of Landing Lag
@export var friction: float = 0.9  ## Some characters are more slipery

@export_category("Walking")
#Walking
@export var fwd_walk_speed: int = 400 ## 400 Avg; 550 Fast; 250 Slow;
@export var bwd_walk_speed: int = 300 ## 300 Avg; 350 Fast ; 200 Slow

@export_category("Dashes")
@export var dashType: DashType = DashType.Dash
@export_subgroup("Dash/Run")
@export var dash_int: int = 800 ## The initial Speed of the character Movement on dash start
@export var dash_acc: int = 100 ## The Speed added per second of running
@export var dash_max: int = 1200 ## The max Speed the character will reach after running for awhile
@export var dash_skid: float = 0.7 ## Take the Current speed of the Character and Multiply it by this for the Skid
@export var dash_min: int = 10 ## How many frames will Dash be applied before allowed to end

@export_subgroup("Dash/Step & Teleport")

@export var step_Duration: int = 20 ## 20 Frames of Step Startup is default for now
@export var step_distance: int = 1000 ## 1000 for Step, 400 For Teleport
@export var step_recovery: int = 6 ## Recovery after Teleporting
@export var step_Startup: int = 4 ## How many frames before the teleport

@export_subgroup("Backdash")
@export var backdash_type: BackDashType = BackDashType.Step
@export var backdash_startup:  int = 4  ## Startup (Before Movement)
@export var backdash_duration: int = 6 ## Duriation (During Movement)
@export var backdash_recovery: int = 15 ## Recovery (After Movement)
@export var backdash_distance: int = 1650 ## Distance
@export var backdash_invul_start: int = 1
@export var backdash_invul_end: int = 8
@export var backdash_airborne_start: int = 1
@export var backdash_airborne_end: int = 8

@export_category("Air Movement")
@export var prejump: int = 4
@export var gravity: int = 4000
@export var air_Jumps: int = 1
@export var air_Dashes: int = 1
@export var airjump_lockout: int = 8

@export_subgroup("Jump/Normal", "jump_")
@export var jump_velocity: int = -1450 ##Base Jump Height 1450, High 1700. Low 1300
@export var jump_fwd_velocity: int = 500
@export var jump_bwd_velocity: int = 500

@export_subgroup("Jump/Super ", "superjump_")
@export var superjump_velocity: int = -1650
@export var superjump_fwd_velocity: int = 400
@export var superjump_bwd_velocity: int = 400

@export_subgroup("Airdashes", "airdash_")
@export var airdash_duration: int = 20
@export var airdash_fwd_velocity: int = 1000
@export var airdash_bwd_velocity: int = -1000



#Signals
signal health_depleted
signal burst_full
signal flow_state_entered
signal health_changed(cur_health: int, max_health: int)
signal limit_changed(cur_limit: int, max_Limit: int)
signal burst_changed(cur_burst: int, max_burst: int)
signal flow_changed(curr_flow: int, max_flow: int)

var curr_health: int = base_max_health : set = _on_health_set ## Characters Current Health Value
var curr_Limit: int = 0: set = _on_limit_set ## Characters Current Limit Value
var curr_burst: int = 0: set = _on_burst_set ## The Characters Burst Gauge
var curr_flow: int = 0: set = _on_flow_set ## The characters Hidden Flow Gauge

func _init() -> void:
	pass

func setup_char() -> void:
	curr_health = base_max_health

func _on_health_set(new_value: int) -> void:
	curr_health = clampi(new_value, 0, base_max_health)
	print(curr_health)
	health_changed.emit(curr_health, base_max_health)
	if curr_health <= 0:
		health_depleted.emit()

func _on_limit_set(new_value: int) -> void:
	curr_Limit = clampi(new_value, 0, base_max_Limit)
	limit_changed.emit(curr_Limit, base_max_Limit) 

func _on_burst_set(new_value: int) -> void:
	curr_burst = clampi(new_value, 0, base_max_burst)
	burst_changed.emit(curr_burst, base_max_burst)
	if curr_burst == base_max_burst:
		burst_full.emit()

func _on_flow_set(new_value: int) -> void:
	curr_flow = clampi(new_value, 0, base_max_flow)
	flow_changed.emit(curr_flow, base_max_flow)
	if curr_flow == base_max_flow:
		flow_state_entered.emit()
