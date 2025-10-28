extends Fighter


func _ready() -> void:
	super._ready()
	
	char_data.health_depleted.connect(_NoHP)

func _process(_delta: float) -> void:
	pass

func _NoHP():
	queue_free()
