extends Advertisement

# For office, the plan returned should be based on who's working there
# What time it is, etc.
func GetActionPlansFor(npc : Entity) -> Array:
	var results := []
	if npc.name != "NPCOfficeWorker":
		return results
	else:
		for i in ActionPlans:
			var new_plan : ActionPlan = i.duplicate()
			results.append(new_plan)
	
	return results
