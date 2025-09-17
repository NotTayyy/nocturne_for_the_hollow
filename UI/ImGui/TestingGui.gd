extends Node

@onready var char_man = G_Refrences.character_manager
@onready var P1: Fighter = null
@onready var P2: Fighter = null
var fwd_walk_reset

func _ready() -> void:
	pass

func Collect():
		P1 = G_Refrences.P1
		P2 = G_Refrences.P2
		fwd_walk_reset = P1.char_data.fwd_walk_speed
		

func _process(_delta: float) -> void:
	if not P1 and P2 == null:
		Collect()
		print(P1," help ", P2)
		return
	ImGui.Begin("Player 1 Stats")
	if P1:
		ImGui.Text(P1.char_data.character_name)
		ImGui.Text("Fwd_Walk: " + str(P1.char_data.fwd_walk_speed))
		if ImGui.Button("+ Walk Speed"):
			P1.char_data.fwd_walk_speed += 25
		if ImGui.Button("- Walk Speed"):
			P1.char_data.fwd_walk_speed -= 25
		if ImGui.Button("Reset"):
			P1.char_data.fwd_walk_speed = fwd_walk_reset
		
	ImGui.End()
