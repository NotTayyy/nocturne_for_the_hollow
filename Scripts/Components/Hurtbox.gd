class_name Hurtbox
extends Area2D

func _ready() -> void:
	monitoring  = false
	monitorable = true
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, false)
