extends Node3D

@export var hide_cable := true

func _ready() -> void:
	hide_ropes(self)

func hide_ropes(n : Node):
	for c in n.get_children(true):
		var r := c as Rope
		if r != null:
			r.visible = not hide_cable
		if c.name.contains("8mCable"):
			c.visible = not hide_cable
		hide_ropes(c)
