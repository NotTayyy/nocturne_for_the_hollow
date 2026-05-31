extends Resource
class_name CancelRouteLibrary

## List of valid command strings for this character.
## Populates the command dropdown on CancelRoute.
@export var commands : Array[String] = []

## Dictionary mapping friendly name → node path string.
## e.g. { "Nml_5A": "Components/FrameData/Nml_5A" }
@export var hfd_paths : Dictionary = {}
