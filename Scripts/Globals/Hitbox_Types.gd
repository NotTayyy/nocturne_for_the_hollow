extends Node

@onready var Debug: bool = true

enum HitboxType {
	NONE,
	GRAB,
	PROJECTILE,
	COLLISION,
	HURTBOX,
	HITBOX
}
