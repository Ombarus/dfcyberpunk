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

# Current thinking is plans picked up by NPCs are duplicated
# and we keep the current "execution state" of the plan in here
# Execution state could be stuff like how much left there is to cook
# If rewards were given, etc.
var PlanMetaData : Dictionary = {}

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
		"Rewards": {Globals.NEEDS.Satiety: 0.068} # Steak: 0.35 over 6 seconds
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
		"Rewards": {Globals.NEEDS.Satiety: -0.01, Globals.NEEDS.Energy: -0.012, Globals.NEEDS.Satisfaction: -0.005} # consider 1 day = 100 seconds, 0.01 means 1 to 0 in 100 seconds
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
