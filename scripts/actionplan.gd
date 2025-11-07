extends Resource
class_name ActionPlan

@export var ActionName : String
# This is the remnant of deprecation. I initially set the float value directly
# I've kept it as a fallback if I ever need to set a specific value
var _energyReward : float
var _satietyReward : float
var _satisfactionReward : float
var _wealthReward : float
var _healthReward : float
var _humanityReward : float
var _joyReward : float
var _securityReward : float
var _curiosityReward : float
var _comfortReward : float

@export var NewEnergyReward := Globals.GRADE.Unset
@export var EnergyAdjustPer := 1.0
@export var NewSatietyReward := Globals.GRADE.Unset
@export var SatietyAdjustPer := 1.0
@export var NewSatisfactionReward := Globals.GRADE.Unset
@export var SatisfactionAdjustPer := 1.0
@export var NewWealthReward := Globals.GRADE.Unset
@export var WealthAdjustPer := 1.0

@export var HealthReward := Globals.GRADE.Unset
@export var HealthAdjustPer := 1.0
@export var HumanityReward := Globals.GRADE.Unset
@export var HumanityAdjustPer := 1.0
@export var JoyReward := Globals.GRADE.Unset
@export var JoyAdjustPer := 1.0
@export var SecurityReward := Globals.GRADE.Unset
@export var SecurityAdjustPer := 1.0
@export var CuriosityReward := Globals.GRADE.Unset
@export var CuriosityAdjustPer := 1.0
@export var ComfortReward := Globals.GRADE.Unset
@export var ComfortAdjustPer := 1.0

# This SpawnReward might not be necessary, maybe this
# should be part of the ActionName
# (ie: ActionName is "CookSpaghetti" and the stats for making spaghetti is in the action)
# (the "CookSpaghetti" action could just initialize a few parameters and call a generic "Cook" action)
# (ex: CookSpaghetti init a list of ingredients and Cook action just tries to find them)
@export var SpawnReward : PackedScene
# At the same time, this SpawnRewardType might not be enough
# We need a bunch of properties that might help the NPC take decision
# Like is this meal Vegan? Does this Job make me more money?
# How far is this? How strong is it? How much damage does it do? etc.
# Not sure how to keep this generic for all the type of ads
# Maybe a generic Dictionary or a list of "tags"
@export var SpawnRewardType : Globals.AD_TYPE
@export var SpawnRewardCount : int = 1

# This plan is only available between X and Y hours
# I'll probably want to expand this for more complex schedules (like weekends?)
@export var StartHour : int = -1
@export var EndHour : int = -1

func GetExpectedReward(need : Globals.NEEDS) -> float:
	if need == Globals.NEEDS.Energy:
		if NewEnergyReward == Globals.GRADE.Unset:
			return _energyReward
		else:
			return Globals.REWARD_BASE[Globals.NEEDS.Energy][NewEnergyReward] * EnergyAdjustPer
	if need == Globals.NEEDS.Satiety:
		if NewSatietyReward == Globals.GRADE.Unset:
			return _satietyReward
		else:
			return Globals.REWARD_BASE[Globals.NEEDS.Satiety][NewSatietyReward] * SatietyAdjustPer
	if need == Globals.NEEDS.Satisfaction:
		if NewSatisfactionReward == Globals.GRADE.Unset:
			return _satisfactionReward
		else:
			return Globals.REWARD_BASE[Globals.NEEDS.Satisfaction][NewSatisfactionReward] * SatisfactionAdjustPer
	if need == Globals.NEEDS.Wealth:
		if NewWealthReward == Globals.GRADE.Unset:
			return _wealthReward
		else:
			return Globals.REWARD_BASE[Globals.NEEDS.Wealth][NewWealthReward] * WealthAdjustPer
	if need == Globals.NEEDS.Health:
		if HealthReward == Globals.GRADE.Unset:
			return _healthReward
		else:
			return Globals.REWARD_BASE[Globals.NEEDS.Health][HealthReward] * HealthAdjustPer
	if need == Globals.NEEDS.Humanity:
		if HumanityReward == Globals.GRADE.Unset:
			return _humanityReward
		else:
			return Globals.REWARD_BASE[Globals.NEEDS.Humanity][HumanityReward] * HumanityAdjustPer
	if need == Globals.NEEDS.Joy:
		if JoyReward == Globals.GRADE.Unset:
			return _joyReward
		else:
			return Globals.REWARD_BASE[Globals.NEEDS.Joy][JoyReward] * JoyAdjustPer
	if need == Globals.NEEDS.Security:
		if SecurityReward == Globals.GRADE.Unset:
			return _securityReward
		else:
			return Globals.REWARD_BASE[Globals.NEEDS.Security][SecurityReward] * SecurityAdjustPer
	if need == Globals.NEEDS.Curiosity:
		if CuriosityReward == Globals.GRADE.Unset:
			return _curiosityReward
		else:
			return Globals.REWARD_BASE[Globals.NEEDS.Curiosity][CuriosityReward] * CuriosityAdjustPer
	if need == Globals.NEEDS.Comfort:
		if ComfortReward == Globals.GRADE.Unset:
			return _comfortReward
		else:
			return Globals.REWARD_BASE[Globals.NEEDS.Comfort][ComfortReward] * ComfortAdjustPer
			
			
	return 0.0

