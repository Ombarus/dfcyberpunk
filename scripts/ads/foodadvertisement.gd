extends Advertisement

var _eat_me : ActionPlan
var _put_in_fridge : ActionPlan

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	_eat_me = ActionPlan.new()
	_eat_me.ActionName = "EatSelectedFood"
	_eat_me.EnergyReward = 0.0
	_eat_me.SatietyReward = Globals.REWARD_BASE[Globals.NEEDS.Satiety][Globals.GRADE.Big]
	_eat_me.SatisfactionReward = Globals.REWARD_BASE[Globals.NEEDS.Satisfaction][Globals.GRADE.Small]
	_eat_me.RichnessReward = 0.0
	
	_put_in_fridge = ActionPlan.new()
	_put_in_fridge.ActionName = "GoPutFoodInFridge"
	_put_in_fridge.EnergyReward = 0.0
	_put_in_fridge.SatietyReward = 0.0
	_put_in_fridge.SatisfactionReward = 0.2 # Fake?
	_put_in_fridge.RichnessReward = 0.0
	
	self.ActionPlans = [
		_eat_me,
		_put_in_fridge
	]

# Want to have somewhat dynamic plans.
# This allow an Advertisement to recalculate reward based on who's asking
func GetActionPlansFor(npc : Entity) -> Array:
	var container : Advertisement = self.AdMetaData["container"]
	var results := []
	if container == null or container.Type != Globals.AD_TYPE.Fridge:
		results.append(_put_in_fridge.duplicate())
		
	results.append(_eat_me)
	return results
