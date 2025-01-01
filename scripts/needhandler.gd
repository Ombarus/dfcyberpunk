extends Object
class_name NeedHandler

var CurrentNeeds := {
	Globals.NEEDS.Satiety: 1.0,
	Globals.NEEDS.Energy: 1.0,
	Globals.NEEDS.Satisfaction: 1.0
}

func Current(need : Globals.NEEDS) -> float:
	return CurrentNeeds[need]

func ApplyNeed(need : Globals.NEEDS, amount : float) -> void:
	var curval : float = CurrentNeeds[need]
	CurrentNeeds[need] = clamp(curval + amount, 0.0, 1.0)
	
func ApplyNeedOverTime(need : Globals.NEEDS, amount : float, delta : float) -> void:
	var curval : float = CurrentNeeds[need]
	var newval : float = curval + (amount * delta)
	newval = clamp(newval, 0.0, 1.0)
	CurrentNeeds[need] = newval

func GetRewardScore(rewards : Dictionary) -> float:
	var score := 0.0
	for need in rewards:
		if rewards[need] != 0:
			score += rewards[need] / CurrentNeeds[need]
	return score
