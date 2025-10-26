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
@export var base_max_health: int = 12500 
@export var current_max_health:int = 12500
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
@export var backdash: int = 30 #Might move to State
@export var backdash_invul: int = 10 #Might move to State
@export var backdash_distance: int = 400 #
@export var backdash_duration: int = 30 #Might move to State

@export_category("Air Movement")
@export var prejump: int = 4 #
@export var jump_velocity: int = -1500 #Base Jump Height 1500, High 1700. Low 1300
@export var fwd_jump_velocity: int = -800
@export var bwd_jump_velocity: int = -800
@export var super_jump_velocity: int = -1650
@export var fwd_super_jump_velocity: int = -1650
@export var bwd_super_jump_velocity: int = -1650
@export var gravity: int = 4000
@export var air_Jumps: int = 1
@export var air_Dashes: int = 1

signal health_depleted
signal health_changed(cur_health: int, max_health: int)

##Testing Out InResource Stats Instead Of Health Component
var health: int = 0: set = _on_health_set

func _init() -> void:
	setup_stats.call_deferred()

func setup_stats() -> void:
	health = base_max_health
	print(health, " ", character_name)

func _on_health_set(new_value: int) -> void:
	health = clampi(new_value, 0, current_max_health)
	health_changed.emit(health, current_max_health)
	if health <= 0:
		health_depleted.emit()
