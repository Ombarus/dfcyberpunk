extends Advertisement

func GetActionPlansFor(npc : Entity) -> Array:
	var work_at_bar := ActionPlan.new()
	work_at_bar.ActionName = "WorkAtBar"
	work_at_bar.EnergyReward = 0.0
	work_at_bar.SatietyReward = 0.0
	work_at_bar.SatisfactionReward = 0.40
	work_at_bar.RichnessReward = 0.00015 # 150$ of 1M	
	
	return [work_at_bar]
