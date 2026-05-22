extends Resource
class_name CancelRoute

## Command string matching InputBuffer — e.g. "Button B", "236A"
@export var command  : String = ""

## NodePath string to the HFD on the fighter — e.g. "Components/FrameData/Nml_5B"
@export var hfd_path : String = ""
