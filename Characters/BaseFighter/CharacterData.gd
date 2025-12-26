extends Resource
class_name CharacterData

enum DashType { Step, Run, Teleport, Hover, None }
enum BackDashType { Step, Run, Teleport, Hover, None }

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

## The Characters Break Buildup, Functionally the same thing as Burst.
@export var base_Max_Break: int = 100


#If the player moves back to much or isn't attacking we will give them a neg Debuff
@export_range(1, 5, 1) var negative_Penalty_Res: int = 3
#This is like Defense? Take less damage the tougher they are
@export_range(0, 5, 1) var toughness: int = 3 #Base Defense for characters
@export_range(0, 5, 1) var willpower: int = 3 #More Defense and maybe More Meter gain lower the HP
@export var ground_throw_range: int = 70 #99% of peeps will be The default
@export var air_throw_range: int = 120 #99% of peeps will be The default

@export_category("Ground Movement")
#Walking
@export var fwd_walk_speed: int = 400 # 400 Avg; 550 Fast; 250 Slow;
@export var bwd_walk_speed: int = 300 # 300 Avg; 350 Fast ; 200 Slow
#Dashing
@export var dashType: DashType = DashType.Run
@export var dash_Startup: int = 4 #4 Is Default
@export var dash_int: int = 300 #
@export var dash_skid: int = 60 #
@export var dash_acc: int = 150 #
@export var dash_max: int = 450 #
#Backdash
@export var backdash_type: BackDashType = BackDashType.Step
@export var backdash: int = 30 ##Might move to State
@export var backdash_invul: int = 10 ##Might move to State
@export var backdash_distance: int = 400 #
@export var backdash_duration: int = 30 ##Might move to State

@export_category("Air Movement")
@export var prejump: int = 4 
@export var jump_velocity: int = -1500 ##Base Jump Height 1500, High 1700. Low 1300
@export var fwd_jump_velocity: int = -800
@export var bwd_jump_velocity: int = -800
@export var super_jump_velocity: int = -1650
@export var fwd_super_jump_velocity: int = -1650
@export var bwd_super_jump_velocity: int = -1650
@export var gravity: int = 4000
@export var air_Jumps: int = 1
@export var air_Dashes: int = 1

#Signals
signal health_depleted
signal break_full
signal health_changed(cur_health: int, max_health: int)
signal limit_changed(cur_limit: int, max_Limit: int)
signal break_changed(cur_break: int, max_break: int)

var curr_health: int = base_max_health : set = _on_health_set ## Characters Current Health Value
var curr_Limit: int = 0: set = _on_limit_set ## Characters Current Limit Value
var curr_break: int = 0: set = _on_break_set ## The Characters Break Gauge

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

func _on_break_set(new_value: int) -> void:
	curr_break = clampi(new_value, 0, base_Max_Break)
	break_changed.emit(curr_break, base_Max_Break)
	if curr_break == 100:
		break_full.emit()
	
