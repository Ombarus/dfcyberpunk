extends Object
class_name NeedHandler

var CurrentNeeds := {
	Globals.NEEDS.Satiety: 1.0,
	Globals.NEEDS.Energy: 1.0,
	Globals.NEEDS.Satisfaction: 0.5
}

func Current(need : Globals.NEEDS) -> float:
	return CurrentNeeds[need]

func SetNeed(need: Globals.NEEDS, val :float) -> void:
	CurrentNeeds[need] = clamp(val, 0.0, 1.0)
	
func GetNeed(need: Globals.NEEDS) -> float:
	return CurrentNeeds[need]

func ApplyNeed(need : Globals.NEEDS, amount : float) -> void:
	var curval : float = CurrentNeeds[need]
	CurrentNeeds[need] = clamp(curval + amount, 0.0, 1.0)
	
func ApplyNeedOverTime(need : Globals.NEEDS, amount : float, delta : float) -> void:
	var curval : float = CurrentNeeds[need]
	var newval : float = curval + (amount * delta)
	newval = clamp(newval, 0.0, 1.0)
	CurrentNeeds[need] = newval

func GetRewardScoreFromPlan(plan : ActionPlan) -> float:
	var score := 0.0
	score += plan.SatietyReward / max(CurrentNeeds[Globals.NEEDS.Satiety], 0.0001)
	score += plan.EnergyReward / max(CurrentNeeds[Globals.NEEDS.Energy], 0.0001)
	score += plan.SatisfactionReward / max(CurrentNeeds[Globals.NEEDS.Satisfaction], 0.0001)
	return score
