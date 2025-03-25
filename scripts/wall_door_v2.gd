extends Node3D

@onready var AnimPlayer : AnimationPlayer = get_node("WallDoorv22/AnimationPlayer")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		print("entered")
		AnimPlayer.play("DoorOpen")


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		print("exited")
		AnimPlayer.play_backwards("DoorOpen")
