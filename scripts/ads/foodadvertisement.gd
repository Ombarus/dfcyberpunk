extends Advertisement

@export var override_satiety : float = 0.6
@export var override_satisfaction :float = 0.01

@export var override_satiety_grade := Globals.GRADE.Big
@export var override_satiety_per := 1.0
@export var override_satisfaction_grade := Globals.GRADE.Small
@export var override_satisfaction_per := 1.0

var _eat_me : ActionPlan
var _put_in_fridge : ActionPlan

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	_eat_me = ActionPlan.new()
	_eat_me.ActionName = "EatSelectedFood"
	_eat_me._satietyReward = override_satiety
	_eat_me._satisfactionReward = override_satisfaction
	_eat_me.NewSatietyReward = override_satiety_grade
	_eat_me.SatietyAdjustPer = override_satiety_per
	_eat_me.NewSatisfactionReward = override_satisfaction_grade
	_eat_me.SatisfactionAdjustPer = override_satisfaction_per
	
	_put_in_fridge = ActionPlan.new()
	_put_in_fridge.ActionName = "GoPutFoodInFridge"
	_put_in_fridge.NewSatisfactionReward = Globals.GRADE.Medium # Fake?
	
	self.ActionPlans = [
		_eat_me,
		_put_in_fridge
	]
	
	for data in _eat_me.ActualReward:
		if data["Action"] == "Eat" and data["State"] == Globals.ACTION_STATE.Running:
			var satiety_before = data["Rewards"][Globals.NEEDS.Satiety]
			print("%s: Satiety Before %.5f" % [self.name, satiety_before])
			#NOTE: I don't know if I'm working with a copy or a static array here. I need to validate it's only changing the copy
			if override_satiety_grade == Globals.GRADE.Unset:
				data["Rewards"][Globals.NEEDS.Satiety] = override_satiety / 4.0
			else:
				data["Rewards"][Globals.NEEDS.Satiety] = Globals.REWARD_BASE[Globals.NEEDS.Satiety][override_satiety_grade] * override_satiety_per
			print("%s: Satiety After %.5f" % [self.name, data["Rewards"][Globals.NEEDS.Satiety]])
		if data["Action"] == "Eat" and data["State"] == Globals.ACTION_STATE.Finished:
			var satisfaction_before = data["Rewards"][Globals.NEEDS.Satisfaction]
			print("%s: Satisfaction Before %.5f" % [self.name, satisfaction_before])
			#NOTE: I don't know if I'm working with a copy or a static array here. I need to validate it's only changing the copy
			if override_satisfaction_grade == Globals.GRADE.Unset:
				data["Rewards"][Globals.NEEDS.Satisfaction] = override_satisfaction
			else:
				data["Rewards"][Globals.NEEDS.Satisfaction] = Globals.REWARD_BASE[Globals.NEEDS.Satisfaction][override_satisfaction_grade] * override_satisfaction_per
			print("%s: Satisfaction After %.5f" % [self.name, data["Rewards"][Globals.NEEDS.Satisfaction]])

# Want to have somewhat dynamic plans.
# This allow an Advertisement to recalculate reward based on who's asking
func GetActionPlansFor(npc : Entity) -> Array:
	var container : Advertisement = self.AdMetaData["container"]
	var results := []
	if container == null or container.Type != Globals.AD_TYPE.Fridge:
		results.append(_put_in_fridge.duplicate())
		
	results.append(_eat_me)
	return results
