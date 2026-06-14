extends Object
class_name NeedHandler

var CurrentNeeds := {
	Globals.NEEDS.Satiety: 0.38,
	Globals.NEEDS.Energy: 0.8,
	Globals.NEEDS.Satisfaction: 0.3,
	Globals.NEEDS.Wealth: 0.01,
	Globals.NEEDS.Health: 0.9,
	Globals.NEEDS.Humanity: 0.7,
	Globals.NEEDS.Joy: 0.5,
	Globals.NEEDS.Security: 0.5,
	Globals.NEEDS.Curiosity: 0.5,
	Globals.NEEDS.Comfort: 0.5,
	Globals.NEEDS.Stamina: 1.0
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
		var expected_reward : float = plan.GetExpectedReward(need_type)
		if CurrentNeeds[need_type] + expected_reward > 1.0:
			# Some reward are fixed (things don't cost less because you don't have the money)
			# But some reward should adjust (The hospital can fix you up from 0 to 100, but if you're at 50% they can do that too)
			# "Overflow" basically mean "make the reward dynamic up to a max of X"
			# If there is no overflow than we actively discourage doing an action that would go above 1.0
			if plan.AllowOverflow(need_type):
				expected_reward = 1.0 - CurrentNeeds[need_type]
			else:
				score -= 1000
		score += expected_reward * Sigmoid(CurrentNeeds[need_type])
	return score
	
# original: reward / current_need give a 100 multiplier around 0.001 
# but then goes down quickly so that anything above 0.2 share multiplier between 4 and 1
#
# Trying with sigmoid function. Current values (100 & 10) 
# should give a 100 multiplier around 0~0.4, 
# then quickly drop and ~15 multiplier for anything above 0.6
func Sigmoid(a):
	var l := 100.0
	var k := -20.0
	var x0 := 0.5
	var mult : float = l / (1 + exp(-k*(a-x0)))
	return mult
	

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
