extends Node2D

var P1
var P2
var p1_max_y : float = 0.0
var p2_max_y : float = 0.0

# Timescale / frame step
var _timescale    : float = 1.0
var _frame_step   : bool  = false   # true = game is paused for frame stepping
var _step_queued  : bool  = false   # true = advance one frame next physics tick

func _ready() -> void:
	# Keep debug overlay running even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	for action in ["debug_pause", "debug_step"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	# Default: F1 = pause/unpause frame step, F2 = advance one frame
	if InputMap.action_get_events("debug_pause").is_empty():
		var e := InputEventKey.new()
		e.keycode = KEY_F1
		InputMap.action_add_event("debug_pause", e)
	if InputMap.action_get_events("debug_step").is_empty():
		var e := InputEventKey.new()
		e.keycode = KEY_F2
		InputMap.action_add_event("debug_step", e)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if event.is_action_pressed("debug_pause"):
		_frame_step = not _frame_step
		if _frame_step:
			get_tree().paused = true
			_set_timescale(1.0)
		else:
			get_tree().paused = false

	if _frame_step and event.is_action_pressed("debug_step"):
		_step_queued = true

func _physics_process(_delta: float) -> void:
	if _frame_step and _step_queued:
		_step_queued = false
		# We're already in a physics frame right now — re-pause after this tick
		await get_tree().physics_frame
		get_tree().paused = true

func _process(_delta: float) -> void:
	if Global.game_manager.current_state != Global.game_manager.GameState.MID_MATCH:
		return
	if P1 == null or P2 == null:
		set_vars()

	if P1:
		if P1.velocity.y < p1_max_y: p1_max_y = P1.velocity.y
	if P2:
		if P2.velocity.y < p2_max_y: p2_max_y = P2.velocity.y

	ImGui.Begin("Players")

	ImGui.PushID("Player1")
	imgui_player_root("Player 1", P1, p1_max_y)
	ImGui.PopID()

	ImGui.Separator()

	ImGui.PushID("Player2")
	imgui_player_root("Player 2", P2, p2_max_y)
	ImGui.PopID()

	ImGui.Separator()
	imgui_timescale()

	ImGui.End()

# =============================================================================
# Root Player Dropdown
# =============================================================================
func imgui_player_root(label: String, player, max_y: float) -> void:
	if player == null: return
	if ImGui.CollapsingHeader(label):
		imgui_core_info(player)
		imgui_health_info(player)
		imgui_movement_info(player, max_y)
		imgui_state_info(player)
		imgui_property_info(player)
		imgui_input_info(player)

# =============================================================================
# Core Info
# =============================================================================
func imgui_core_info(player) -> void:
	if ImGui.TreeNode("Core"):
		ImGui.Text("Player ID: " + str(player.player_id))
		ImGui.Text("Name: "      + str(player.char_data.character_name))
		ImGui.TreePop()

# =============================================================================
# Health Info
# =============================================================================
func imgui_health_info(player) -> void:
	if ImGui.TreeNode("Health"):
		var curr  : int   = player.char_data.curr_health
		var max_hp: int   = player.char_data.base_max_health
		var pct   : float = float(curr) / float(max_hp)
		ImGui.TextColored(Color(1.0 - pct, pct, 0.0, 1.0),
			"HP: %d / %d (%.0f%%)" % [curr, max_hp, pct * 100])
		ImGui.TreePop()

# =============================================================================
# Movement / Physics
# =============================================================================
func imgui_movement_info(player, max_y: float) -> void:
	if ImGui.TreeNode("Movement"):
		ImGui.Text("Facing:    " + str(player.dir_facing))
		ImGui.Text("Airborne:  " + str(player.is_airborne))
		ImGui.Text("Vel X:     %.1f" % player.velocity.x)
		ImGui.Text("Vel Y:     %.1f" % player.velocity.y)
		ImGui.Text("Peak Y:    %.1f" % max_y)
		if ImGui.Button("Reset Peak"):
			if player == P1: p1_max_y = 0.0
			else:            p2_max_y = 0.0
		ImGui.TreePop()

