class_name HitLog extends RefCounted

var hit_log: Array = []

func has_hit(node: Node) -> bool:
	return hit_log.has(node)

func log_hit(node: Node) -> void:
	hit_log.append(node)
