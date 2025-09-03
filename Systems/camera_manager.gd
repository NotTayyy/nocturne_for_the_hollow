extends Node2D

var Player_1: Node2D
var Player_2: Node2D
var distance: float
var game_manager: Node

@export var max_zoom: Vector2 = Vector2(1.2, 1.2)
@export var min_zoom: Vector2 = Vector2(1.5, 1.5)
@export var min_vertical_offset: Vector2 = Vector2(0, -163)
@export var max_vertical_offset: Vector2 = Vector2(0, -225)
@export var zoom_speed: float = 8
@export var move_speed: float = 8

@export var min_distance: float = 850
@export var max_distance: float = 1200 

@export var left_limit: float = -1920
@export var right_limit: float = 1920
@export var top_limit: float = 0
@export var bottom_limit: float = 355

@export var jump_limit: float = 200
@export var floor: float = 170
@export var wall_speed: int = 5

@onready var Foreground_camera: Camera2D = %Forground_Camera
@onready var coords_loc: Label = $Forground_Camera/CanvasLayer/Control/Label
@onready var Walls = $Walls

func set_targets(P1: Node2D, P2: Node2D):
	Player_1 = P1
	Player_2 = P2

func _ready() -> void:
	await get_tree().process_frame
	game_manager = get_parent()
	
	
	
	if game_manager and G_HitboxTypes.Debug == true:
		print("Camera Manager Loaded!")
## Currently Working on ZOOM And Camera Placement at 1080p
func _process(_delta: float) -> void:
	if not Player_1 and not Player_2:
		return
	
	
	var midpoint = (Player_1.global_position + Player_2.global_position ) * 0.5
	var highest_y = min(Player_1.global_position.y, Player_2.global_position.y)
	var t: float = 0.0
	
	
	midpoint.x = clamp(midpoint.x, left_limit, right_limit)
	midpoint.y = clamp(midpoint.y, top_limit, bottom_limit)
	distance = abs(Player_1.global_position.x - Player_2.global_position.x)
	
	if distance <= min_distance:
		t = 0
	elif distance >= max_distance:
		t = 1
	else:
		t = (distance - min_distance) / (max_distance - min_distance)
	
	var target_zoom = min_zoom.lerp(max_zoom, t)
	var target_offset = min_vertical_offset.lerp(max_vertical_offset, t)
	
	if highest_y < jump_limit:
		midpoint.y = highest_y + 100
	else:
		midpoint.y = floor + target_offset.y

	Walls.global_position.x = lerpf(Walls.global_position.x, midpoint.x, wall_speed * _delta)
	Foreground_camera.global_position.y = lerpf(Foreground_camera.global_position.y, midpoint.y, move_speed * _delta)
	Foreground_camera.global_position.x = lerpf(Foreground_camera.global_position.x, midpoint.x, move_speed * _delta)
	Foreground_camera.zoom = Foreground_camera.zoom.lerp(target_zoom, zoom_speed * _delta)
