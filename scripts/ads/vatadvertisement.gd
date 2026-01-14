extends Advertisement

@export var pack : PackedScene

func _ready() -> void:
	super._ready()

func _on_timer_timeout() -> void:
	var inv : Array = self.Inventory
	if inv.size() > 5:
		return

	var n := pack.instantiate() as Advertisement
	self.get_parent().add_child(n)
	n.global_position = self.global_position
	n.visible = false
	inv.append(n)
	self.Inventory = inv
	n.AdMetaData["container"] = self
