extends State

var we_idle: bool

func Enter() -> void:
	possible_commands = ["6A", "6B", "6C", "Forward Dash"]
	state_machine.allowed_cmnds = possible_commands
	
	print("We Getting Lazy.. Oh Yeag")

func Update(_delta:float) -> void:
	fighter.capture_input()
	
	
	we_idle = true

func Exit() -> void:
	print("Damn Guess we doing stuff now")
