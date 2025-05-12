extends Node2D

var Player_1: Node2D
var Player_2: Node2D

var game_manager: Node

@onready var Foreground_camera: Camera2D = %Forground_Camera
@onready var Background_camera: Camera2D = %Background_Camera

func set_targets(P1: Node2D, P2: Node2D):
	Player_1 = P1
	Player_2 = P2

func _ready() -> void:
	await get_tree().process_frame
	game_manager = get_parent()
	
	if game_manager:
		print("Camera Manager Loaded!")

func _process(delta: float) -> void:
	var midpoint: Vector2 = (Player_1.global_position + Player_2.global_position) * 0.5 + Vector2(0, -120)
	move_Camera(midpoint)

func move_Camera(mid: Vector2):
	Foreground_camera.global_position = mid
	Background_camera.global_position = mid
