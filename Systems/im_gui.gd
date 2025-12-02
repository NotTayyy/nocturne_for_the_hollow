extends Node2D

var P1
var P2
var player

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if not Global.game_manager.current_state == Global.game_manager.GameState.MID_MATCH:
		return
	if  P1 == null and P2 == null:
		set_vars()
	
	ImGui.Begin("Players")
	imgui_player_stats("Player 1", 1)
	ImGui.Text(" ")
	imgui_player_stats("Player 2", 2)
	ImGui.End()
	
func imgui_player_stats(table_name: String, player_no):
	
	if player_no == 1:
		player = P1
	else:
		player = P2
	
	ImGui.Text(table_name)
	if ImGui.BeginTable(table_name, 8):
		ImGui.TableSetupColumn("Player_Id")
		ImGui.TableSetupColumn("Name")
		ImGui.TableSetupColumn("Health")
		ImGui.TableSetupColumn("Dir")
		ImGui.TableSetupColumn("Facing")
		ImGui.TableSetupColumn("Airborn")
		ImGui.TableSetupColumn("XYZ")
		ImGui.TableSetupColumn("Scale")
		ImGui.TableHeadersRow()
		
		ImGui.TableNextRow()
		
		ImGui.TableNextColumn()
		ImGui.Text(id(player_no))
		
		ImGui.TableNextColumn()
		ImGui.Text(str(player.char_data.character_name))
		
		ImGui.TableNextColumn()
		ImGui.Text(str(player.char_data.health))
		
		ImGui.TableNextColumn()
		ImGui.Text(str(player.dir_facing))
		
		ImGui.TableNextColumn()
		ImGui.Text(str(player.dir))
		
		ImGui.TableNextColumn()
		ImGui.Text(str(player.is_airborn))
		
		ImGui.TableNextColumn()
		ImGui.Text(str(player.global_position))
		
		ImGui.TableNextColumn()
		ImGui.Text(str(player.scale))
		

			
	ImGui.EndTable()

func set_vars() -> void:
	P1 = Global.P1
	P2 = Global.P2

func id(plr_id) -> String:
	match plr_id:
		1:
			return str(Global.P1.player_id)
		2:
			return str(Global.P2.player_id)
		_:
			return "Broken"
	
