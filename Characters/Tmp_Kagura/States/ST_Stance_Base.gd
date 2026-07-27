extends State_Base
class_name Stance_Base

enum StancePhase { Active, Recovery }
enum Stance      { None, Neutral, Crouching, Forward }

@export var Stance_Timer : int = 84
@export var actionable   : int = 10
@export var recovery     : int = 24

var recov_timer : int = 0
var curr_stance : Stance      = Stance.None
var phase       : StancePhase = StancePhase.Active

func enter(_prev: String) -> void:
	frame       = 0
	phase       = StancePhase.Active
