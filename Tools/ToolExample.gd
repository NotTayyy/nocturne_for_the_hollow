@tool
class_name ToolExample
extends EditorScript

func _run() -> void:
	var window := Window.new()
	EditorInterface.popup_dialog(window, Rect2(Vector2(100, 100), Vector2(1280, 720)))
	
	var button := Button.new()
	button.text = "Fuck Off"
	button.pressed.connect(func():
		print("I Said Fuck Off")
	)
	
	window.add_child(button)
	
	window.close_requested.connect(func():
		window.queue_free()
	)

func _on_pressed():
	print("I Said Go AWAY")
