extends Node2D
class_name Advertisement

@export var Type : Globals.AD_TYPE = Globals.AD_TYPE.Other

# Wanted to call this "Owner" but Godot has a property "owner" that clashes
# The idea is to eventually have more complex relationship anyway
# Like Borrowed, Selling, etc.
@export var BelongTo : Entity

@export var ActionPlans : Array

# Want to have somewhat dynamic plans.
# This allow an Advertisement to recalculate reward based on who's asking
func GetActionPlansFor(npc : Entity) -> Array:
	if self.Type != Globals.AD_TYPE.Food:
		return ActionPlans
		
	var nodes : Array = get_tree().get_nodes_in_group(str(Globals.AD_TYPE.Food))
	var food_count : int = nodes.size()
	var results := []
	for i in ActionPlans:
		var plan := i as ActionPlan
		var new_plan := plan.duplicate()
		new_plan.SatisfactionReward = new_plan.SatisfactionReward / food_count
		results.append(new_plan)
	return results
	

func _ready() -> void:
	self.add_to_group(str(self.Type))
	
func _exit_tree() -> void:
	self.remove_from_group(str(self.Type))
