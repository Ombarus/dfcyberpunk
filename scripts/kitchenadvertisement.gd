extends Advertisement

func _ready() -> void:
	super._ready()
	self.AdMetaData["inventory"] = []
	
	var preserve_food := ActionPlan.new()
	preserve_food.ActionName = "PutFoodInFridge"
	preserve_food.EnergyReward = 0.0
	preserve_food.SatietyReward = 0.0
	preserve_food.SatisfactionReward = 0.2
	
	self.ActionPlans = [
		preserve_food
	]
	

# Want to have somewhat dynamic plans.
# This allow an Advertisement to recalculate reward based on who's asking
func GetActionPlansFor(npc : Entity) -> Array:
	var foods : Array = self.AdMetaData.get("inventory", [])
	var results := []
	for i in foods:
		if (i as Advertisement).Type == Globals.AD_TYPE.Food:
			var plan := self.ActionPlans[0] as ActionPlan
			var new_plan := plan.duplicate()
			results.append(new_plan)

	return results
