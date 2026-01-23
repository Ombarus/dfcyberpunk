@tool
extends MeshInstance3D
class_name Rope

@export var A : float = 3.0:
	set(value):
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

func refresh_rope():
	print("hello")
	if self.get_child_count() < 2:
		return
	var n1 : Node3D = self.get_child(0)
	var n2 : Node3D = self.get_child(1)
	create_catenary_rope_v6(n1.global_position, n2.global_position, self.A, self.Radius, self.Segments, self.Sides)

func create_catenary_rope_v6(
	start: Vector3,
	end: Vector3,
	drop: float,
	radius: float,
	segments: int,
	sides: int
) -> void:
	var x1 = start.x
	var x2 = end.x
	var x12swapped = false
	var x12offset = 0.0
	if x1 > x2:
		x2 = start.x
		x1 = end.x
		x12swapped = true
	if x1 != 0:
		x12offset = x1
		x2 = x2 - x1
		x1 = 0.0
	var y1 = start.y
	var y2 = end.y
	var y12offset = 0.0
	if y1 != 0:
		y12offset = y1
		y2 = y2 - y1
		y1 = 0.0
	var sehne = sqrt((x2 * x2) + (y2 * y2))
	var L := (end - start).length()
	L *= drop
	var a = L
	var term1 := 0.0
	var term2 := 1.0
	var maxiter : int = 4
	var step : float = 1.0
	for i in range(maxiter):
		print("iter %d" % [i])
		while term1 < term2:
			print("%.5f: %.3f" % [step, a])
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
			print("%.5f: %.3f" % [step, a])
			a = a + step
			term1 = sinh(x2 / (2 * a))
			term2 = sqrt((L * L) - (y2 * y2)) / (2 * a)
		step = step / 10.0

	var x0 = (x2 / 2) - a * atanh(y2 / L)
	var y0 = -a * cosh(x0 / a)
	var xm = x0 + (a * sinh(y2 / x2))
	var ym = y_x(xm, a, x0, y0)
	var dhmax = ((y2 * xm) / x2) - y_x(xm, a, x0, y0)
	var x1delta = x2 / 1000
	var x2delta = x2 - x1delta
	var y1delta = y_x(x1delta, a, x0, y0)
	var y2delta = y_x(x2delta, a, x0, y0) - y2
	var alpha1 = atan(y1delta / x1delta) * 180 / PI
	var alpha2 = atan(y2delta / (x1delta)) * 180 / PI
	
	### CREATE GRAPH
	
	
	
	print("L=%.3f, x1=%.3f, x2=%.3f, a=%.3f" % [L, x1, x2, a])
	
	draw_catenary_rope_v2(0, x2, x0, y0, a, self.Radius, self.Segments, self.Sides)
	#create_catenary_rope(Vector3(0.0, y_x(0.0, a, x0, y0), 0.0), Vector3(x2, y_x(x2, a, x0, y0), 0.0), a, 0.1, 12, 6)

func y_x(x, a, x0, y0):
	var val = y0 + a * cosh((x - x0) / a)
	return val
	
	
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
			vertices.append(p + dir * radius)
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




func create_catenary_rope_v4(
	from: Vector3,
	to: Vector3,
	drop: float,
	radius: float,
	segments: int,
	sides: int
) -> void:
	var start := from
	var end := to
	var arc_length := (end - start).length()
	arc_length *= drop
	var horizontal_dist : float = (Vector2(end.x, end.z) - Vector2(start.x, start.z)).length()
	var vertical_dist : float = abs(end.y - start.y)
	var a = solve_catenary_a(horizontal_dist, vertical_dist, arc_length)
	#var a = solve_catenary_a(1426.0, 300.0, 2245.0)
	print("H:%.3f, V:%.3f, L:%.3f, a=%.3f" % [horizontal_dist, vertical_dist, arc_length, a])
	
	var lv2 = (arc_length * arc_length)-(vertical_dist * vertical_dist)
	var x1 = a * (
		log(
			-(sqrt(lv2) * sqrt(4 * (a*a) + lv2) + lv2) /
			((2 * a * arc_length) - (2 * a * vertical_dist))
		)
	)
	var x2 = a * (
		log(
			(-sqrt(lv2) * sqrt(4 * (a*a) + lv2) + lv2) / 
			((2 * a * arc_length) - (2 * a * vertical_dist))
		)
	)
	print("X1:%.3f, X2:%.3f" % [x1, x2])
	if abs(x1) > 100.0 or abs(x2) > 100.0 or abs(a) > 1000.0 or is_nan(x1) or is_nan(x2) or is_nan(a):
		print("bad")
		return
	create_catenary_rope(Vector3(x1, a * cosh(x1/a), 0.0), Vector3(x2, a * cosh(x2/a), 0.0), a, 0.1, 12, 6)
	
	
