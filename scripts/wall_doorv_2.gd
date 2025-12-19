extends Node3D

@export var AnimToPlay : String = "DoorOpen"
@export var Target : NodePath

@onready var nav := get_node("NavigationAgent3D") as NavigationAgent3D
@onready var t := get_node(Target) as Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not AnimToPlay.is_empty():
		(get_node("AnimationPlayer") as AnimationPlayer).play(AnimToPlay)
		
	if t != null:
		nav.target_position = t.global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if t == null:
		return
	var next = nav.get_next_path_position()
	var dir = (next - self.global_position).normalized()
	self.velocity = dir
	self.global_position += dir * delta
	
