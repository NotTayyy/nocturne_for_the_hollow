extends Node2D

var current_Gui = null
var UI_Node = null

func _ready() -> void:
	Global.ui_manager = self
	UI_Node = Global.UI
	await get_tree().process_frame
	
func _process(_delta: float) -> void:
	pass

func Change_Gui_scene(new_scene: String, delete: bool = true, keep_running: bool = false) -> void:
	if current_Gui != null:
		if delete:
			current_Gui.queue_free()
		elif keep_running:
			current_Gui.visible = false
		else:
			UI_Node.remove_child(current_Gui)
	var new = load(new_scene).instantiate()
	UI_Node.add_child(new)
	current_Gui = new
