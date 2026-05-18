extends Node2D

var P1
var P2
var p1_max_y : float = 0.0
var p2_max_y : float = 0.0

# Attack data cache — persists after attack ends
var _p1_last_md  : MoveData        = null
var _p1_last_hfd : HitboxFrameData = null
var _p2_last_md  : MoveData        = null
var _p2_last_hfd : HitboxFrameData = null

# Last combo cache
var _last_combo_hits     : int           = 0
var _last_combo_damage   : int           = 0
var _last_combo_moves    : Array[String] = []
var _last_combo_attacker : String        = ""
var _last_combo_defender : String        = ""

# Timescale / frame step
var _timescale   : float = 1.0
var _frame_step  : bool  = false
var _step_queued : bool  = false

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

	# Combo window — attack data + combo tracking
	ImGui.Begin("Combo")
	ImGui.PushID("AttackP1")
	ImGui.TextColored(Color.CYAN, "P1 Attack")
	imgui_attack_info(P1)
	ImGui.PopID()
	ImGui.Separator()
	ImGui.PushID("AttackP2")
	ImGui.TextColored(Color.CYAN, "P2 Attack")
	imgui_attack_info(P2)
	ImGui.PopID()
	ImGui.Separator()
	imgui_combo_info()
	ImGui.End()

	# Players window
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
# Root
# =============================================================================
func imgui_player_root(label: String, player, max_y: float) -> void:
	if player == null: return
	if ImGui.CollapsingHeader(label):
		imgui_core_info(player)
		imgui_health_info(player)
		imgui_movement_info(player, max_y)
		imgui_state_info(player)
		imgui_property_info(player)
		imgui_transform_info(player)

# =============================================================================
# Core
# =============================================================================
func imgui_core_info(player) -> void:
	ImGui.Text("Player ID: %s  Name: %s" % [str(player.player_id), str(player.char_data.character_name)])

# =============================================================================
# Health
# =============================================================================
func imgui_health_info(player) -> void:
	var curr  : int   = player.char_data.curr_health
	var max_hp : int  = player.char_data.base_max_health
	var pct   : float = float(curr) / float(max_hp) if max_hp > 0 else 0.0
	ImGui.TextColored(Color(1.0 - pct, pct, 0.0, 1.0), "HP: %d / %d (%.0f%%)" % [curr, max_hp, pct * 100])

# =============================================================================
# Movement
# =============================================================================
func imgui_movement_info(player, max_y: float) -> void:
	ImGui.Text("Facing: %s  Air: %s  Vel:(%.0f, %.0f)  PeakY:%.0f" % [
		str(player.dir_facing), str(player.is_airborne),
		player.velocity.x, player.velocity.y, max_y
	])
	if ImGui.Button("Reset Peak##%s" % player.name):
		if player == P1: p1_max_y = 0.0
		else:            p2_max_y = 0.0

# =============================================================================
# State Machine
# =============================================================================
func imgui_state_info(player) -> void:
	var sm : State_Manager = player.state_machine
	var st : State_Base    = sm.active_state
	if st == null:
		ImGui.Text("No active state")
		return

	ImGui.TextColored(Color.CYAN, "State: %s  Frame: %d" % [st.state_id, st.frame])

	if "_phase" in st:
		var phase_names := _get_phase_names(st)
		var phase_idx   : int    = st._phase
		var phase_label : String = phase_names[phase_idx] if phase_idx < phase_names.size() else str(phase_idx)
		ImGui.TextColored(Color.YELLOW, "Phase: %s" % phase_label)

	if "_timer" in st and st._timer >= 0:
		var max_timer := _get_max_timer(st)
		if max_timer > 0:
			var progress := 1.0 - (float(st._timer) / float(max_timer))
			ImGui.ProgressBar(progress, Vector2(-1, 10), "Timer: %d" % st._timer)

	# Gates
	ImGui.Text("Gates:")
	ImGui.SameLine()
	_gate_inline("Self",      st.gate_self)
	_gate_inline("Special",   st.gate_special)
	_gate_inline("Drive",     st.gate_drive)
	_gate_inline("Overdrive", st.gate_overdrive)
	_gate_inline("Jump",      st.gate_jump)
	_gate_inline("Rapid",     st.gate_rapid)
	ImGui.NewLine()
	ImGui.Text("      ")
	ImGui.SameLine()
	_gate_inline("Dash",      st.gate_dash)
	_gate_inline("Backdash",  st.gate_backdash)
	_gate_inline("Burst",     st.gate_burst)
	_gate_inline("Barrier",   st.gate_barrier)

	# Invul
	ImGui.NewLine()
	ImGui.Text("Invul:")
	ImGui.SameLine()
	_gate_inline("Head",        st.invul_head)
	_gate_inline("Body",        st.invul_body)
	_gate_inline("Foot",        st.invul_foot)
	_gate_inline("Throw",       st.invul_throw)
	_gate_inline("Projectile",  st.invul_projectile)
	_gate_inline("Burst",       st.invul_burst)
	_gate_inline("All",         st.invul_all)
	_gate_inline("GuardPoint",  st.invul_guard_point)

	# Aerial stocks
	ImGui.NewLine()
	ImGui.Text("Air:")
	ImGui.SameLine()
	_gate_inline("Jumps:%d/%d" % [player.jumps_remaining, player.char_data.air_Jumps], player.jumps_remaining > 0)
	_gate_inline("Dashes:%d/%d" % [player.dashes_remaining, player.char_data.air_Dashes], player.dashes_remaining > 0)
	_gate_inline("Lockout:%d" % st.lockout_timer, st.lockout_timer == 0)
	ImGui.NewLine()

