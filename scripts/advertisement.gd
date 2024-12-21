extends Node2D
class_name Advertisement

enum TYPE {
	BED,
	FOOD,
	KITCHEN,
	OTHER
}

@export var Type : TYPE = TYPE.OTHER

@export var Owner : Entity

func _ready() -> void:
	self.add_to_group(str(self.Type))
	
func _exit_tree() -> void:
	self.remove_from_group(str(self.Type))
