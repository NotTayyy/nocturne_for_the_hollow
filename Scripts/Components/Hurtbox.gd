class_name Hurtbox
extends Area2D

func _ready() -> void:
	monitoring   = false
	monitorable  = true
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, false)

## Called by HitboxFrameData._on_area_entered via ComboManager
## The HitResult already has damage calculated — just receive it
func recieve_hit(result : HitResult) -> void:
	pass  # All handling done in Fighter.recieve_hit via ComboManager
