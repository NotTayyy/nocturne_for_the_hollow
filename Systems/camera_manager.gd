extends Node2D

var Player_1: Node2D
var Player_2: Node2D
var distance: float
var game_manager: Node

@export var cam_offset: Vector2 = Vector2(0, -300)
@export var max_zoom: Vector2 = Vector2(0.5, 0.5)
@export var min_zoom: Vector2 = Vector2(1., 1)
@export var zoom_speed: float = 5.0
@export var move_speed: float = 5.0

@export var left_limit: float = 0
@export var right_limit: float = 1920
@export var top_limit: float = 0
@export var bottom_limit: float = 1080

@onready var Foreground_camera: Camera2D = %Forground_Camera

func set_targets(P1: Node2D, P2: Node2D):
	Player_1 = P1
	Player_2 = P2

func _ready() -> void:
	await get_tree().process_frame
	game_manager = get_parent()
	
	if game_manager and G_HitboxTypes.Debug == true:
		print("Camera Manager Loaded!")

## Currently Working on ZOOM And Camera Placement at 1080p
#Need to make the Hud Scale wit hthe Cam
#Need the cam to move and shit.
func _process(_delta: float) -> void:
	if not Player_1 and not Player_2:
		return
	
	var midpoint = (Player_1.global_position + Player_2.global_position ) * 0.5
	midpoint.y += cam_offset.y
	
	midpoint.x = clamp(midpoint.x, left_limit, right_limit)
	midpoint.y = clamp(midpoint.y, top_limit, bottom_limit)
	Foreground_camera.global_position = Foreground_camera.global_position.lerp(midpoint, move_speed * _delta)
	
	var distamce = abs(Player_1.global_position.x - Player_2.global_position.x)
	var t = clamp(distance/ 1000.0, 0, 1)
	var target_zoom = min_zoom.lerp(max_zoom, t)
	
	Foreground_camera.zoom = Foreground_camera.zoom.lerp(target_zoom, zoom_speed * _delta)
