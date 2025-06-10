extends State

var we_idle: bool

func Enter() -> void:
	print("We Getting Lazy.. Oh Yeag")

func Update(_delta:float) -> void:
	fighter.capture_input()
	
	if not we_idle:
		print("what does this do")

func _physics_process(delta: float) -> void:
	
	
	if not we_idle:
		print("oh Yeah we Idle now")
		we_idle = true

func Exit() -> void:
	print("Damn Guess we doing stuff now")
