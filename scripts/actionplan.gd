extends Resource
class_name ActionPlan

@export var ActionName : String
@export var EnergyReward : float
@export var SatietyReward : float
@export var SatisfactionReward : float
@export var RichnessReward : float

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

# Right now it's generic and cover all Actions
# but the idea is to inventually be able to customize the Rewards by Ads
# ie: Different food give more/less Satiety per second, bad job give less Richness, etc.
var ActualReward := [
	{
		"Action": "Sleep",
		"State": Globals.ACTION_STATE.Running,
		# If running, need is /sec, if not then it's given whole on state transition
		"Rewards": {Globals.NEEDS.Energy: 0.1}
	},
	{
		"Action": "Sleep",
		"State": Globals.ACTION_STATE.Finished,
		"Rewards": {Globals.NEEDS.Satisfaction: 0.1}
	},
	{
		"Action": "Eat",
		"State": Globals.ACTION_STATE.Running,
		"Rewards": {Globals.NEEDS.Satiety: 0.15} # Steak: 0.6 over 4 seconds
	},
	{
		"Action": "Eat",
		"State": Globals.ACTION_STATE.Finished,
		"Rewards": {Globals.NEEDS.Satisfaction: 0.05}
	},
	{
		"Action": "WalkRandomly",
		"State": Globals.ACTION_STATE.Finished,
		"Rewards": {Globals.NEEDS.Satisfaction: 0.04}
	},
	{
		"Action": "RefillFridge2",
		"State": Globals.ACTION_STATE.Finished,
		"Rewards": {Globals.NEEDS.Satisfaction: 0.06}
	},
	{
		"Action": "CookInKitchen2",
		"State": Globals.ACTION_STATE.Finished,
		"Rewards": {Globals.NEEDS.Satisfaction: 0.05}
	},
	{
		"Action": "Default",
		"State": Globals.ACTION_STATE.Running,
		"Rewards": {Globals.NEEDS.Satiety: -0.008, Globals.NEEDS.Energy: -0.006, Globals.NEEDS.Satisfaction: -0.005} # consider 1 day = 100 seconds, 0.01 means 1 to 0 in 100 seconds
	},
	{
		"Action": "SleepOnFloor",
		"State": Globals.ACTION_STATE.Finished,
		"Rewards": {Globals.NEEDS.Satisfaction: -0.2}
	},
	{
		"Action": "WorkAtBar",
		"State": Globals.ACTION_STATE.Finished,
		"Rewards": {Globals.NEEDS.Satisfaction: 0.4, Globals.NEEDS.Richness: 0.00015}
	}
]
