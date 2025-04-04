extends Camera3D

@export var PanSpeed : float = 8.0
@export var RotSpeed : float = 5.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var target : Node3D = get_parent()
	var pan := Vector3.ZERO
	var rot : float = 0.0
	if Input.is_action_pressed("pan_down"):
		pan += target.transform.basis.z
	if Input.is_action_pressed("pan_left"):
		pan -= target.transform.basis.x
	if Input.is_action_pressed("pan_right"):
		pan += target.transform.basis.x
	if Input.is_action_pressed("pan_up"):
		pan -= target.transform.basis.z
	if Input.is_action_pressed("rotate_left"):
		rot -= 1.0
	if Input.is_action_pressed("rotate_right"):
		rot += 1.0
	
	pan.y = 0.0
	if pan.length_squared() > 0.001:
		get_parent().global_transform.origin += pan * delta * PanSpeed
		
	if rot != 0.0:
		get_parent().rotate(Vector3.UP, rot * delta * RotSpeed)
