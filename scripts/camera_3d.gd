extends Camera3D

@export var PanSpeed : float = 8.0
@export var RotSpeed : float = 5.0
@export var ZoomSpeed : float = 5.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.look_at(get_parent().global_position)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var target : Node3D = get_parent()
	var pan := Vector3.ZERO
	var rot : float = 0.0
	var zoom : float = 0.0
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
	if Input.is_action_pressed("zoom_in"):
		zoom += 1.0
	if Input.is_action_pressed("zoom_out"):
		zoom -= 1.0
	
	pan.y = 0.0
	if pan.length_squared() > 0.001:
		get_parent().global_transform.origin += pan * delta * PanSpeed
		
	if rot != 0.0:
		get_parent().rotate(Vector3.UP, rot * delta * RotSpeed)	
	
		
		
func _input(event: InputEvent) -> void:
	var zoom : float = 0.0
	if event.is_action("zoom_in"):
		zoom -= 1.0
	if event.is_action("zoom_out"):
		zoom += 1.0
		
	if abs(zoom) > 0.001:
		var look_y = self.get_parent().global_transform.origin.y
		var new_y = self.global_transform.origin.y + (zoom * ZoomSpeed)
		new_y = clamp(new_y, look_y + 0.2, look_y + 28.0)
		self.global_transform.origin.y = new_y
		self.look_at(get_parent().global_position)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_released() and event.button_index == MOUSE_BUTTON_LEFT:
		var from = self.project_ray_origin(event.position)
		var to = from + self.project_ray_normal(event.position) * 1000.0
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = 1  # only layer 1

		var result = space_state.intersect_ray(query)
		if result:
			var collider = result["collider"]
			print("Hit node: ", collider.name)
			var p = collider
			while p != null:
				if p is Advertisement:
					Events.OnAdSelected.emit(p)
					break
				p = p.get_parent()
