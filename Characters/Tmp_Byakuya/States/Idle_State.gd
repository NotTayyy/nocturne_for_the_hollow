extends State
class_name PlayerIdle

func Enter():
	pass

func Update(_delta:float):
	if(Input.get_vector("P1_Left", "P1_Right", "P1_Up", "P1_Down")):
		pass
	
	if (Input.is_action_just_pressed("P1_Btn_A")) or (Input.is_action_just_pressed("P1_Btn_B")):
		pass

func Exit():
	pass
