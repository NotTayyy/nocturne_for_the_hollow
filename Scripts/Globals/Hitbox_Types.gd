extends Node

@onready var Debug: bool = false

enum HitboxType {
	NONE,
	GRAB,
	PROJECTILE,
	COLLISION,
	HURTBOX,
	HITBOX
}
