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

# Current thinking is plans picked up by NPCs are duplicated
# and we keep the current "execution state" of the plan in here
# Execution state could be stuff like how much left there is to cook
# If rewards were given, etc.
var PlanMetaData : Dictionary = {}
