extends Node3D

@export var grid_size := 20
@export var cell_size := 1.0

@export var grid_color := Color(0.35, 0.35, 0.35, 0.7)

@export var axis_x_color := Color.RED
@export var axis_y_color := Color.GREEN
@export var axis_z_color := Color.BLUE

func _ready():
	add_grid()
	add_axes()


func add_grid():
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()

	mesh_instance.mesh = immediate_mesh

	var material := ORMMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = grid_color

	mesh_instance.material_override = material

	add_child(mesh_instance)

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var half := grid_size * cell_size * 0.5

	for i in range(grid_size + 1):
		var p := -half + i * cell_size

		# Lines parallel to Z
		immediate_mesh.surface_add_vertex(Vector3(p, 0, -half))
		immediate_mesh.surface_add_vertex(Vector3(p, 0, half))

		# Lines parallel to X
		immediate_mesh.surface_add_vertex(Vector3(-half, 0, p))
		immediate_mesh.surface_add_vertex(Vector3(half, 0, p))

	immediate_mesh.surface_end()


func add_axes():
	var axis_length := grid_size * cell_size * 0.6

	# X Axis (Red)
	create_axis(
		Vector3(-axis_length, 0, 0),
		Vector3(axis_length, 0, 0),
		axis_x_color
	)

	# Y Axis (Green)
	create_axis(
		Vector3(0, -axis_length, 0),
		Vector3(0, axis_length, 0),
		axis_y_color
	)

	# Z Axis (Blue)
	create_axis(
		Vector3(0, 0, -axis_length),
		Vector3(0, 0, axis_length),
		axis_z_color
	)


func create_axis(from: Vector3, to: Vector3, color: Color):
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()

	mesh_instance.mesh = immediate_mesh

	var material := ORMMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color

	mesh_instance.material_override = material

	add_child(mesh_instance)

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	immediate_mesh.surface_add_vertex(from)
	immediate_mesh.surface_add_vertex(to)

	immediate_mesh.surface_end()
