class_name Pushbox extends Area2D

var enemy_collision
@onready var collision = $CollisionShape2D

func _ready() -> void:
	set_collision_mask_value(1, false)
	set_collision_layer_value(1, false)

	set_collision_layer_value(13, true)

func _physics_process(_delta: float) -> void:
	push_if_overlapping()

func push_if_overlapping() -> void:
	var my_rect: Rect2 = Rect2(collision.global_position - collision.shape.extents, collision.shape.extents * 2)
	var enemy_rect: Rect2 = Rect2(enemy_collision.global_position - enemy_collision.shape.extents, enemy_collision.shape.extents * 2)
	var opponent = enemy_collision.owner
	
	if my_rect.intersects(enemy_rect):
		var overlap = my_rect.intersection(enemy_rect)
		if overlap.size.x < overlap.size.y:
			var push_distance = overlap.size.x / 2
			
			#Checks if corner fight is happening, THe higher player loses and is Pushed off
			if is_on_wall(owner) and is_on_wall(opponent) == true:
				if my_rect.position.y < enemy_rect.position.y:
					owner.is_on_Wall_Left = false
					owner.is_on_Wall_Right = false
					return
			
			if owner.is_on_Wall_Left == true:
				opponent.global_position.x += push_distance * 2
				return
			elif owner.is_on_Wall_Right == true:
				opponent.global_position.x -= push_distance * 2
				return
			else:
				if my_rect.position.x < enemy_rect.position.x:
					owner.global_position.x -= push_distance
				else:
					owner.global_position.x += push_distance
					
func is_on_wall(checker: Node) -> bool:
	return checker.is_on_Wall_Left or checker.is_on_Wall_Right
