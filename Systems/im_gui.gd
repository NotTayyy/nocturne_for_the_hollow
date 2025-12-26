extends Node2D

var P1
var P2

func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	if Global.game_manager.current_state != Global.game_manager.GameState.MID_MATCH:
		return

	if P1 == null or P2 == null:
		set_vars()

	ImGui.Begin("Players")

	# ---------- PLAYER 1 ----------
	ImGui.PushID("Player1")
	imgui_player_root("Player 1", P1)
	ImGui.PopID()

	ImGui.Separator()

	# ---------- PLAYER 2 ----------
	ImGui.PushID("Player2")
	imgui_player_root("Player 2", P2)
	ImGui.PopID()

	ImGui.End()


# =========================
# Root Player Dropdown
# =========================
func imgui_player_root(label: String, player) -> void:
	if player == null:
		return

	if ImGui.CollapsingHeader(label):
		imgui_core_info(player)
		imgui_health_info(player)
		imgui_movement_info(player)
		imgui_state_info(player)
		imgui_transform_info(player)
		imgui_input_info(player)


# =========================
# Core Info
# =========================
func imgui_core_info(player) -> void:
	if ImGui.TreeNode("Core"):
		ImGui.Text("Player ID: " + str(player.player_id))
		ImGui.Text("Name: " + str(player.char_data.character_name))
		ImGui.TreePop()


# =========================
# Health Info
# =========================
func imgui_health_info(player) -> void:
	if ImGui.TreeNode("Health"):
		var curr : int = player.char_data.curr_health
		var max_hp : int = player.char_data.base_max_health
		var pct := float(curr) / float(max_hp)

		ImGui.TextColored(
			Color(1.0 - pct, pct, 0.0, 1.0),
			"HP: %d / %d" % [curr, max_hp]
		)

		ImGui.TreePop()


# =========================
# Movement / Facing
# =========================
func imgui_movement_info(player) -> void:
	if ImGui.TreeNode("Movement"):
		ImGui.Text("Facing Dir: " + str(player.dir_facing))
		ImGui.Text("Move Dir: " + str(player.dir))
		ImGui.Text("Airborne: " + str(player.is_airborn))
		ImGui.TreePop()


# =========================
# State Machine
# =========================	
func imgui_state_info(player) -> void:
	if not player.has_node("StateMachine"):
		return

	if ImGui.TreeNode("State"):
		var sm = player.state_machine
		ImGui.Text("Current State: " + sm.current_state.name)
		ImGui.Text("Can Cancel: " + str(player.can_cancel))
		ImGui.Text("In Hitstop: " + str(player.in_hitstop))
		ImGui.TreePop()


# =========================
# Transform Info
# =========================
func imgui_transform_info(player) -> void:
	if ImGui.TreeNode("Transform"):
		ImGui.Text("Global Position: " + str(player.global_position))
		ImGui.Text("Scale: " + str(player.scale))
		ImGui.Text("Rotation: " + str(player.rotation))
		ImGui.TreePop()


# =========================
# Input Buffer
# =========================
func imgui_input_info(player) -> void:
	if not player.has_node("InputBuffer"):
		return

	if ImGui.TreeNode("Input Buffer"):
		var buffer = player.input_buffer.buffer_history

		for i in buffer.size():
			ImGui.PushID(i)
			var entry = buffer[i]
			ImGui.Text(
				"%s (%s) @ %d"
				% [
					entry["action"],
					entry["type"],
					entry["action_frame"]
				]
			)
			ImGui.PopID()

		ImGui.TreePop()


# =========================
# Global Player References
# =========================
func set_vars() -> void:
	P1 = Global.P1
	P2 = Global.P2
