@tool
extends MeshInstance3D
class_name Rope

var PrevPos1 : Vector3
var PrevPos2 : Vector3

@export var A : float = 3.0:
	set(value):
		if A > 1.0:
			A = value
			if Engine.is_editor_hint():
				refresh_rope()
	get:
		return A
@export var Radius : float = 0.2:
	set(value):
		Radius = value
		if Engine.is_editor_hint():
			refresh_rope()
	get:
		return Radius
@export var Segments : int = 10:
	set(value):
		Segments = value
		if Engine.is_editor_hint():
			refresh_rope()
	get:
		return Segments
@export var Sides : int = 5:
	set(value):
		Sides = value
		if Engine.is_editor_hint():
			refresh_rope()
	get:
		return Sides
@export var UV : Vector2:
	set(value):
		UV = value
		if Engine.is_editor_hint():
			refresh_rope()
	get:
		return UV

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	refresh_rope()
	
func _enter_tree() -> void:
	if Engine.is_editor_hint():
		self.set_process(true)
	else:
		self.set_process(false)
		
func _process(delta: float) -> void:
	if self.get_child_count() < 2:
		return
	var n1 : Node3D = self.get_child(0)
	var n2 : Node3D = self.get_child(1)
	if self.PrevPos1 != n1.global_position or self.PrevPos2 != n2.global_position:
		refresh_rope()
	

func refresh_rope():
	if self.get_child_count() < 2:
		return
	var n1 : Node3D = self.get_child(0)
	var n2 : Node3D = self.get_child(1)
	var start : Vector3 = n1.global_position
	var end : Vector3 = n2.global_position
	
	var xz_start := start
	xz_start.y = 0
	var xz_end := end
	xz_end.y = 0
	var x1 = 0
	var x2 = (xz_start - xz_end).length()
	var y1 = 0
	var y2 = end.y - start.y
	var L := sqrt((x2 * x2) + (y2 * y2))
	L *= self.A
	
	var a = solve_catenary_rope(x2, y2, L)
	
	var x0 = (x2 / 2) - a * atanh(y2 / L)
	var y0 = -a * cosh(x0 / a)
	
	draw_catenary_rope_v2(0, x2, x0, y0, a, self.Radius, self.Segments, self.Sides)
	self.PrevPos1 = n1.global_position
	self.PrevPos2 = n2.global_position

func solve_catenary_rope(
	x2: float,
	y2: float,
	L: float
) -> float:
	var x1 := 0.0
	var y1 := 0.0

	var a = L
	var term1 := 0.0
	var term2 := 1.0
	var maxiter : int = 4
	var step : float = 1.0
	for i in range(maxiter):
		while term1 < term2:
			a = a - step
			if a > 0:
				term1 = sinh(x2 / (2 * a))
				term2 = sqrt((L * L) - (y2 * y2)) / (2 * a)
			else:
				a = 0.0
				term1 = 1.0
				term2 = 0.0
				break
		step = step / 10.0
		while term2 < term1:
			a = a + step
			term1 = sinh(x2 / (2 * a))
			term2 = sqrt((L * L) - (y2 * y2)) / (2 * a)
		step = step / 10.0

	print("L=%.3f, x1=%.3f, x2=%.3f, a=%.3f" % [L, x1, x2, a])
	return a

func y_x(x, a, x0, y0):
	var val = y0 + a * cosh((x - x0) / a)
	return val
	
# ChatGPT
func draw_catenary_rope_v2(
	x1: float,
	x2: float,
	x0: float,
	y0: float,
	a: float,
	radius: float,
	segments: int,
	sides: int
) -> MeshInstance3D:
	var y1 = y_x(x1, a, x0, y0)
	var y2 = y_x(x2, a, x0, y0)
	var dx = (x2 - x1) / segments

	var points : Array[Vector3] = []
	
	for i in range(segments + 1):
		var curx = x1 + (dx * i)
		var cury = y_x(curx, a, x0, y0)
		points.append(Vector3(curx, cury, 0.0))
		
	self.mesh = build_tube_mesh(points, radius, sides)
	
	return self
	
func build_tube_mesh(
	points: Array[Vector3],
	radius: float,
	sides: int
) -> ArrayMesh:
	var vertices: PackedVector3Array = []
	var normals: PackedVector3Array = []
	var indices: PackedInt32Array = []
	var uvs: PackedVector2Array = []
	var n1 : Node3D = self.get_child(0)
	var n2 : Node3D = self.get_child(1)
	var offset_transform : Transform3D = segment_to_segment_trasnform_v2(points[0], points[points.size()-1], n1.global_position, n2.global_position)

	var ring_count = points.size()
	var ring_size = sides

	# Precompute angles
	var angles := PackedFloat32Array()
	for i in sides:
		angles.append(TAU * float(i) / float(sides))

	var prev_binormal: Vector3 = Vector3.ZERO

	for i in ring_count:
		var p = points[i]

		# Compute tangent
		var tangent: Vector3
		if i == 0:
			tangent = (points[i + 1] - p).normalized()
		elif i == ring_count - 1:
			tangent = (p - points[i - 1]).normalized()
		else:
			tangent = (points[i + 1] - points[i - 1]).normalized()

		# Build stable frame
		var normal: Vector3
		if prev_binormal == Vector3.ZERO:
			normal = tangent.cross(Vector3.UP)
			if normal.length() < 0.001:
				normal = tangent.cross(Vector3.RIGHT)
			normal = normal.normalized()
		else:
			normal = prev_binormal.cross(tangent).normalized()

		var binormal = tangent.cross(normal).normalized()
		prev_binormal = binormal

		# Build ring
		for j in sides:
			var angle = angles[j]
			var dir = cos(angle) * normal + sin(angle) * binormal
			var v : Vector3 = p + dir * radius
			v = offset_transform * v
			vertices.append(v)
			normals.append(dir)
			uvs.append(self.UV)

	# Build indices
	for i in ring_count - 1:
		var base0 = i * ring_size
		var base1 = (i + 1) * ring_size

		for j in sides:
			var j0 = j
			var j1 = (j + 1) % ring_size

			indices.append(base0 + j0)
			indices.append(base1 + j0)
			indices.append(base1 + j1)

			indices.append(base0 + j0)
			indices.append(base1 + j1)
			indices.append(base0 + j1)

	# Assemble mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	return mesh
	
func segment_to_segment_trasnform_v2(
	p1: Vector3,
	p2: Vector3,
	p3: Vector3,
	p4: Vector3
) -> Transform3D:
	var v1 = p2 - p1
	var v2 = p4 - p3
	v1.y = 0
	v2.y = 0
	v1 = v1.normalized()
	v2 = v2.normalized()
	
	var angle = v1.angle_to(v2)
	var rot = Basis(Vector3.UP, angle)
	var trans = p3 - p1
	
	return Transform3D(rot, trans)
