extends Resource
class_name CharacterData

enum DashType { Step, Run, Teleport, Hover, None }

@export var character_name: String = "Default Fighter"

@export_category("Meta Data")
@export var fighter_scene: PackedScene

@export_category("Basics Data")
@export var max_health: int = 13000
@export var negative_debuff_Res: int = 3
@export_range(0, 5, 1) var toughness: int = 3
@export_range(0, 5, 1) var guts: int = 2

@export_category("Ground Movement")
@export var dashType: DashType = DashType.Run
@export var fwd_walk_speed: float = 200
@export var bwd_walk_speed: float = 140
@export var forward_dash: int = 0
@export var run_int: float = 300
#@export var run_acc: int = 150
#@export var run_max: float = 450
@export var backdash: int = 30
@export var backdash_Invuln: int = 10
@export var backdash_Distance: int = 400

@export_category("Air Movement")
@export var prejump: int = 4
@export var jump_velocity: float = -1350
@export var fwd_jump_velocity: float = -800
@export var bwd_jump_velocity: float = -800
@export var super_jump_velocity: float = -1650
@export var fwd_super_jump_velocity: float = -1650
@export var bwd_super_jump_velocity: float = -1650
@export var gravity: float = 3500
@export var air_Jumps: int = 1
@export var air_Dashes: int = 1
