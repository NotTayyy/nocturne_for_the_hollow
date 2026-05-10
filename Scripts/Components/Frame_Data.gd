@tool
extends Area2D
class_name HitboxFrameData

@export var FrameDataHitboxData : Array[FrameDataObject] = []

var clickCount : int = 0
var currentFrame = -1

func _get_tool_buttons():
	return [
		{displayName = "Add Single Frame Data", call = "Add1Frame"},
		{displayName = "Add Multi-Frame Data: 2 Hitboxes", call = "Add2Frame"},
		{displayName = "Add Multi-Frame Data: 3 Hitboxes", call = "Add3Frame"},
		{displayName = "Add Empty Frame Data", call = "AddEmptyFrame"},
		{displayName = "Clear Frame Data", call = "ClearFrameData"},
	]


func start():
	pass

func next_frame():
	pass

func end():
	pass

func ClearFrameData():
	pass

func Add1Frame():
	pass

func Add2Frame():
	pass

func Add3Frame():
	pass

func AddEmptyFrame():
	pass
