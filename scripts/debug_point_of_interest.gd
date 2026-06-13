extends POI
class_name DebugPOI

@export var NeedOverrides : Dictionary[Globals.NEEDS, float]
@export var SkillOverrides : Dictionary[Globals.SKILLS, float]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
