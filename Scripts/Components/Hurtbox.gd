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
func recieve_hit(damage: int) -> void:
	print(owner.char_data.character_name, " took ", damage, " Damage!")
	owner.char_data.health -= damage
