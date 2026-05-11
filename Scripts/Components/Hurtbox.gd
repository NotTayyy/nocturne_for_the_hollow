class_name Hurtbox
extends Area2D

enum hurtbox_Attribute {
	Head,
	Body,
	Foot
}

func _ready() -> void:
	monitoring   = false   # hurtbox doesn't detect — it gets detected
	monitorable  = true    # can be found by hitboxes
	set_collision_layer_value(1, true)   # Layer 1 — hurtbox layer
	set_collision_mask_value(1, false)

func recieve_hit(damage : int, type : int) -> void:
	print(owner.char_data.character_name, " took ", damage, " damage")
	owner.char_data.curr_health -= damage