# =============================================================================
# State Machine — state, phase, frame counter, gates, invul
# =============================================================================
func imgui_state_info(player) -> void:
	if ImGui.TreeNode("State Machine"):
		var sm : State_Manager = player.state_machine
		var st : State_Base    = sm.active_state

		if st == null:
			ImGui.Text("No active state")
			ImGui.TreePop()
			return

		# --- Current state ---
		ImGui.TextColored(Color.CYAN, "State: " + st.state_id)
		ImGui.Text("Frame:        %d" % st.frame)
		ImGui.Text("Apply Gravity: " + str(st.apply_gravity))

		ImGui.Spacing()

		# --- Phase / duration display ---
		# Show phase info for states that have a _phase var and _timer var
		if "_phase" in st:
			var phase_names := _get_phase_names(st)
			var phase_idx   : int = st._phase
			var phase_label : String = phase_names[phase_idx] if phase_idx < phase_names.size() else str(phase_idx)
			ImGui.TextColored(Color.YELLOW, "Phase: " + phase_label)

		if "_timer" in st:
			ImGui.Text("Timer:  %d" % st._timer)

		# Frame progress bar — shows how far through current timer we are
		if "_timer" in st and st._timer >= 0:
			var max_timer := _get_max_timer(st)
			if max_timer > 0:
				var progress := 1.0 - (float(st._timer) / float(max_timer))
				ImGui.ProgressBar(progress, Vector2(200, 14),
					"%.0f%%" % (progress * 100))

		ImGui.Spacing()

		# --- Cancel gates ---
		if ImGui.TreeNode("Cancel Gates"):
			_gate_row("Self",      st.gate_self)
			_gate_row("Special",   st.gate_special)
			_gate_row("Drive",     st.gate_drive)
			_gate_row("Overdrive", st.gate_overdrive)
			_gate_row("Jump",      st.gate_jump)
			_gate_row("Rapid",     st.gate_rapid)
			_gate_row("Dash",      st.gate_dash)
			_gate_row("Backdash",  st.gate_backdash)
			_gate_row("Burst",     st.gate_burst)
			_gate_row("Barrier",   st.gate_barrier)
			ImGui.TreePop()

		# --- Invul flags ---
		if ImGui.TreeNode("Invul"):
			_gate_row("Strike",  st.invul_strike)
			_gate_row("Throw",   st.invul_throw)
			_gate_row("Burst",   st.invul_burst)
			_gate_row("All",     st.invul_all)
			ImGui.TreePop()

		# --- Airborne state stocks ---
		if ImGui.TreeNode("Aerial Stocks"):
			ImGui.Text("Jumps left:  %d / %d" % [player.jumps_remaining,  player.char_data.air_Jumps])
			ImGui.Text("Dashes left: %d / %d" % [player.dashes_remaining, player.char_data.air_Dashes])
			ImGui.Text("Lockout:     %d"       % st._lockout_timer)
			ImGui.TreePop()

		ImGui.TreePop()

# =============================================================================
# Transform
# =============================================================================
func imgui_property_info(player) -> void:
	if ImGui.TreeNode("Properties (%d)" % player.properties.size()):
		if player.properties.is_empty():
			ImGui.TextDisabled("None active")
		else:
			for p in player.properties:
				var dur_str   := "\u221e" if p.duration == -1 else str(p.duration) + "f"
				var stack_str := " [stack]" if p.does_stack else ""
				ImGui.TextColored(p.get_color(), "\u25cf %s" % p.get_name())
				ImGui.SameLine()
				ImGui.TextDisabled("%s  owner:%s  val:%.2f%s" % [
					dur_str, p.owner, p.value, stack_str
				])
		ImGui.TreePop()

# =============================================================================
# Transform
	if ImGui.TreeNode("Transform"):
		ImGui.Text("Position: (%.1f, %.1f)" % [player.global_position.x, player.global_position.y])
		ImGui.Text("Scale:    (%.2f, %.2f)" % [player.scale.x, player.scale.y])
		ImGui.TreePop()

# =============================================================================
# Input Buffer — BBCF-style event log
# =============================================================================
func imgui_input_info(player) -> void:
	if not player.has_node("InputBuffer"):
		return
	if ImGui.TreeNode("Input Buffer"):
		var buf : InputBuffer = player.input_buffer

		# Held inputs
		ImGui.TextColored(Color.GREEN, "Held: " + _format_held(buf.held_inputs, player.dir_facing == "Right"))

		# Buffered command
		if not buf._buffered_command.is_empty():
			var age := Engine.get_physics_frames() - buf._buffered_command_frame
			ImGui.TextColored(Color.ORANGE,
				"Buffered: %s  [%d/%d]" % [
					buf._buffered_command.get("Command","?"),
					age, buf.BUFFER_WINDOW
				])
		else:
			ImGui.TextDisabled("Buffered: none")

		ImGui.Separator()

		# Build grouped rows — one row per frame, direction + buttons together
		var log   : Array = buf.event_log
		var start : int   = maxi(0, log.size() - 60)
		var rows  : Array = []
		var i     : int   = start

		while i < log.size():
			var e   = log[i]
			var row = { "frame": e["frame"], "dir": "5", "pressed": [], "released": [] }
			while i < log.size() and log[i]["frame"] == e["frame"]:
				var ev = log[i]
				if ev["action"] in InputBuffer.DIRECTIONS:
					row["dir"] = ev["action"]
				elif ev["type"] == "press":
					row["pressed"].append(ev["action"])
				else:
					row["released"].append(ev["action"])
				i += 1
			rows.append(row)

		# Render — most recent at bottom
		var facing_right : bool = player.dir_facing == "Right"
		for r in rows:
			var arrow : String = _dir_to_arrow(r["dir"], facing_right)
			ImGui.PushID(r["frame"])
			if not r["pressed"].is_empty():
				ImGui.TextColored(Color.WHITE, arrow)
				for btn in r["pressed"]:
					ImGui.SameLine()
					ImGui.TextColored(_btn_color(btn), btn)
			elif not r["released"].is_empty():
				ImGui.TextColored(Color(0.45, 0.45, 0.45), arrow)
				for btn in r["released"]:
					ImGui.SameLine()
					ImGui.TextColored(Color(0.35, 0.35, 0.35), "(%s)" % btn)
			else:
				ImGui.TextColored(Color(0.55, 0.75, 0.55), arrow)
			ImGui.SameLine()
			ImGui.TextDisabled("f%d" % r["frame"])
			ImGui.PopID()

		ImGui.TreePop()

