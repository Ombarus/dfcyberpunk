extends Node2D
class_name Advertisement

enum TYPE {
	BED,
	FOOD,
	KITCHEN,
	CURRENCY,
	OTHER
}

@export var Type : TYPE = TYPE.OTHER

# Wanted to call this "Owner" but Godot has a property "owner" that clashes
# The idea is to eventually have more complex relationship anyway
# Like Borrowed, Selling, etc.
@export var BelongTo : Entity

@export var ActionPlans : Array

func _ready() -> void:
	self.add_to_group(str(self.Type))
	
func _exit_tree() -> void:
	self.remove_from_group(str(self.Type))
