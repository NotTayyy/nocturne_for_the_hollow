extends Node2D

var P1
var P2
var p1_max_y : float = 0.0
var p2_max_y : float = 0.0

# Last attack data cache — persists after attack ends
var _p1_last_md  : MoveData        = null
var _p1_last_hfd : HitboxFrameData = null
var _p2_last_md  : MoveData        = null
var _p2_last_hfd : HitboxFrameData = null

# Timescale / frame step
var _timescale    : float = 1.0
var _frame_step   : bool  = false
var _step_queued  : bool  = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for action in ["debug_pause", "debug_step"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
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

	ImGui.SetNextWindowCollapsed(false, 4)
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
		imgui_attack_info(player)
		imgui_property_info(player)
		imgui_transform_info(player)

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
# State Machine
# =============================================================================
func imgui_state_info(player) -> void:
	if ImGui.TreeNode("State Machine"):
		var sm : State_Manager = player.state_machine
		var st : State_Base    = sm.active_state

		if st == null:
			ImGui.Text("No active state")
			ImGui.TreePop()
			return

		ImGui.TextColored(Color.CYAN, "State: " + st.state_id)
		ImGui.Text("Frame:         %d" % st.frame)
		ImGui.Text("Apply Gravity: " + str(st.apply_gravity))

		ImGui.Spacing()

		if "_phase" in st:
			var phase_names := _get_phase_names(st)
			var phase_idx   : int    = st._phase
			var phase_label : String = phase_names[phase_idx] if phase_idx < phase_names.size() else str(phase_idx)
			ImGui.TextColored(Color.YELLOW, "Phase: " + phase_label)

		if "_timer" in st:
			ImGui.Text("Timer:  %d" % st._timer)

		if "_timer" in st and st._timer >= 0:
			var max_timer := _get_max_timer(st)
			if max_timer > 0:
				var progress := 1.0 - (float(st._timer) / float(max_timer))
				ImGui.ProgressBar(progress, Vector2(200, 14), "%.0f%%" % (progress * 100))

		ImGui.Spacing()

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

		if ImGui.TreeNode("Invul"):
			_gate_row("Strike",     st.invul_strike)
			_gate_row("Throw",      st.invul_throw)
			_gate_row("Burst",      st.invul_burst)
			_gate_row("Head",       st.invul_head)
			_gate_row("Foot",       st.invul_foot)
			_gate_row("Projectile", st.invul_projectile)
			_gate_row("All",        st.invul_all)
			ImGui.TreePop()

		if ImGui.TreeNode("Aerial Stocks"):
			ImGui.Text("Jumps left:  %d / %d" % [player.jumps_remaining,  player.char_data.air_Jumps])
			ImGui.Text("Dashes left: %d / %d" % [player.dashes_remaining, player.char_data.air_Dashes])
			ImGui.Text("Lockout:     %d"       % st.lockout_timer)
			ImGui.TreePop()

		ImGui.TreePop()

# =============================================================================
# Attack Data — always visible, caches last move
# =============================================================================
func imgui_attack_info(player) -> void:
	var is_p1     : bool          = player == P1
	var sm        : State_Manager = player.state_machine
	var st        : State_Base    = sm.active_state
	var is_active : bool          = st != null and st.state_id == "Attack"

	if is_active:
		var attack : ST_Attack = st as ST_Attack
		if attack != null and attack.hfd != null and attack.hfd.move_data != null:
			if is_p1:
				_p1_last_md  = attack.hfd.move_data
				_p1_last_hfd = attack.hfd
			else:
				_p2_last_md  = attack.hfd.move_data
				_p2_last_hfd = attack.hfd

	var md  : MoveData        = _p1_last_md  if is_p1 else _p2_last_md
	var hfd : HitboxFrameData = _p1_last_hfd if is_p1 else _p2_last_hfd
	var header : String = "Attack Data" if md == null else "Attack Data — %s" % md.move_name

	if ImGui.TreeNode(header):
		if md == null:
			ImGui.TextDisabled("No attack performed yet")
			ImGui.TreePop()
			return

		if not is_active:
			ImGui.TextColored(Color(0.55, 0.55, 0.55), "(last attack — not active)")

		ImGui.TextColored(Color.ORANGE, md.move_name)
		ImGui.Text("ID:       %s" % md.move_id)
		ImGui.Text("Anim:     %s" % md.anim_path)

		ImGui.Spacing()
		ImGui.TextColored(Color.YELLOW, "Frame Data")
		ImGui.Text("Startup:  %d" % md.startup)
		ImGui.Text("Active:   %s" % str(md.active))
		ImGui.Text("Gaps:     %s" % str(md.gaps))
		ImGui.Text("Recovery: %d" % md.recovery)
		ImGui.Text("Total:    %d" % md.total_frames())

		if is_active and hfd != null:
			ImGui.Spacing()
			ImGui.TextColored(Color.CYAN, "Progress")
			var f     : int   = hfd._current_frame
			var total : int   = md.total_frames()
			var prog  : float = float(f) / float(total) if total > 0 else 0.0
			ImGui.Text("Frame:     %d / %d" % [f, total])
			ImGui.Text("Hit Index: %d" % hfd._current_active_index)
			if f <= md.startup:
				ImGui.TextColored(Color.YELLOW, "[ STARTUP ]")
			elif hfd._current_active_index >= 0:
				ImGui.TextColored(Color.RED, "[ ACTIVE — index %d ]" % hfd._current_active_index)
			else:
				ImGui.TextColored(Color.GRAY, "[ RECOVERY ]")
			ImGui.ProgressBar(prog, Vector2(200, 14), "%d / %d" % [f, total])

		ImGui.Spacing()
		ImGui.TextColored(Color.YELLOW, "Properties")
		ImGui.Text("Damage:    %s" % str(md.damage))
		ImGui.Text("Level:     %d" % md.attack_level)
		ImGui.Text("Guard:     %s" % str(md.guard))
		ImGui.Text("Attribute: %s" % str(md.attribute))
		ImGui.Text("P1:        %d" % md.p1)
		ImGui.Text("P2:        %s" % str(md.p2))
		ImGui.Text("On Block:  %d" % 0)
		ImGui.Text("On Hit:    %d" % 0)

		if is_active and hfd != null:
			ImGui.Spacing()
			if ImGui.TreeNode("Hit Log"):
				if hfd._hit_log.is_empty():
					ImGui.TextDisabled("No hits registered")
				else:
					for idx in hfd._hit_log.keys():
						ImGui.Text("Index %d: %d hit(s)" % [idx, hfd._hit_log[idx].size()])
				ImGui.TreePop()

			if ImGui.TreeNode("Spawned Shapes (%d)" % hfd._spawned_shapes.size()):
				if hfd._spawned_shapes.is_empty():
					ImGui.TextDisabled("None active")
				else:
					for shape in hfd._spawned_shapes:
						if is_instance_valid(shape):
							ImGui.Text("%s  pos:(%.0f, %.0f)" % [
								shape.name, shape.position.x, shape.position.y
							])
				ImGui.TreePop()

		ImGui.TreePop()

# =============================================================================
# Properties
# =============================================================================
func imgui_property_info(player) -> void:
	if ImGui.TreeNode("Properties (%d)" % player.properties.size()):
		if player.properties.is_empty():
			ImGui.TextDisabled("None active")
		else:
			for p in player.properties:
				var dur_str   : String = "\u221e" if p.duration == -1 else str(p.duration) + "f"
				var stack_str : String = " [stack]" if p.does_stack else ""
				ImGui.TextColored(p.get_color(), "\u25cf %s" % p.get_name())
				ImGui.SameLine()
				ImGui.TextDisabled("%s  owner:%s  val:%.2f%s" % [
					dur_str, p.owner, p.value, stack_str
				])
		ImGui.TreePop()

# =============================================================================
# Transform
# =============================================================================
func imgui_transform_info(player) -> void:
	if ImGui.TreeNode("Transform"):
		ImGui.Text("Position: (%.1f, %.1f)" % [player.global_position.x, player.global_position.y])
		ImGui.Text("Scale:    (%.2f, %.2f)" % [player.scale.x, player.scale.y])
		ImGui.TreePop()

# =============================================================================
# Timescale / Frame Step
# =============================================================================
func imgui_timescale() -> void:
	if ImGui.TreeNode("Timescale / Frame Step"):
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
	match st.state_id:
		"Dash":        return ["STARTUP", "ACTIVE", "RECOVERY"]
		"BackDash":    return ["INVUL",   "ACTIVE", "RECOVERY"]
		"AirDash":     return ["ACTIVE"]
		"AirBackDash": return ["ACTIVE"]
		_:             return []

func _get_max_timer(st: State_Base) -> int:
	var cd = st.fighter.char_data if st.fighter else null
	if cd == null: return 0
	match st.state_id:
		"Dash":
			if cd.dashType == cd.DashType.Dash:
				return 1
			else:
				match st._phase:
					0: return cd.step_Startup
					1: return cd.step_Duration
					_: return cd.step_recovery
		"BackDash":
			if cd.backdash_type == cd.BackDashType.Dash:
				return 1
			else:
				match st._phase:
					0: return cd.backdash_startup
					1: return cd.backdash_duration
					_: return cd.backdash_recovery
		_: return 0

# =============================================================================
# Setup
# =============================================================================
func set_vars() -> void:
	P1 = Global.P1
	P2 = Global.P2