func _format_held(held: Dictionary, facing_right: bool) -> String:
	var dirs : Array = []
	var btns : Array = []
	for k in held.keys():
		if k in InputBuffer.DIRECTIONS: dirs.append(_dir_to_arrow(k, facing_right))
		else:                           btns.append(k)
	return " ".join(dirs) + ("  " if not btns.is_empty() else "") + " ".join(btns)

func _dir_to_arrow(dir: String, facing_right: bool) -> String:
	var r := {"1":"\U0001f882","2":"\U0001f883","3":"\U0001f886","4":"\U0001f880","5":"·","6":"\U0001f882","7":"\U0001f884","8":"\U0001f881","9":"\U0001f885"}
	var l := {"1":"\U0001f886","2":"\U0001f883","3":"\U0001f882","4":"\U0001f882","5":"·","6":"\U0001f880","7":"\U0001f885","8":"\U0001f881","9":"\U0001f884"}
	return (r if facing_right else l).get(dir, dir)

func _btn_color(btn: String) -> Color:
	match btn:
		"A":  return Color(0.4, 0.9, 0.4)
		"B":  return Color(0.4, 0.6, 1.0)
		"C":  return Color(1.0, 0.3, 0.3)
		"D":  return Color(1.0, 0.8, 0.2)
		_:    return Color.WHITE

# Timescale / Frame Step
# =============================================================================
func imgui_timescale() -> void:
	if ImGui.TreeNode("Timescale / Frame Step"):

		# --- Frame step ---
		var step_label := "▶ Resume (F1)" if _frame_step else "⏸ Frame Step (F1)"
		if ImGui.Button(step_label):
			_frame_step = not _frame_step
			if _frame_step:
				get_tree().paused = true
				_set_timescale(1.0)
			else:
				get_tree().paused = false

		if _frame_step:
			ImGui.SameLine()
			if ImGui.Button("→ Step (F2)"):
				_step_queued = true
			ImGui.TextColored(Color.ORANGE, "PAUSED — F2 to advance one frame")
		else:
			ImGui.Spacing()

			# --- Timescale ---
			ImGui.Text("Speed: %.2f×  (%d Hz)" % [_timescale, Engine.physics_ticks_per_second])

			if ImGui.Button("1/8"): _set_timescale(0.125)
			ImGui.SameLine()
			if ImGui.Button("1/4"): _set_timescale(0.25)
			ImGui.SameLine()
			if ImGui.Button("1/2"): _set_timescale(0.5)
			ImGui.SameLine()
			if ImGui.Button("1×"):  _set_timescale(1.0)
			ImGui.SameLine()
			if ImGui.Button("2×"):  _set_timescale(2.0)

			var ts := [_timescale]
			if ImGui.SliderFloat("##ts", ts, 0.05, 3.0):
				_set_timescale(ts[0])

		ImGui.TreePop()

func _set_timescale(t: float) -> void:
	_timescale = t
	Engine.physics_ticks_per_second = int(60.0 * t)

# =============================================================================
# Helpers
# =============================================================================
func _gate_row(label: String, value: bool) -> void:
	var color := Color.LIME_GREEN if value else Color(0.4, 0.4, 0.4)
	ImGui.TextColored(color, ("✓ " if value else "✗ ") + label)

func _get_phase_names(st: State_Base) -> Array:
	# Try to get phase enum names from the state class
	match st.state_id:
		"Dash":        return ["STARTUP", "ACTIVE", "RECOVERY"]
		"BackDash":    return ["INVUL",   "ACTIVE", "RECOVERY"]
		"AirDash":     return ["ACTIVE"]
		"AirBackDash": return ["ACTIVE"]
		_:             return []

func _get_max_timer(st: State_Base) -> int:
	# Return the starting value of the timer for the current phase
	# Used to draw the progress bar
	var cd = st.fighter.char_data if st.fighter else null
	if cd == null: return 0
	match st.state_id:
		"Dash":
			match st._phase:
				0: return cd.dash_Startup   # STARTUP
				1: return cd.dash_int       # ACTIVE
				_: return cd.dash_skid
		"BackDash":
			match st._phase:
				0: return cd.backdash_invul_start
				1: return cd.backdash_duration - cd.backdash_invul_end
				_: return 8
		_: return 0

# =============================================================================
# Setup
# =============================================================================
func set_vars() -> void:
	P1 = Global.P1
	P2 = Global.P2
