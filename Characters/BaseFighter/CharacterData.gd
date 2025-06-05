extends Resource
class_name CharacterData

enum DashType { Step, Run, Teleport, Hover, None }
enum BackDashType { Step, Hover, Run }

@export_category("Lore Data")
@export var character_name: String = "Default Fighter"

@export_category("Meta Data")
@export var fighter_scene: PackedScene
@export var command_list: CommandData
@export var neg_edge: bool = false
@export var charge_moves: bool = false

@export_category("Basics Data")
@export var max_health: int = 15000
#If the player moves back to much or isnt attacking we will give them a neg Debuff
@export_range(1, 5, 1) var negative_Penalty_Res: int = 3
#This is like Defense? Take less damage the tougher they are
@export_range(0, 5, 1) var toughness: int = 3 #Might Not Use
@export_range(0, 5, 1) var guts: int = 3
@export var ground_throw_range: int = 70
@export var air_throw_range: int = 120

@export_category("Ground Movement")
@export var dashType: DashType = DashType.Run
@export var fwd_walk_speed: int = 200
@export var bwd_walk_speed: int = 140
@export var dash_Startup: int = 4
@export var run_int: int = 300
@export var run_skid: int = 60
@export var run_acc: int = 150
@export var run_max: int = 450
@export var backdash_type: BackDashType = BackDashType.Run
@export var backdash: int = 30
@export var backdash_invuln: int = 10
@export var backdash_distance: int = 400
@export var backdash_duration: int = 30

@export_category("Air Movement")
@export var prejump: int = 4
@export var jump_velocity: int = -1350
@export var fwd_jump_velocity: int = -800
@export var bwd_jump_velocity: int = -800
@export var super_jump_velocity: int = -1650
@export var fwd_super_jump_velocity: int = -1650
@export var bwd_super_jump_velocity: int = -1650
@export var gravity: int = 3500
@export var air_Jumps: int = 1
@export var air_Dashes: int = 1
