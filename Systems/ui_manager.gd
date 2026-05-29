extends Node2D
class_name Ui_Manager

var current_Gui: Object = null
var current_scene: String = ""
var UI_Node = null

var Ui_Scenes: Dictionary = {
	"Main_menu": "res://UI/Menu/Main/Main_menu.tscn",
	"MM_Options": "res://UI/Menu/Options/Options.tscn",
	"Character_Select": "res://UI/Menu/Character_Select/Character_Select.tscn",
	"Level_Select": "res://UI/Menu/Level_Select/Level_select.tscn",
	"Ingame_UI": "res://UI/Ingame/Ingame_UI.tscn"
}

func _ready() -> void:
	Global.ui_manager = self
	UI_Node = Global.UI
	await get_tree().process_frame
	
func _process(_delta: float) -> void:
	pass

func Change_Gui_scene(new_scene: String, delete: bool = true, keep_running: bool = false) -> void:
	var scene = Ui_Scenes[new_scene]
	
	if new_scene == current_scene:
		return
	
	if current_Gui != null:
		if delete == true:
			current_Gui.queue_free()
		elif keep_running:
			current_Gui.visible = false
		else:
			UI_Node.remove_child(current_Gui)
			
	var new = load(scene).instantiate()
	current_Gui = new
	current_scene = scene
	UI_Node.add_child(new)
