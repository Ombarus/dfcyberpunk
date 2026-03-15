@tool
extends Node3D

@export_tool_button("Arrange")
var arrange_button = arrange_children

@export_tool_button("Reset")
var reset_button = reset_children

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func reset_children():
	for child in get_children():
		if not child is Node3D:
			continue
		var node := child as MeshInstance3D
		if node == null:
			continue
		node.position = Vector3.ZERO

func _sort_by_depth(a: MeshInstance3D, b: MeshInstance3D) -> bool:
	var size_a = a.mesh.get_aabb().size
	var size_b = b.mesh.get_aabb().size
	return (size_a.z + size_a.x) > (size_b.z + size_b.x)

func arrange_children():
	var max_x := 200.0
	var z_spacing := 1.0
	var x_spacing := 1.0
	var x := 0.0
	var z := 0.0
	var row_depth := 0.0
	var sorted_children := []
	for child in get_children():
		if not child is Node3D:
			continue
		var node := child as MeshInstance3D
		if node == null:
			continue
		sorted_children.append(child)
	
	sorted_children.sort_custom(_sort_by_depth)
	
	for child in sorted_children:
		var node := child as MeshInstance3D
		var aabb := node.mesh.get_aabb()
		var aabb_size := aabb.size
		if x + aabb_size.x > max_x:
			x = 0.0
			z += row_depth + z_spacing
			row_depth = 0.0
		
		node.position = Vector3(x - aabb.position.x, -aabb.position.y, z - aabb.position.z)
		x += aabb_size.x + x_spacing
		row_depth = max(row_depth, aabb_size.z)