# =============================================================================
# Attack Data — in Combo window
# =============================================================================
func imgui_attack_info(player) -> void:
	if player == null:
		ImGui.TextDisabled("No player")
		return

	var is_p1     : bool          = player == P1
	var sm        : State_Manager = player.state_machine
	var st        : State_Base    = sm.active_state
	var is_active : bool          = st != null and st.state_id == "Attack"

	# Update cache while attacking
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

	if md == null:
		ImGui.TextDisabled("No attack yet")
		return

	if not is_active:
		ImGui.TextColored(Color(0.55, 0.55, 0.55), "(last attack)")

	# Identity
	ImGui.TextColored(Color.ORANGE, "%s  [%s]" % [md.move_name, md.move_id])

	# Frame data
	ImGui.Text("Startup:%d  Active:%s  Gaps:%s  Recovery:%d  Total:%d" % [
		md.startup, str(md.active), str(md.gaps), md.recovery, md.total_frames()
	])

	# Live progress
	if is_active and hfd != null:
		var f     : int   = hfd._current_frame
		var total : int   = md.total_frames()
		var prog  : float = float(f) / float(total) if total > 0 else 0.0
		var phase_label : String
		if f <= md.startup:
			phase_label = "STARTUP"
		elif hfd._current_active_index >= 0:
			phase_label = "ACTIVE [%d]" % hfd._current_active_index
		else:
			phase_label = "RECOVERY"
		ImGui.ProgressBar(prog, Vector2(-1, 12), "%s  %d/%d" % [phase_label, f, total])

	# Properties
	var lvl_str : String = str(md.attack_level)
	ImGui.Text("Dmg:%s  Lvl:%s  P1:%d  P2:%s" % [str(md.damage), lvl_str, md.p1, str(md.p2)])

	# Guard
	var guard_names : Array[String] = []
	for g in md.guard:
		guard_names.append(MoveData.GuardType.find_key(g))
	ImGui.Text("Guard: %s" % " / ".join(guard_names))

	# Attribute
	var attr_names : Array[String] = []
	for a in md.attribute:
		attr_names.append(MoveData.Attribute.find_key(a))
	ImGui.Text("Attribute: %s" % " / ".join(attr_names))

	# Hit Effects
	ImGui.Text("On Hit:")
	for i in md.ground_hit_effect.size():
		var eff  : String = MoveData.HitEffect.find_key(md.ground_hit_effect[i])
		var dur  : int    = md.ground_hit_duration[i] if i < md.ground_hit_duration.size() else -1
		var dur_str : String = str(dur) if dur != -1 else "table"
		ImGui.Text("  [%d] %s (%s)" % [i, eff, dur_str])

	ImGui.Text("On Hit (Air):")
	for i in md.air_hit_effect.size():
		var eff  : String = MoveData.HitEffect.find_key(md.air_hit_effect[i])
		var dur  : int    = md.air_hit_duration[i] if i < md.air_hit_duration.size() else -1
		var dur_str : String = str(dur) if dur != -1 else "table"
		ImGui.Text("  [%d] %s (%s)" % [i, eff, dur_str])

	# Hit log
	if is_active and hfd != null and not hfd._hit_log.is_empty():
		var log_str : String = ""
		for idx in hfd._hit_log.keys():
			log_str += "idx%d:%d  " % [idx, hfd._hit_log[idx].size()]
		ImGui.Text("Hits: %s" % log_str.strip_edges())

