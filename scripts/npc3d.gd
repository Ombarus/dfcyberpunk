extends CharacterBody3D

@export var AnimToPlay : String = "DoorOpen"
@export var Target : NodePath

@onready var nav := get_node("NavigationAgent3D") as NavigationAgent3D
@onready var t := get_node(Target) as Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not AnimToPlay.is_empty():
		(get_node("Peep12/AnimationPlayer") as AnimationPlayer).play(AnimToPlay)
		
	if t != null:
		nav.target_position = t.position
		
func _physics_process(delta: float) -> void:
	if t == null:
		return
	var next = nav.get_next_path_position()
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	var dir = (next - self.position).normalized()
	self.look_at(next)
	
	velocity = Vector3(dir.x, velocity.y, dir.z)

	move_and_slide()
