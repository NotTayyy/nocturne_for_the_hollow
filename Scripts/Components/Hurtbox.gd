class_name Hurtbox extends Area2D

enum hurtbox_Attribute {
	Head,
	Body,
	Foot
}

func _ready() -> void:
	monitoring = false
	set_collision_mask_value(1, false)

#Signal
func recieve_hit(damage: int, type:) -> void:
	print(owner.char_data.character_name, " took ", damage, " Damage of Type - ", Hitbox.HitboxType.find_key(type))
	owner.char_data.curr_health -= damage
