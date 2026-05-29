extends Resource
class_name CancelRoute

## Command string matching InputBuffer — e.g. "Button B", "236A", "Button D"
@export var command : String = ""

## Path to either:
##   An HFD node  — e.g. "Components/FrameData/Nml_5B"  (contains "/" → go to Attack state)
##   A state ID   — e.g. "ST_Kag_Stance"                 (no "/" → transition directly)
@export var path    : String = ""
