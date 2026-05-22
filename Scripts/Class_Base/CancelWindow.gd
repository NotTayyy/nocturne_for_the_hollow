extends Resource
class_name CancelWindow

@export var on_hit   : bool = false
@export var on_block : bool = false
@export var on_whiff : bool = false

func is_available(hit: bool, blocked: bool) -> bool:
	if hit     and on_hit:   return true
	if blocked and on_block: return true
	if on_whiff:             return true
	return false
