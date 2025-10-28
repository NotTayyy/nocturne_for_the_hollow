class_name Stage extends StaticBody2D


func _on_wall_right_sticky_area_entered(area: Area2D) -> void:
	if not area.has_method("push_if_overlapping"):
		return
	
	area.owner.is_on_Wall_Right = true

func _on_wall_right_sticky_area_exited(area: Area2D) -> void:
	if not area.has_method("push_if_overlapping"):
		return
	
	area.owner.is_on_Wall_Right = false

func _on_wall_left_sticky_area_entered(area: Area2D) -> void:
	if not area.has_method("push_if_overlapping"):
		return
	
	area.owner.is_on_Wall_Left = true

func _on_wall_left_sticky_area_exited(area: Area2D) -> void:
	if not area.has_method("push_if_overlapping"):
		return
	
	area.owner.is_on_Wall_Left = false