func solve_catenary_a(
	H: float,
	V: float,
	L: float,
	max_iter: int = 50,
	tolerance: float = 1e-6
) -> float:
	# Initial guess (parabolic approximation)
	var a = (H * H) / max(8.0 * max(abs(V), 0.001), 0.01)
	#var a = 388.8042839

	for i in max_iter:
		var f1 = fa(H, V, L, a)
		var f2 = fia(H, V, L, a)
		print("iter %d, fa %.3f, fia %.3f, a=%.3f" % [i, f1, f2, a])
		a = a - ( fa(H, V, L, a) / fia(H, V, L, a) )
		
	return a
	
func fia(H, V, L, a) -> float:
	var h2a = H / (2.0 * a)
	var r = 2 * ( sinh(h2a) - (h2a * cosh(h2a)) )
	return r
	
func fa(H, V, L, a) -> float:
	var lv = sqrt((L * L) - (V * V))
	var h2a = H / (2.0 * a)
	var r = (2 * a * sinh(h2a)) - lv
	return r

	
	

func catenary_y(x: float, a: float, l: float) -> float:
	# Centered catenary
	return a * (cosh((x - l * 0.5) / a) - cosh((l * 0.5) / a))
	
func create_catenary_rope_v5(
	start_point: Vector3,
	end_point: Vector3,
	drop: float,
	radius: float,
	segments: int,
	sides: int
) -> MeshInstance3D:
	assert(segments >= 2)
	assert(sides >= 3)

	var mesh := ArrayMesh.new()

	var vertices: PackedVector3Array = []
	var normals: PackedVector3Array = []
	var uvs: PackedVector2Array = []
	var indices: PackedInt32Array = []

	# Direction and length
	var delta: Vector3 = end_point - start_point
	var length := delta.length()
	var dir := delta.normalized()

	# Build a local 2D frame (X along rope, Y up)
	var up := Vector3.UP
	if abs(dir.dot(up)) > 0.99:
		up = Vector3.FORWARD

	var right := dir.cross(up).normalized()
	up = right.cross(dir).normalized()

	# Catenary parameter (simple numeric approximation)
	# Larger drop -> larger sag
	var a : float = length / max(drop * 2.0, 0.001)


	# Frame transport
	var prev_normal := up

	for i in range(segments + 1):
		var t := float(i) / segments
		var x := t * length

		# Position on curve
		var y := catenary_y(x, a, length)
		var center := start_point + dir * x + up * y

		# Tangent (finite difference)
		var dx := 0.001 * length
		var y2 := catenary_y(min(x + dx, length), a, length)
		var tangent := (dir * dx + up * (y2 - y)).normalized()

		# Transport frame
		var binormal := tangent.cross(prev_normal).normalized()
		var normal := binormal.cross(tangent).normalized()
		prev_normal = normal

		# Ring vertices
		for j in range(sides):
			var angle := TAU * float(j) / sides
			var offset := normal * cos(angle) * radius + binormal * sin(angle) * radius
			var pos : Vector3 = center + offset
			pos.y -= 2.75
			vertices.append(pos)
			normals.append(offset.normalized())
			uvs.append(self.UV)

	# Build indices
	for i in range(segments):
		var ring_a := i * sides
		var ring_b := (i + 1) * sides

		for j in range(sides):
			var aa := ring_a + j
			var b := ring_a + (j + 1) % sides
			var c := ring_b + j
			var d := ring_b + (j + 1) % sides

			indices.append_array([aa, c, b])
			indices.append_array([b, c, d])

	# Commit mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TEX_UV] = uvs

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mi := self
	mi.mesh = mesh
	return mi


