@tool
extends CSGPolygon3D

@export var Angle : float = 72:
	set(value):
		Angle = value
		generate_arc_polygon(Angle)
	get:
		return Angle

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#generate_arc_polygon(self.angle)

func generate_arc_polygon(angle_degrees: float, radius: float = 1.0, point_count: int = 10) -> void:
	var points := PackedVector2Array()

	# Center point (origin)
	points.append(Vector2.ZERO)

	var angle_rad := deg_to_rad(angle_degrees)

	for i in range(point_count):
		var t := float(i) / float(point_count - 1)

		var a := t * angle_rad

		var x := sin(a) * radius
		var y := cos(a) * radius

		points.append(Vector2(x, y))

	self.polygon = points