# =============================================================================
# Properties
# =============================================================================
func imgui_property_info(player) -> void:
	ImGui.Text("Properties (%d)" % player.properties.size())
	if player.properties.is_empty():
		ImGui.TextDisabled("  None active")
	else:
		for p in player.properties:
			var dur_str   : String = "\u221e" if p.duration == -1 else str(p.duration) + "f"
			var stack_str : String = " [stack]" if p.does_stack else ""
			ImGui.TextColored(p.get_color(), "  \u25cf %s" % p.get_name())
			ImGui.SameLine()
			ImGui.TextDisabled("%s  owner:%s  val:%.2f%s" % [dur_str, p.owner, p.value, stack_str])

# =============================================================================
# Transform
# =============================================================================
func imgui_transform_info(player) -> void:
	ImGui.Text("Pos:(%.0f, %.0f)  Scale:(%.2f, %.2f)" % [
		player.global_position.x, player.global_position.y,
		player.scale.x, player.scale.y
	])

# =============================================================================
# Combo Info
# =============================================================================
func imgui_combo_info() -> void:
	var cm : ComboManager = Global.combo_manager
	if cm == null:
		ImGui.TextDisabled("No ComboManager")
		return

	if not cm.is_active:
		# Cache when combo ends
		if cm.hit_count > 0 and _last_combo_hits != cm.hit_count:
			_last_combo_hits     = cm.hit_count
			_last_combo_damage   = cm._total_damage
			_last_combo_moves    = cm.move_history.duplicate()
			_last_combo_attacker = cm.attacker.name if cm.attacker else "?"
			_last_combo_defender = cm.defender.name if cm.defender else "?"
		if _last_combo_hits == 0:
			ImGui.TextColored(Color(0.5, 0.5, 0.5), "No combo yet")
			return
		ImGui.TextColored(Color(0.5, 0.5, 0.5), "Last Combo")
		ImGui.TextColored(Color(0.7, 0.5, 0.2), "%d Hits  %d dmg" % [_last_combo_hits, _last_combo_damage])
		ImGui.Text("%s -> %s" % [_last_combo_attacker, _last_combo_defender])
		if not _last_combo_moves.is_empty():
			ImGui.TextWrapped(" > ".join(_last_combo_moves))
		return

	# Active combo
	ImGui.TextColored(Color.ORANGE, "%d Hits" % cm.hit_count)
	ImGui.SameLine()
	ImGui.TextColored(Color.WHITE, "  %d dmg" % cm._total_damage)

	var timer_pct   : float = clampf(float(cm.combo_timer) / 30.0, 0.0, 1.0)
	var timer_color : Color = Color.LIME_GREEN if cm.combo_timer > 10 else Color.YELLOW if cm.combo_timer > 5 else Color.RED
	ImGui.TextColored(timer_color, "Timer: %df" % cm.combo_timer)
	ImGui.ProgressBar(timer_pct, Vector2(-1, 10), "")

	ImGui.Text("Duration: %df" % cm.combo_duration_frames)
	var decay_color : Color = Color.LIME_GREEN
	if   cm.combo_duration_frames >= 660: decay_color = Color.RED
	elif cm.combo_duration_frames >= 480: decay_color = Color.ORANGE
	elif cm.combo_duration_frames >= 300: decay_color = Color.YELLOW
	elif cm.combo_duration_frames >= 120: decay_color = Color(0.8, 0.9, 0.4)
	ImGui.TextColored(decay_color, "Decay: %s" % cm._decay_tier_label())

	ImGui.Text("%s -> %s" % [
		cm.attacker.name if cm.attacker else "?",
		cm.defender.name if cm.defender else "?"
	])

	if not cm.move_history.is_empty():
		ImGui.TextWrapped(" > ".join(cm.move_history))

