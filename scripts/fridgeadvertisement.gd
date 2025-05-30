extends Advertisement

func _ready() -> void:
	super._ready()
	self.AdMetaData["inventory"] = []
	
	var spag_recipe := ActionPlan.new()
	spag_recipe.ActionName = "CookInKitchen2"
	spag_recipe.EnergyReward = -0.05
	spag_recipe.SatietyReward = 0.15 # fake reward to encourage NPC to cook when hungry
	spag_recipe.SatisfactionReward = 0.05
	spag_recipe.RichnessReward = 0.0
	#spag_recipe.SpawnReward = preload("res://scenes/food_spag.tscn")
	spag_recipe.SpawnRewardType = Globals.AD_TYPE.Food
	
	var pie_recipe := ActionPlan.new()
	pie_recipe.ActionName = "CookInKitchen2"
	pie_recipe.EnergyReward = -0.045
	pie_recipe.SatietyReward = 0.10 # fake reward to encourage NPC to cook when hungry
	pie_recipe.SatisfactionReward = 0.08
	pie_recipe.RichnessReward = 0.0
	#pie_recipe.SpawnReward = preload("res://scenes/food_pie.tscn")
	pie_recipe.SpawnRewardType = Globals.AD_TYPE.Food
	
	var steak_recipe := ActionPlan.new()
	steak_recipe.ActionName = "CookInKitchen2"
	steak_recipe.EnergyReward = -0.03
	steak_recipe.SatietyReward = 0.18 # fake reward to encourage NPC to cook when hungry
	steak_recipe.SatisfactionReward = 0.05
	steak_recipe.RichnessReward = 0.0
	steak_recipe.SpawnReward = preload("res://scenes/food_steak3d.tscn")
	steak_recipe.SpawnRewardType = Globals.AD_TYPE.Food
	
	var refill_fridge := ActionPlan.new()
	refill_fridge.ActionName = "RefillFridge"
	refill_fridge.EnergyReward = -0.05
	refill_fridge.SatietyReward = 0.0
	refill_fridge.SatisfactionReward = 0.2
	refill_fridge.RichnessReward = -0.00005 # 50$ of 1M
	refill_fridge.SpawnReward = preload("res://scenes/foodstuff3d.tscn")
	refill_fridge.SpawnRewardType = Globals.AD_TYPE.Foodstuff
	
	self.ActionPlans = [
		#spag_recipe,
		#pie_recipe,
		steak_recipe,
		refill_fridge
	]
	
# Want to have somewhat dynamic plans.
# This allow an Advertisement to recalculate reward based on who's asking
func GetActionPlansFor(npc : Entity) -> Array:
	var num_foodstuff : int = len(self.AdMetaData["inventory"])
	if num_foodstuff < 1:
		return [self.ActionPlans[-1].duplicate()]

	var nodes : Array = get_tree().get_nodes_in_group(str(Globals.AD_TYPE.Food))
	var food_count : int = nodes.size()
	var results := []
	for i in ActionPlans:
		var plan := i as ActionPlan
		var new_plan := plan.duplicate()
		if new_plan.SpawnRewardType == Globals.AD_TYPE.Food:
			new_plan.SatisfactionReward = new_plan.SatisfactionReward / (food_count + 1)
		if new_plan.SpawnRewardType == Globals.AD_TYPE.Foodstuff:
			new_plan.SatisfactionReward = new_plan.SatisfactionReward / (num_foodstuff + 1)
		results.append(new_plan)
	return results
