extends Node2D

var Player_1
var Player_2
var game_manager 
var distance: float

var max_zoom: Vector2 = Vector2(1.2, 1.2)
var min_zoom: Vector2 = Vector2(1.5, 1.5)
var min_vertical_offset: Vector2 = Vector2(0, -163)
var max_vertical_offset: Vector2 = Vector2(0, -225)
var min_distance: float = 850
var max_distance: float = 1200 
var cam_top_move: float = 70
var cam_floor: float = 330
var t: float = 0.0

var wall_speed: int = 6
var zoom_speed: float = 8
var move_speed: float = 8
var Walls: StaticBody2D

@onready var Foreground_camera: Camera2D = %Forground_Camera


func _ready() -> void:
	game_manager = get_parent()
	Global.camera_manager = self
	Global.UI = $Forground_Camera/UI

	if game_manager and game_manager.Debug == true:
		print("Camera Manager Loaded!")

func _process(_delta: float) -> void:
	if not Player_1 and not Player_2:
		Player_1 = Global.P1
		Player_2 = Global.P2
		return
		
	if not Walls:
		Walls = Global.Walls 
		return
	
	var midpoint = (Player_1.global_position + Player_2.global_position ) * 0.5
	var highest_y = min(Player_1.global_position.y, Player_2.global_position.y)
	
	distance = abs(Player_1.global_position.x - Player_2.global_position.x)
	t = clamp(inverse_lerp(min_distance, max_distance, distance), 0.0, 1.0)
	
	var target_zoom = min_zoom.lerp(max_zoom, t)
	var target_offset = min_vertical_offset.lerp(max_vertical_offset, t)
	
	midpoint.y = highest_y if highest_y < cam_top_move else cam_floor + target_offset.y

	Walls.global_position.x = lerpf(Walls.global_position.x, midpoint.x, wall_speed * _delta)
	Foreground_camera.global_position.y = lerpf(Foreground_camera.global_position.y, midpoint.y, move_speed * _delta)
	Foreground_camera.global_position.x = lerpf(Foreground_camera.global_position.x, midpoint.x, move_speed * _delta)
	Foreground_camera.zoom = Foreground_camera.zoom.lerp(target_zoom, zoom_speed * _delta)