# =============================================================================
# Input Buffer
# =============================================================================
func imgui_input_info(player) -> void:
	if player == null: return
	var buf          : InputBuffer = player.input_buffer
	var facing_right : bool        = player.dir_facing == "Right"

	# Buffered command
	if not buf._buffered_command.is_empty():
		var age : int = Engine.get_physics_frames() - buf._buffered_command_frame
		var pct : float = clampf(1.0 - float(age) / float(buf.BUFFER_WINDOW), 0.0, 1.0)
		ImGui.TextColored(Color.ORANGE, "Buf: %s" % buf._buffered_command.get("Command", "?"))
		ImGui.SameLine()
		ImGui.ProgressBar(pct, Vector2(60, 10), "")
	else:
		ImGui.TextDisabled("Buf: --")

	# Build rows from event_log — most recent first, max 40
	var plog  : Array = buf.event_log
	var rows  : Array = []
	var i     : int   = plog.size() - 1

	while i >= 0 and rows.size() < 40:
		var e         = plog[i]
		var row_frame : int    = e["frame"]
		var dir       : String = "5"
		var buttons   : Array  = []
		var is_press  : bool   = false

		# Collect all events on this frame
		while i >= 0 and plog[i]["frame"] == row_frame:
			var ev = plog[i]
			if ev["action"] in InputBuffer.DIRECTIONS:
				dir = ev["action"]
			else:
				buttons.append(ev["action"])
			if ev["type"] == "press":
				is_press = true
			i -= 1

		var next_frame : int = plog[i]["frame"] if i >= 0 else row_frame
		var duration   : int = row_frame - next_frame

		rows.append({ "dir": dir, "buttons": buttons, "is_press": is_press, "duration": duration })

	# Held buttons for top row
	var held_btns : Array = []
	for k in buf.held_inputs.keys():
		if k in InputBuffer.BUTTONS:
			held_btns.append(k)

	# Render
	for ri in rows.size():
		var r     : Dictionary = rows[ri]
		var color : Color      = Color.WHITE if r["is_press"] else Color(0.5, 0.5, 0.5)
		var arrow : String     = _dir_to_numpad(r["dir"], facing_right)

		ImGui.TextColored(color, "%-2s" % (arrow if arrow != "5" else " "))

		for btn in ["A", "B", "C", "D"]:
			var in_row  : bool = btn in r["buttons"]
			var is_held : bool = ri == 0 and btn in held_btns and not in_row
			if in_row or is_held:
				ImGui.SameLine()
				var btn_color : Color
				if is_held:
					btn_color = Color(0.4, 0.4, 0.4)
				elif r["is_press"]:
					btn_color = _btn_color(btn)
				else:
					btn_color = Color(0.4, 0.4, 0.4)
				ImGui.TextColored(btn_color, btn)

		ImGui.SameLine()
		ImGui.TextDisabled("%d" % r["duration"])

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

func _gate_inline(label: String, value: bool) -> void:
	var color := Color.LIME_GREEN if value else Color(0.35, 0.35, 0.35)
	ImGui.TextColored(color, label)
	ImGui.SameLine()

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
			match st._phase:
				0: return cd.step_Startup
				1: return cd.step_Duration
				_: return cd.step_recovery
		"BackDash":
			match st._phase:
				0: return cd.backdash_startup
				1: return cd.backdash_duration
				_: return cd.backdash_recovery
		_: return 0

func _dir_to_numpad(dir: String, facing_right: bool) -> String:
	var r : Dictionary = {"1":"1","2":"2","3":"3","4":"4","5":"5","6":"6","7":"7","8":"8","9":"9"}
	var l : Dictionary = {"1":"3","2":"2","3":"1","4":"6","5":"5","6":"4","7":"9","8":"8","9":"7"}
	return (r if facing_right else l).get(dir, dir)

func _btn_color(btn: String) -> Color:
	match btn:
		"A": return Color(0.4, 0.9, 0.4)
		"B": return Color(0.4, 0.6, 1.0)
		"C": return Color(1.0, 0.3, 0.3)
		"D": return Color(1.0, 0.8, 0.2)
		_:   return Color.WHITE

# =============================================================================
# Setup
# =============================================================================
func set_vars() -> void:
	P1 = Global.P1
	P2 = Global.P2
