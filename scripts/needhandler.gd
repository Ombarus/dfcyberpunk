extends Object
class_name NeedHandler

var CurrentNeeds := {
	Globals.NEEDS.Satiety: 0.38,
	Globals.NEEDS.Energy: 0.8,
	Globals.NEEDS.Satisfaction: 0.3,
	Globals.NEEDS.Wealth: 0.01,
	Globals.NEEDS.Health: 1.0,
	Globals.NEEDS.Humanity: 1.0,
	Globals.NEEDS.Joy: 0.5,
	Globals.NEEDS.Security: 0.5,
	Globals.NEEDS.Curiosity: 0.5,
	Globals.NEEDS.Comfort: 0.5
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
	for need_type in Globals.NEEDS.values():
		score += plan.GetExpectedReward(need_type) / max(CurrentNeeds[need_type], 0.000001)
	return score


#Default
#GoGetItem
#GoDropItem
#Transfer
#toFromExchange
#TravelAnimState
#WalkRandomly
#~Goto   ~~~~~
#LoadWait
#Wait
#GoSleepInBed
#*Sleep  *****
#CookInKitchen2
#GoPutFoodInFridge
#RefilFridge2
#Spawn
#*EatSelectedFood ****
#SleepOnFloor

func ApplyNeedForAction(curAction : String, delta : float, param : Dictionary, curActionState : Globals.ACTION_STATE) -> void:
	var plan : ActionPlan = param.get("current_plan", null)
	for r in plan.ActualReward:
		if curAction == r["Action"]:
			if curActionState == r["State"]:
				var mult := 1.0
				if curActionState == Globals.ACTION_STATE.Running:
					mult = delta
				var rewards : Dictionary = r["Rewards"]
				for need in rewards:
					ApplyNeed(need, rewards[need] * mult)
