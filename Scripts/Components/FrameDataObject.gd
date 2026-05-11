@tool
extends CollisionShape2D
class_name FrameDataObject

## Which frame this hitbox becomes active
@export var start_frame : int = 0
## Which frame this hitbox deactivates (inclusive)
@export var end_frame   : int = 0
## Which hit of the move this shape belongs to (for multi-hit P2 lookup)
@export var hit_index   : int = 0

## Box type — determines which collision layer it uses at runtime
enum BoxType { Hitbox, Hurtbox }
@export var box_type : BoxType = BoxType.Hitbox

func _ready() -> void:

	_update_debug_color()

func _update_debug_color() -> void:
	match box_type:
		BoxType.Hitbox:  debug_color = Color(1.0, 0.2, 0.2, 0.35)
		BoxType.Hurtbox: debug_color = Color(0.0, 0.531, 0.852, 0.349)