func create_catenary_rope(
	start: Vector3,
	end: Vector3,
	a: float,
	radius: float,
	segments: int,
	sides: int
) -> MeshInstance3D:
	var total_dir := end - start
	var length := total_dir.length()
	var forward := total_dir.normalized()

	var half_len := length * 0.5
	var y_offset := a * cosh(half_len / a)

	var points: Array = []

	# Sample catenary points
	for i in range(segments + 1):
		var t := float(i) / segments
		var x : float = lerp(-half_len, half_len, t)
		var y : float = a * cosh(x / a) - y_offset
		points.append({
			"center": start + forward * (t * length) + Vector3.UP * y,
			"normal": Vector3.ZERO,
			"binormal": Vector3.ZERO
		})

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	var prev_normal := Vector3.UP

	for i in range(points.size()):
		# Compute tangent
		var tangent: Vector3
		if i == 0:
			tangent = (points[i + 1].center - points[i].center).normalized()
		elif i == points.size() - 1:
			tangent = (points[i].center - points[i - 1].center).normalized()
		else:
			tangent = (points[i + 1].center - points[i - 1].center).normalized()

		# Build stable frame
		var normal := prev_normal - tangent * prev_normal.dot(tangent)
		if normal.length() < 0.001:
			normal = tangent.cross(Vector3.FORWARD).normalized()
		else:
			normal = normal.normalized()

		var binormal := tangent.cross(normal).normalized()
		prev_normal = normal

		points[i] = {
			"center": points[i].center,
			"normal": normal,
			"binormal": binormal
		}

	var rings := []

	# Generate rings
	for p in points:
		var ring := []
		for j in range(sides):
			var angle := TAU * float(j) / sides
			var offset : Vector3 = p.normal * cos(angle) * radius + p.binormal * sin(angle) * radius
			ring.append(p.center + offset)
		rings.append(ring)

	# Build mesh
	surface.set_uv(self.UV)
	for i in range(segments):
		for j in range(sides):
			var jn := (j + 1) % sides

			var v0 : Vector3 = rings[i][j]
			var v1 : Vector3 = rings[i + 1][j]
			var v2 : Vector3 = rings[i + 1][jn]
			var v3 : Vector3 = rings[i][jn]

			surface.add_vertex(v0)
			surface.add_vertex(v1)
			surface.add_vertex(v2)

			surface.add_vertex(v0)
			surface.add_vertex(v2)
			surface.add_vertex(v3)

	surface.generate_normals()
	surface.generate_tangents()
	print("assigning mesh")

	var mesh := surface.commit()
	var rope := self
	rope.mesh = mesh
	return rope
	
	
	
func create_catenary_rope_v3(
	from_node: Node3D,
	to_node: Node3D,
	a: float,
	radius: float,
	segments: int,
	sides: int
) -> MeshInstance3D:
	assert(segments >= 2)
	assert(sides >= 3)

	var start := from_node.global_position
	var end := to_node.global_position

	var dir := end - start
	var length := dir.length()
	var forward := dir.normalized()

	# Local vertical axis (gravity)
	var gravity := Vector3.UP

	# Remove gravity component from forward to get horizontal axis
	var horizontal := (forward - gravity * forward.dot(gravity)).normalized()
	if horizontal.length() < 0.001:
		horizontal = Vector3.FORWARD

	var half_len := length * 0.5
	var base_offset := a * cosh(half_len / a)

	var points: Array[Vector3] = []

	# Sample curve with linear height correction
	for i in range(segments + 1):
		var t := float(i) / segments
		var x : float = lerp(-half_len, half_len, t)
		var base_height : float = lerp(0.0, end.dot(gravity) - start.dot(gravity), t)

		# Symmetric catenary sag
		var sag := a * cosh(x / a) - base_offset

		# Linear interpolation between endpoints
		var linear_height : float = lerp(start.dot(gravity), end.dot(gravity), t)

		var center := start + horizontal * (t * length) + gravity * (base_height + sag)

		points.append(center)

	# Build mesh
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	var prev_normal := Vector3.UP
	var rings := []

	for i in range(points.size()):
		# Tangent
		var tangent: Vector3
		if i == 0:
			tangent = (points[i + 1] - points[i]).normalized()
		elif i == points.size() - 1:
			tangent = (points[i] - points[i - 1]).normalized()
		else:
			tangent = (points[i + 1] - points[i - 1]).normalized()

		# Parallel transport frame
		var normal := prev_normal - tangent * prev_normal.dot(tangent)
		if normal.length() < 0.001:
			normal = tangent.cross(Vector3.FORWARD).normalized()
		else:
			normal = normal.normalized()

		var binormal := tangent.cross(normal).normalized()
		prev_normal = normal

		var ring := []
		for j in range(sides):
			var angle := TAU * float(j) / sides
			var offset := normal * cos(angle) * radius + binormal * sin(angle) * radius
			ring.append(points[i] + offset)
		rings.append(ring)

	# Triangles
	surface.set_uv(self.UV)
	for i in range(segments):
		for j in range(sides):
			var jn := (j + 1) % sides

			surface.add_vertex(rings[i][j])
			surface.add_vertex(rings[i + 1][j])
			surface.add_vertex(rings[i + 1][jn])

			surface.add_vertex(rings[i][j])
			surface.add_vertex(rings[i + 1][jn])
			surface.add_vertex(rings[i][jn])

	surface.generate_normals()
	surface.generate_tangents()

	var rope := self
	rope.mesh = surface.commit()
	return rope