# Right now it's generic and cover all Actions
# but the idea is to inventually be able to customize the Rewards by Ads
# ie: Different food give more/less Satiety per second, bad job give less Wealth, etc.
var ActualReward := [
	{
		"Action": "Sleep",
		"State": Globals.ACTION_STATE.Running,
		# If running, need is /sec, if not then it's given whole on state transition
		"Rewards": {Globals.NEEDS.Energy: Globals.REWARD_BASE[Globals.NEEDS.Energy][Globals.GRADE.VBig] / Globals.DAY_LENGTH_SEC}
	},
	{
		"Action": "GoSleepInBed",
		"State": Globals.ACTION_STATE.Finished,
		"Rewards": {Globals.NEEDS.Satisfaction: Globals.REWARD_BASE[Globals.NEEDS.Satisfaction][Globals.GRADE.Small]}
	},
	{
		"Action": "Eat",
		"State": Globals.ACTION_STATE.Running,
		"Rewards": {Globals.NEEDS.Satiety: Globals.REWARD_BASE[Globals.NEEDS.Satiety][Globals.GRADE.Big] / 4.0} # Steak: Big over 4 seconds (currently hardcoded)
	},
	{
		"Action": "Eat",
		"State": Globals.ACTION_STATE.Finished,
		"Rewards": {Globals.NEEDS.Satisfaction: Globals.REWARD_BASE[Globals.NEEDS.Satisfaction][Globals.GRADE.Small]}
	},
	{
		"Action": "EatAtBar",
		"State": Globals.ACTION_STATE.Finished,
		"Rewards": {
			Globals.NEEDS.Energy: Globals.REWARD_BASE[Globals.NEEDS.Energy][Globals.GRADE.VSmall],
			Globals.NEEDS.Wealth: -Globals.REWARD_BASE[Globals.NEEDS.Wealth][Globals.GRADE.VSmall]
		}
	},
	{
		"Action": "WalkRandomly",
		"State": Globals.ACTION_STATE.Finished,
		"Rewards": {Globals.NEEDS.Satisfaction: Globals.REWARD_BASE[Globals.NEEDS.Satisfaction][Globals.GRADE.Small]}
	},
	{
		"Action": "RefillFridge2",
		"State": Globals.ACTION_STATE.Finished,
		"Rewards": {
			Globals.NEEDS.Satisfaction: Globals.REWARD_BASE[Globals.NEEDS.Satisfaction][Globals.GRADE.Small],
			Globals.NEEDS.Wealth: -Globals.REWARD_BASE[Globals.NEEDS.Wealth][Globals.GRADE.VSmall]
		}
	},
	{
		"Action": "CookInKitchen2",
		"State": Globals.ACTION_STATE.Finished,
		"Rewards": {Globals.NEEDS.Satisfaction: Globals.REWARD_BASE[Globals.NEEDS.Satisfaction][Globals.GRADE.Small]}
	},
	{
		"Action": "Default",
		"State": Globals.ACTION_STATE.Running,
		# Satiety 0.72 / day, Energy 0.54 / day, Satisfaction 0.45 / day
		 # consider 1 day = 900 seconds, 0.00111 means 1 to 0 in 100 seconds
		"Rewards": {
			Globals.NEEDS.Satiety: -0.0008,
			Globals.NEEDS.Energy: -0.0006,
			Globals.NEEDS.Satisfaction: -0.0005,
			Globals.NEEDS.Joy: -0.0005,
			Globals.NEEDS.Curiosity: -0.00005 # Will really depend on the personality
		}
	},
	{
		"Action": "SleepOnFloor",
		"State": Globals.ACTION_STATE.Finished,
		"Rewards": {Globals.NEEDS.Satisfaction: -Globals.REWARD_BASE[Globals.NEEDS.Satisfaction][Globals.GRADE.Medium]}
	},
	{
		"Action": "WorkAtBar",
		"State": Globals.ACTION_STATE.Finished,
		"Rewards": {
			Globals.NEEDS.Satisfaction: Globals.REWARD_BASE[Globals.NEEDS.Satisfaction][Globals.GRADE.Big],
			Globals.NEEDS.Wealth: Globals.REWARD_BASE[Globals.NEEDS.Wealth][Globals.GRADE.Small]
		}
	},
	{
		"Action": "WorkAtShop",
		"State": Globals.ACTION_STATE.Finished,
		"Rewards": {
			Globals.NEEDS.Satisfaction: Globals.REWARD_BASE[Globals.NEEDS.Satisfaction][Globals.GRADE.Big],
			Globals.NEEDS.Wealth: Globals.REWARD_BASE[Globals.NEEDS.Wealth][Globals.GRADE.Small]
		}
	},
	{
		"Action": "Deliver",
		"State": Globals.ACTION_STATE.Finished,
		"Rewards": {
			Globals.NEEDS.Satisfaction: Globals.REWARD_BASE[Globals.NEEDS.Satisfaction][Globals.GRADE.Big],
			Globals.NEEDS.Wealth: Globals.REWARD_BASE[Globals.NEEDS.Wealth][Globals.GRADE.Small] * 2.0 # Currently 2 delivery hardcoded
		}
	},
	{
		"Action": "WalkRandomly",
		"State": Globals.ACTION_STATE.Running,
		"Rewards": {
			Globals.NEEDS.Satisfaction: Globals.REWARD_BASE[Globals.NEEDS.Satisfaction][Globals.GRADE.VSmall] / 20.0 # arbitrary VSmall reward every 20 seconds of walking (~32min gametime?)
		}
	}
]
