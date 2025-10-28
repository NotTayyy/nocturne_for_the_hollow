class_name Hitbox extends Area2D

var damage: int
var lifetime: float
var hitbox_size: Vector2
var hitbox_pos: Vector2
var Player: int #The owning player ID
var hit_log: HitLog


enum HitboxType {
	Attack,
	Throw,
	Projectile,
	Strike_Throw,
	Summon,
	Burst
}


func _init(_damage: int, _lifetime: float, _hitbox_size: Vector2, _hitbox_pos: Vector2, _player: int, _hitlog: HitLog = null) -> void:
	damage = _damage
	lifetime = _lifetime
	hitbox_size = _hitbox_size
	Player = _player
	hit_log = _hitlog
	hitbox_pos = _hitbox_pos

func _ready() -> void:
	monitorable = false
	set_collision_layer_value(1, false)
	
	area_entered.connect(_on_area_entered)
	
	#Lifetime Making
	var new_time = Timer.new()
	add_child(new_time)
	new_time.timeout.connect(queue_free)
	new_time.call_deferred("start", lifetime)

	#Collision Making
	var collision = CollisionShape2D.new()
	var hitbox_shape = RectangleShape2D.new()
	hitbox_shape.size = hitbox_size
	collision.shape = hitbox_shape
	add_child(collision)
	
	self.position = hitbox_pos
	
	

func _on_area_entered(area: Area2D) -> void:
	if not area.has_method("recieve_hit"):
		return
	if area.owner.player_id == Player:
		return
	
	var hurtbox_owner = area.owner
	if hit_log:
		if hit_log.has_hit(hurtbox_owner):
			return
		else:
			hit_log.log_hit(hurtbox_owner)
	
	area.recieve_hit(damage)
