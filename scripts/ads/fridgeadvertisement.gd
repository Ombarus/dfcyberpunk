extends Advertisement

func _ready() -> void:
	super._ready()
	
	# Very filling but not as satisfying
	var spag_recipe := ActionPlan.new()
	spag_recipe.ActionName = "CookInKitchen2"
	spag_recipe.NewSatietyReward = Globals.GRADE.VSmall # fake reward to encourage NPC to cook when hungry
	spag_recipe.SatietyAdjustPer = 1.1
	spag_recipe.NewSatisfactionReward = Globals.GRADE.Small
	spag_recipe.SatisfactionAdjustPer = 0.9
	spag_recipe.SpawnReward = preload("res://scenes/food_spaghetti3d.tscn")
	spag_recipe.SpawnRewardType = Globals.AD_TYPE.Food
	
	# Not very filling, but increase sati
	var pie_recipe := ActionPlan.new()
	pie_recipe.ActionName = "CookInKitchen2"
	pie_recipe.NewSatietyReward = Globals.GRADE.VSmall # fake reward to encourage NPC to cook when hungry
	pie_recipe.SatietyAdjustPer = 0.5
	pie_recipe.NewSatisfactionReward = Globals.GRADE.Small
	pie_recipe.SatisfactionAdjustPer = 1.5
	pie_recipe.SpawnReward = preload("res://scenes/food_pie3d.tscn")
	pie_recipe.SpawnRewardType = Globals.AD_TYPE.Food
	
	# half/half
	var steak_recipe := ActionPlan.new()
	steak_recipe.ActionName = "CookInKitchen2"
	steak_recipe.NewSatietyReward = Globals.GRADE.VSmall # fake reward to encourage NPC to cook when hungry
	steak_recipe.SatietyAdjustPer = 1.0
	steak_recipe.NewSatisfactionReward = Globals.GRADE.Small
	steak_recipe.SatisfactionAdjustPer = 1.0
	steak_recipe.SpawnReward = preload("res://scenes/food_steak3d.tscn")
	steak_recipe.SpawnRewardType = Globals.AD_TYPE.Food
	
	var refill_fridge := ActionPlan.new()
	refill_fridge.ActionName = "RefillFridge2"
	refill_fridge.NewSatietyReward = Globals.GRADE.VSmall # fake reward to encourage NPC to cook when hungry
	refill_fridge.SatietyAdjustPer = 1.0
	refill_fridge.NewSatisfactionReward = Globals.GRADE.Small
	refill_fridge.SatisfactionAdjustPer = 1.0
	refill_fridge.NewRichnessReward = Globals.GRADE.VSmall
	refill_fridge.RichnessAdjustPer = -1.0
	refill_fridge.SpawnReward = preload("res://scenes/foodstuff3d.tscn")
	refill_fridge.SpawnRewardType = Globals.AD_TYPE.Foodstuff
	refill_fridge.SpawnRewardCount = 5
	
	self.ActionPlans = [
		spag_recipe,
		pie_recipe,
		steak_recipe,
		refill_fridge
	]
		
	
# Want to have somewhat dynamic plans.
# This allow an Advertisement to recalculate reward based on who's asking
func GetActionPlansFor(npc : Entity) -> Array:
	var num_foodstuff := 0
	var num_food := 0
	var results := []
	var inv : Array = self.Inventory
	for i in inv:
		var ad := i as Advertisement
		if ad.Type == Globals.AD_TYPE.Foodstuff:
			num_foodstuff += 1
		elif ad.Type == Globals.AD_TYPE.Food:
			num_food += 1
		
	for i in ActionPlans:
		var plan := i as ActionPlan
		var new_plan := plan.duplicate() as ActionPlan
		if new_plan.SpawnRewardType == Globals.AD_TYPE.Food and num_foodstuff > 0:
			# Square it so it's not linear, we REALLY don't want more than 2 meals (but 1 * 1 still = 1 so doesn't change the reward for the first meal)
			new_plan.SatisfactionAdjustPer = new_plan.SatisfactionAdjustPer / ((num_food + 1) * (num_food + 1))
			new_plan.SatietyAdjustPer = new_plan.SatietyAdjustPer / ((num_food + 1) * (num_food + 1))
			results.append(new_plan)
		# BUG: RefillFridge2 only work if the fridge doesn't have foodstuff in it 
		elif new_plan.SpawnRewardType == Globals.AD_TYPE.Foodstuff and num_foodstuff == 0:
			# Square it so it's not linear, we REALLY don't want more than 2 meals (but 1 * 1 still = 1 so doesn't change the reward for the first meal)
			new_plan.SatisfactionAdjustPer = new_plan.SatisfactionAdjustPer / ((num_food + 1) * (num_food + 1))
			results.append(new_plan)

	return results
