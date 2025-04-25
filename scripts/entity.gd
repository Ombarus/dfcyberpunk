extends Advertisement
class_name Entity

#######################################
# NEED-BASED ACTION PLANS
######################################
# Current Implementation
# Each actions represent a Method of the same name (ie: action "Eat" has a method "Eat()")
# NPCs have a param dictionary that can contain any configuration necessary to perform actions (ie: where to go, how much to sleep, etc.)
# This is used to communicate between actions
# Actions are kept in an ordered "Stack" Array list of actions. Any Actions can push more actions
# Every frame, we call the action method in order from bottom of stack to top (top being the most recent action)
# If nothing changed, the action pushes the same stack and we do nothing special
# If the action pushes a different action from last frame, we discard everything else and move to the new action child
# If the action is considered "done" or "errored" we push nothing and return the state "Finished" or "ERROR" which will remove
# the action from the stack. All actions will eventually finish except "Default" which will always be pushed if nothing else is there.

# I'm in the process of feeding certain actions (called "ActionPlans") from items. Items can advertise certain action(s)
# With promised rewards (like Energy or Satiety) and the NPC (usually in the "Default" Action) can decide to "pick" that Plan to fulfil it's needs
# When an item become used (picked up, sit on, slept on, etc.) it's "Owner(BelongTo)" is set to the current NPC, preventing others from using the item
# The ActionPlan can then use the Items reward as params for the actions (like how much "Satiety" a food item is worth)

# There are still some uncertainties about how Items should advertise and how to "stick" to a given actionplan.
# Right now most items only have one "ActionPlan" and a set reward. But I would like to make them more dynamic in the future
# and a NPC who decide for example to eat Food A, should stick with the ActionPlan of that specific food unless for some reason
# that food becomes unavailable (rot, is picked up by someone, etc.)
# I'm not sure how to transition between an Action fed from an Item and an Action pushed by the NPC or another Action

# Pain Points:
# Passing Knowledge between actions is tricky. 
#    Though we probably want to make them independent where possible 
#    (ie: instead of waiting for a message: "I'm done" it's better for the action to "notice that the item is now in our inventory" for example)
#    * If unavoidable. My current idea is to use an intermediary. Store it in the Plan/Ad as Metadata. This way if someone else comes along, they
#      Can continue based on the data in the intermediary. This work well for stuff like preparing food where you would also have to "cleanup"
# Action don't know if child action is done or not
# Canceling action means we might stay in a weird state if parents didn't clean up properly
# How to express preferences? ie: NPC like to eat healthy so he should get a bonus to cooking healthy food...
#    but just from the needs/reward of the action plan we can't really tell


@export var MovePixSec : float = 100.0
@export var MoveEnerSec : float = 0.01
@export var EatUnitSec : float = 0.3334
@export var CookEnerSec : float = 0.01
@export var SleepEnerSec : float = 0.1
@export var SatSec : float = 0.01 # consider 1 day = 100 seconds, 0.01 means 1 to 0 in 100 seconds
@export var SatisSec : float = 0.01
@export var SleepJitter : float = 0.1 # Random variation in % (if bed give +0.9, this will add/remove 10% of 0.9)

var Needs := NeedHandler.new()

var curParam : Dictionary
var actionStack : Array
var lastAction : String

var debugThoughtsAction : Label
var debugThoughtsSatiety : ProgressBar
var debugThoughtsEnergy : ProgressBar
var debugThoughtsSatisfaction : ProgressBar
var debugPlanScore : VBoxContainer
var debugThoughts : Control

class ActionStep:
	var Name : String
	var State : Globals.ACTION_STATE
	var Metadata : Dictionary


func _ready() -> void:
	self.actionStack = []
	self.debugThoughtsEnergy = self.find_child("EnergyProgress", true, false) as ProgressBar
	self.debugThoughtsSatiety = self.find_child("SatietyProgress", true, false) as ProgressBar
	self.debugThoughtsSatisfaction = self.find_child("SatisfactionProgress", true, false) as ProgressBar
	self.debugThoughtsAction = self.find_child("Action", true, false) as Label
	self.debugPlanScore = self.find_child("PlanScore", true, false) as VBoxContainer
	self.debugThoughts = self.find_child("NPCThoughts", true, false) as Control

func _process(delta: float) -> void:
	if self.actionStack.size() == 0:
		self.pushAction("Default", -1)
	var i := 0
	# For loop was having issue with updating actionStack during loop
	while i < self.actionStack.size():
		var s = self.callv(self.actionStack[i], [delta, self.curParam, i])
		
		if (s == Globals.ACTION_STATE.Finished):
			self.popAction()
		i += 1
	
	UpdateThoughts()
	UpdateSatiety(delta)
	UpdateSatisfaction(delta)

func UpdateThoughts():
	self.debugThoughtsEnergy.value = Needs.Current(Globals.NEEDS.Energy)
	self.debugThoughtsSatiety.value = Needs.Current(Globals.NEEDS.Satiety)
	self.debugThoughtsSatisfaction.value = Needs.Current(Globals.NEEDS.Satisfaction)
	var actions = ""
	for a in actionStack:
		if actions != "":
			actions += "->"
		actions += a
	self.debugThoughtsAction.text = actions
	self.debugThoughts.position = get_viewport().get_camera_3d().unproject_position(self.position)

func UpdateSatiety(delta : float) -> void:
	Needs.ApplyNeedOverTime(Globals.NEEDS.Satiety, -self.SatSec, delta)
	
func UpdateSatisfaction(delta : float) -> void:
	Needs.ApplyNeedOverTime(Globals.NEEDS.Satisfaction, -self.SatisSec, delta)

###################################################################################################
## ACTION FUNCTION
###################################################################################################

func WalkRandomly(delta : float, param : Dictionary, actionDepth : int) -> int:
	var target = param.get("target", null)
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	if target == null:
		var nav := self.get_tree().root.find_child("NavigationRegion3D", true, false) as NavigationRegion3D
		var nav_map := nav.get_navigation_map()
		target = NavigationServer3D.map_get_random_point(nav_map, 1, true)
		param["target"] = target
		self.pushAction("Goto", actionDepth)
		return Globals.ACTION_STATE.Running
	
	if is_top_of_stack:
		param.erase("target")
		return Globals.ACTION_STATE.Finished
		
	self.pushAction("Goto", actionDepth)
	
	return Globals.ACTION_STATE.Running

func _physics_process(delta: float) -> void:
	# Terrible hack to "cast" player object to CharacterBody3D
	# Without having to make ALL Advertisement inherit from it
	if "velocity" in self:
		# Add the gravity.
		if not self.call("is_on_floor"):
			self.velocity += self.call("get_gravity") * delta
		self.call("move_and_slide")
		

func Goto(delta : float, param : Dictionary, actionDepth : int) -> int:
	# Maybe one day I can handle different type of movement. For now only accept
	# CharacterBody3D movement
	if not "velocity" in self:
		return Globals.ACTION_STATE.Finished

	var precision : float = param.get("precision", 1.0)
	var nav_agent := self.find_child("NavigationAgent3D", true, false) as NavigationAgent3D
	nav_agent.target_position = param["target"] as Vector3
	var next := nav_agent.get_next_path_position()
	
	var dir = (next - self.position).normalized()
	# For some reason it's REALLY hard to keep the capsule properly
	# aligned on the Y axis
	# So just hack it if we run into problems
	if abs(dir.y) > 0.8:
		self.position.y = next.y
	dir *= self.MovePixSec
	var look_at_vec : Vector3 = next
	look_at_vec.y = self.position.y
	self.look_at(look_at_vec, Vector3.UP)
	# I might have made a mistake aligning the models to Y- in Blender
	# Seems like it becomes z+ in Godot and look_at assume Z-?
	self.rotate_y(deg_to_rad(180.0))
	
	self.velocity = Vector3(dir.x, self.velocity.y, dir.z)
	var anim : AnimationPlayer = self.find_child("AnimationPlayer", true, false)
	
	if nav_agent.is_target_reached() or isAtLocation(nav_agent.target_position, precision):
		anim.play("Idle")
		self.velocity = Vector3.ZERO
		return Globals.ACTION_STATE.Finished
	
	anim.play("Walk")
	var energy : float = self.MoveEnerSec * delta
	Needs.ApplyNeed(Globals.NEEDS.Energy, -energy)
	return Globals.ACTION_STATE.Running
	

func Eat(delta : float, param : Dictionary, actionDepth : int) -> int:
	var ret_val = Globals.ACTION_STATE.Running
	var rewards : Dictionary = param.get("food", {})
	var food : Advertisement = param.get("plan_ad", null)

	var eat := self.EatUnitSec * delta
	if eat > rewards[Globals.NEEDS.Satiety]:
		eat = rewards[Globals.NEEDS.Satiety]
		ret_val = Globals.ACTION_STATE.Finished
		# Energy and Satisfaction only get applied once the whole meal is consumed?
		Needs.ApplyNeed(Globals.NEEDS.Satisfaction, rewards[Globals.NEEDS.Satisfaction])
		Needs.ApplyNeed(Globals.NEEDS.Energy, rewards[Globals.NEEDS.Energy])
		param.erase("food")
		param["plan_ad"] = null
		var inv : Array = param.get("inventory", [])
		inv.erase(food)
		food.queue_free()
		
	# Can you eat more than your fill? (maybe you get fat?)
	Needs.ApplyNeed(Globals.NEEDS.Satiety, eat)
	rewards[Globals.NEEDS.Satiety] -= eat
	
	return ret_val
	
func Cook(delta : float, param : Dictionary, actionDepth : int) -> int:
	# You cannot be interrupted while cooking?
	if not isTopOfStack(actionDepth):
		return Globals.ACTION_STATE.Running
		
	var cur_plan : ActionPlan = param["current_plan"]
	var cook_left := cur_plan.PlanMetaData["meal"] as float
	# Should eventually be able to handle positive OR negative values
	# For now, I know cooking should consume energy so it'll be negative
	cook_left = abs(cook_left)
	var inv : Array = param.get("inventory", [])
	var food_to_drop : Advertisement
	for i in inv:
		var ad = (i as Advertisement)
		if (i as Advertisement).Type == Globals.AD_TYPE.Food:
			food_to_drop = ad
			break
	
	if cook_left == 0:
		if food_to_drop != null:
			param["item"] = food_to_drop
			self.pushAction("Drop", actionDepth)
			return Globals.ACTION_STATE.Running
		else:
			var sati_reward : float = cur_plan.PlanMetaData.get("meal_sati", 0.0)
			Needs.ApplyNeed(Globals.NEEDS.Satisfaction, sati_reward)
			cur_plan.PlanMetaData["finished"] = true
			var foodstuff : Advertisement
			for i in inv:
				var ad = (i as Advertisement)
				if (i as Advertisement).Type == Globals.AD_TYPE.Foodstuff:
					foodstuff = ad
					break
			inv.erase(foodstuff)
			param["inventory"] = inv
			return Globals.ACTION_STATE.Finished
		
	var ener := self.CookEnerSec * delta
	if ener >= cook_left:
		ener = cook_left
		param["scene"] = cur_plan.SpawnReward
		self.pushAction("Spawn", actionDepth)
	Needs.ApplyNeed(Globals.NEEDS.Energy, -ener)
	# Can't be bottered to redo the logic so just flip the sign
	# (see comment above)
	cur_plan.PlanMetaData["meal"] = -(cook_left - ener)
	return Globals.ACTION_STATE.Running

class Sorter:
	var sort_key
	func _init(k):
		sort_key = k
		
	func sort_desc(a, b):
		if a[sort_key] > b[sort_key]:
			return true
		return false
		
func LoadWait(delta : float, param : Dictionary, actionDepth : int) -> int:
	var load_done : bool = param.get("load_done", false)
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	if load_done == true and is_top_of_stack:
		return Globals.ACTION_STATE.Finished
		
	if is_top_of_stack:
		param["wait"] = 1.0
		param["load_done"] = true
		
	self.pushAction("Wait", actionDepth)
	
	return Globals.ACTION_STATE.Running

func Default(delta : float, param : Dictionary, actionDepth : int) -> int:
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	# For now, don't interrupt running actions
	# But what if we decide to go to sleep before finishing cooking?
	if not is_top_of_stack:
		return Globals.ACTION_STATE.Running
		
	var random_goto_plan := ActionPlan.new()
	random_goto_plan.ActionName = "WalkRandomly"
	random_goto_plan.EnergyReward = 0.0
	random_goto_plan.SatietyReward = 0.0
	random_goto_plan.SatisfactionReward = 0.08 # Slightly higher than making food when we have a lot of food
	
	var fallback_sleep_plan := ActionPlan.new()
	fallback_sleep_plan.ActionName = "SleepOnFloor"
	fallback_sleep_plan.EnergyReward = 0.01
	random_goto_plan.SatietyReward = 0.0
	fallback_sleep_plan.SatisfactionReward = -0.2
	
	var wait_plan := ActionPlan.new()
	wait_plan.ActionName = "LoadWait"
	wait_plan.EnergyReward = 0.0
	wait_plan.SatietyReward = 0.0
	wait_plan.SatisfactionReward = 0.1
		
	
	# Something like : [{name:"plan1", ad:<node>, score:123}, ...]
	var collected_plans := []
	# "Default" Plans when nothing better to do
	if param.get("load_done", false) == false:
		collected_plans.append({
			"plan": wait_plan,
			"ad": self,
			"score": Needs.GetRewardScoreFromPlan(random_goto_plan)
		})
	else:
		collected_plans.append({
			"plan": random_goto_plan,
			"ad": self,
			"score": Needs.GetRewardScoreFromPlan(random_goto_plan)
		})
		collected_plans.append({
			"plan": fallback_sleep_plan,
			"ad": self,
			"score": Needs.GetRewardScoreFromPlan(fallback_sleep_plan)
		})
		
		for n in get_tree().get_nodes_in_group(Globals.AD_GROUP):
			var ad := n as Advertisement
			# Only null (belong to no one) or belonging to me
			if ad.BelongTo != null and ad.BelongTo != self:
				continue
			var plans : Array = ad.GetActionPlansFor(self)
			for i in plans:
				var data = {
					"plan": i,
					"ad": ad,
					"score": Needs.GetRewardScoreFromPlan(i as ActionPlan)
				}
				collected_plans.append(data)
				
	var sorter := Sorter.new("score")
	collected_plans.sort_custom(Callable(sorter, "sort_desc"))
	
	UpdatePlanScoreDebug(collected_plans)
	
	var best_action : Dictionary = {}
	# Skip actions that would put the NPC at more than 100% of their need
	# This is because otherwise sleeping would always be at the top because of
	# How much energy it gives, even with the scale-down factor for already satisfied needs
	# TODO: It'd be nice to integrate this steep score cutoff directly in the score calculation but I'm not sure how
	for data in collected_plans:
		best_action = data
		var cur_plan := data["plan"] as ActionPlan
		var planed_sat : float = cur_plan.SatietyReward + Needs.Current(Globals.NEEDS.Satiety)
		var planed_sati : float = cur_plan.SatisfactionReward + Needs.Current(Globals.NEEDS.Satisfaction) 
		var planed_ener : float = cur_plan.EnergyReward + Needs.Current(Globals.NEEDS.Energy)
		
		if planed_sat < 1.0 and planed_sati < 1.0 and planed_ener < 1.0:
			break
	
	# duplicate so we can modify properties in a unique way
	# NOTE: might not always be the case, for example maybe a car would only ever have one active plan and the
	#       state from the previous action would influence the current plan
	# For now, all plans a duplicated
	param["current_plan"] = best_action["plan"].duplicate()
	param["plan_ad"] = best_action["ad"]
	self.pushAction(best_action["plan"].ActionName, actionDepth)

	return Globals.ACTION_STATE.Running
	
func UpdatePlanScoreDebug(collected_plans):
	for c in self.debugPlanScore.get_children():
		if c.name != "Title":
			c.queue_free()
	var greened := false
	for p in collected_plans:
		var l : RichTextLabel = RichTextLabel.new()
		l.bbcode_enabled = true
		var color := "[color=white]"
		var cur_plan := p["plan"] as ActionPlan
		var planed_sat : float = cur_plan.SatietyReward + Needs.Current(Globals.NEEDS.Satiety)
		var planed_sati : float = cur_plan.SatisfactionReward + Needs.Current(Globals.NEEDS.Satisfaction) 
		var planed_ener : float = cur_plan.EnergyReward + Needs.Current(Globals.NEEDS.Energy)
		if planed_sat < 1.0 and planed_sati < 1.0 and planed_ener < 1.0:
			if greened == false:
				color = "[color=green]"
				greened = true
		else:
			color = "[color=red]"
		l.text = color + p["plan"].ActionName + ": " + str(p["score"]) + "[/color]"
		l.custom_minimum_size = Vector2(250, 20)
		self.debugPlanScore.add_child(l)
	
func EatSelectedFood(delta : float, param : Dictionary, actionDepth : int) -> int:
	var plan : ActionPlan = param.get("current_plan", null)
	var food : Advertisement = param.get("plan_ad", null)
	var left = param.get("food", null)
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	
	if plan == null or food == null:
		return Globals.ACTION_STATE.Finished
	
	var inv : Array = param.get("inventory", [])
	var in_inventory := false
	for i in inv:
		if i == food:
			in_inventory = true
			break
	
	if in_inventory == true:
		if is_top_of_stack:
			var rewards := {
				Globals.NEEDS.Satiety: plan.SatietyReward,
				Globals.NEEDS.Energy: plan.EnergyReward,
				Globals.NEEDS.Satisfaction: plan.SatisfactionReward
			}
			param["food"] = rewards
		self.pushAction("Eat", actionDepth)
		return Globals.ACTION_STATE.Running
	
	if self.position != food.position:
		param["target"] = food.position
		self.pushAction("Goto", actionDepth)
	else:
		param["item"] = food
		self.pushAction("Pickup", actionDepth)

	return Globals.ACTION_STATE.Running

func CookInKitchen(delta : float, param : Dictionary, actionDepth : int) -> int:
	var kitchen : Advertisement = self.getFirstOf(Globals.AD_TYPE.Kitchen)
	var cur_plan : ActionPlan = param["current_plan"]
	var fridge : Advertisement = param.get("plan_ad", null)
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	
	var left_progress : bool = cur_plan.PlanMetaData.get("finished", false)
	if left_progress == true:
		return Globals.ACTION_STATE.Finished
		
	var inv : Array = param.get("inventory", [])
	var foodstuff : Advertisement
	for i in inv:
		var ad = (i as Advertisement)
		if (i as Advertisement).Type == Globals.AD_TYPE.Foodstuff:
			foodstuff = ad
			break
	
	if foodstuff == null and self.position != fridge.position:
		param["target"] = fridge.position
		self.pushAction("Goto", actionDepth)
	elif foodstuff == null and self.position == fridge.position:
		param["item_type"] = Globals.AD_TYPE.Foodstuff
		param["giver"] = fridge
		self.pushAction("Receive", actionDepth)		
	elif foodstuff != null and self.position != kitchen.position:
		param["target"] = kitchen.position
		self.pushAction("Goto", actionDepth)
	elif foodstuff != null and self.position == kitchen.position:
		if is_top_of_stack:
			cur_plan.PlanMetaData["meal"] = cur_plan.EnergyReward
			cur_plan.PlanMetaData["meal_sati"] = cur_plan.SatisfactionReward
		self.pushAction("Cook", actionDepth)
	return Globals.ACTION_STATE.Running
	
func Receive(delta : float, param : Dictionary, actionDepth : int) -> int:
	var item_type : Globals.AD_TYPE = param["item_type"]
	var giver : Advertisement = param["giver"]
	var receiver_inv : Array = param.get("inventory", [])
	var giver_inv : Array = giver.AdMetaData.get("inventory", [])
	
	for item in giver_inv:
		var ad : Advertisement = item as Advertisement
		if ad.Type == item_type:
			receiver_inv.push_back(ad)
			giver_inv.erase(ad)
			param["inventory"] = receiver_inv
			giver.AdMetaData["inventory"] = giver_inv
			break
		
	return Globals.ACTION_STATE.Finished

func Spawn(delta : float, param : Dictionary, actionDepth : int) -> int:
	var pos : Vector3 = self.position
	var pack := param["scene"] as PackedScene
	var n := pack.instantiate() as Advertisement
	self.get_parent().add_child(n)
	n.position = pos
	n.BelongTo = self
	n.visible = false
	var inv : Array = param.get("inventory", [])
	inv.append(n)
	param["inventory"] = inv
	return Globals.ACTION_STATE.Finished

func Pickup(delta : float, param : Dictionary, actionDepth : int) -> int:
	var item : Node2D = param["item"] as Node2D
	param.erase("item")
	var inv : Array = param.get("inventory", [])
	inv.push_back(item)
	param["inventory"] = inv
	#item.queue_free()
	item.visible = false
	item.BelongTo = self
	return Globals.ACTION_STATE.Finished
	
func Drop(delta : float, param : Dictionary, actionDepth : int) -> int:
	var inv : Array = param.get("inventory", [])
	var item : Advertisement = param["item"] as Advertisement
	param.erase("item")
	inv.erase(item)
	item.visible = true
	item.BelongTo = null
	var pos := self.position + Vector3(randi_range(-50.0, 50.0), self.position.y, randi_range(-50.0, 50.0))
	item.position = pos
	return Globals.ACTION_STATE.Finished
	
func Wait(delta : float, param : Dictionary, actionDepth: int) -> int:
	var wait_left : float = param["wait"]
	wait_left -= delta
	if wait_left <= 0.0:
		return Globals.ACTION_STATE.Finished
	param["wait"] = wait_left
	var anim : AnimationPlayer = self.find_child("AnimationPlayer", true, false)
	if anim != null:
		anim.play("Idle")
	return Globals.ACTION_STATE.Running
	
func SleepOnFloor(delta : float, param : Dictionary, actionDepth : int) -> int:
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	if Needs.GetNeed(Globals.NEEDS.Energy) > 0.5 and is_top_of_stack:
		return Globals.ACTION_STATE.Finished
	else:
		if is_top_of_stack:
			param["wake"] = randf_range(0.5, 0.8)
		self.pushAction("Sleep", actionDepth)
	return Globals.ACTION_STATE.Running
	
func SleepInBed(delta : float, param : Dictionary, actionDepth : int) -> int:
	var plan : ActionPlan = param.get("current_plan", null)
	var bed : Advertisement = param.get("plan_ad", null)
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	var next_action := getCurAction(actionDepth+1) # return "" if top_of_stack

	if bed == null:
		return Globals.ACTION_STATE.Error
	
	var playing_anim : String = getPlayingAnim(param)
	
	if (playing_anim != "Idle" and Needs.GetNeed(Globals.NEEDS.Energy) > 0.8 and is_top_of_stack) or (next_action == "WakeUpFromBed"):
		self.pushAction("WakeUpFromBed", actionDepth)
		return Globals.ACTION_STATE.Running
	elif Needs.GetNeed(Globals.NEEDS.Energy) > 0.8 and is_top_of_stack:
		bed.BelongTo = null
		return Globals.ACTION_STATE.Finished
	
	var dist_to_bed : float = (self.position - bed.position).length()
	if not isAtLocation(bed.position, 0.5):
		param["target"] = bed.position
		param["precision"] = 0.5
		self.pushAction("Goto", actionDepth)
		return Globals.ACTION_STATE.Running
	else:
		self.velocity = Vector3.ZERO
		
	if playing_anim != "SleepBedIdle":
		bed.BelongTo = self
		self.pushAction("FallAsleepInBed", actionDepth)
		return Globals.ACTION_STATE.Running

	if is_top_of_stack:
		var base_sleep = plan.EnergyReward
		var jitter = randf_range(-self.SleepJitter, self.SleepJitter)
		var wake = clamp(Needs.GetNeed(Globals.NEEDS.Energy) + base_sleep + jitter, 0.0, 1.0)
		param["wake"] = wake
	self.pushAction("Sleep", actionDepth)
	return Globals.ACTION_STATE.Running
	
func FallAsleepInBed(delta : float, param : Dictionary, actionDepth : int) -> int:
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	var bed : Advertisement = param.get("plan_ad", null)
	if is_top_of_stack:
		if getPlayingAnim(param) == "SleepBed":
			var anim : AnimationPlayer = self.find_child("AnimationPlayer", true, false)
			anim.play("SleepBedIdle")
			param["last_anim"] = "SleepBedIdle"
			return Globals.ACTION_STATE.Finished
		param["anim"] = "SleepBed"
		param["anim_backward"] = true
		param["anim_transform"] = bed.global_transform
	self.pushAction("PlayAnim", actionDepth)
	return Globals.ACTION_STATE.Running
	
func WakeUpFromBed(delta : float, param : Dictionary, actionDepth : int) -> int:
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	var bed : Advertisement = param.get("plan_ad", null)
	if is_top_of_stack:
		if getPlayingAnim(param) == "SleepBed":
			var anim : AnimationPlayer = self.find_child("AnimationPlayer", true, false)
			anim.play("Idle")
			return Globals.ACTION_STATE.Finished
		param["anim"] = "SleepBed"
		param["anim_backward"] = false
		param["anim_transform"] = bed.global_transform
	self.pushAction("PlayAnim", actionDepth)
	return Globals.ACTION_STATE.Running
	
func PlayAnim(delta : float, param : Dictionary, actionDepth : int) -> int:
	var anim_name : String = param.get("anim", "")
	var play_backward : bool = param.get("anim_backward", false)
	
	var anim : AnimationPlayer = self.find_child("AnimationPlayer", true, false)
	if not anim_name.is_empty() and anim != null and anim.current_animation != anim_name:
		param.erase("anim")
		param["last_anim"] = anim_name
		if play_backward:
			anim.play_backwards(anim_name)
		else:
			anim.play(anim_name)
		
	var anim_length : float = anim.current_animation_length
	var anim_time : float = anim.current_animation_position
	if play_backward:
		anim_time = anim_time * -1.0 + anim_length
	
	if "anim_transform" in param:
		var anim_transform : Transform3D = param["anim_transform"]
		var npc_transform : Transform3D = self.global_transform
		var anim_left : float = anim_length - anim_time
		if anim_left < delta:
			self.global_transform = anim_transform
		else:
			var interpolated : Transform3D = anim_transform.interpolate_with(npc_transform, delta / anim_left)
			self.global_transform = interpolated
		
	# in non-looping anim, current_animation is empty when done
	if anim_length == anim_time or anim.current_animation.is_empty():
		param.erase("anim_backward")
		param.erase("anim_transform")
		return Globals.ACTION_STATE.Finished

	return Globals.ACTION_STATE.Running
	
func Sleep(delta : float, param : Dictionary, actionDepth : int) -> int:
	var ret_val := Globals.ACTION_STATE.Running
	var recover := self.SleepEnerSec * delta
	var wake_ener : float = param["wake"] as float
	if Needs.GetNeed(Globals.NEEDS.Energy) + recover > wake_ener:
		Needs.SetNeed(Globals.NEEDS.Energy, wake_ener)
		return Globals.ACTION_STATE.Finished
	Needs.ApplyNeed(Globals.NEEDS.Energy, recover)
	return ret_val
	
func WorkInOffice(delta : float, param : Dictionary, actionDepth : int) -> int:
	var plan : ActionPlan = param.get("current_plan", null)
	var office : Advertisement = param.get("plan_ad", null)
	if self.position != office.position:
		param["target"] = office.position
		self.pushAction("Goto", actionDepth)
		return Globals.ACTION_STATE.Running
	elif plan.PlanMetaData.get("finished", false) == true:
		return Globals.ACTION_STATE.Finished
	else:
		self.pushAction("Work", actionDepth)
	return Globals.ACTION_STATE.Running
	
func Work(delta : float, param : Dictionary, actionDepth : int) -> int:
	var world_clock : WorldTime = %WorldTime
	var normal_work_day_ticks : float = world_clock.GameHoursToGameTick(2.0)
	var plan : ActionPlan = param.get("current_plan", null)
	var work_time_left : float = plan.PlanMetaData.get("work_time", normal_work_day_ticks)
	var work_time_delta = world_clock.RealSecondToGameTick(delta)
	if work_time_left < work_time_delta:
		work_time_delta = work_time_left
	work_time_left -= work_time_delta
	plan.PlanMetaData["work_time"] = work_time_left
	
	var energy_loss : float = plan.EnergyReward / normal_work_day_ticks * work_time_delta
	Needs.ApplyNeed(Globals.NEEDS.Energy, energy_loss)
	
	if work_time_left <= 0.0:
		Needs.ApplyNeed(Globals.NEEDS.Satisfaction, plan.SatisfactionReward)
		plan.PlanMetaData["finished"] = true
		return Globals.ACTION_STATE.Finished
	
	return Globals.ACTION_STATE.Running
	
func RefillFridge(delta : float, param : Dictionary, actionDepth : int) -> int:
	var plan : ActionPlan = param.get("current_plan", null)
	var fridge : Advertisement = param.get("plan_ad", null)
	var market : Advertisement = getFirstOf(Globals.AD_TYPE.Market)
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	
	var inv : Array = param.get("inventory", [])
	var foodstuff : Advertisement
	for i in inv:
		var ad = (i as Advertisement)
		if (i as Advertisement).Type == Globals.AD_TYPE.Foodstuff:
			foodstuff = ad
			break
			
	if foodstuff == null and not isAtLocation(fridge.position, 2.0):
		self.pushAction("GoBuyFoodstuff", actionDepth)
		return Globals.ACTION_STATE.Running
		
	if foodstuff != null and is_top_of_stack:
		self.pushAction("GoDropFoodInFridge", actionDepth)
		return Globals.ACTION_STATE.Running
		
	if foodstuff == null and isAtLocation(fridge.position, 2.0) and is_top_of_stack:
		return Globals.ACTION_STATE.Finished
	
	return Globals.ACTION_STATE.Running
	
func GoDropFoodInFridge(delta : float, param : Dictionary, actionDepth : int) -> int:
	var fridge : Advertisement = param.get("plan_ad", null)
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	var inv : Array = param.get("inventory", [])
	var foodstuff : Advertisement
	for i in inv:
		var ad = (i as Advertisement)
		if ad.Type == Globals.AD_TYPE.Foodstuff:
			foodstuff = ad
			break
		
	if not is_top_of_stack:
		return Globals.ACTION_STATE.Running
			
	if not isAtLocation(fridge.position, 1.5):
		param["target"] = fridge.position
		param["precision"] = 1.5
		self.pushAction("Goto", actionDepth)
		return Globals.ACTION_STATE.Running
		
	if isAtLocation(fridge.position, 2.0):
		var cur_anim = animState(fridge)
		if cur_anim != "OpenIdle" and foodstuff != null:
			param["obj"] = fridge
			param["start"] = "FridgeOpen"
			param["end"] = "OpenIdle"
			self.pushAction("TravelObjAnim", actionDepth)
			return Globals.ACTION_STATE.Running

		if foodstuff != null:
			param["item"] = foodstuff
			param["receiver"] = fridge
			self.pushAction("Give", actionDepth)
			return Globals.ACTION_STATE.Running
			
		if cur_anim != "CloseIdle":
			param["obj"] = fridge
			param["start"] = "FridgeClose"
			param["end"] = "CloseIdle"
			self.pushAction("TravelObjAnim", actionDepth)
			return Globals.ACTION_STATE.Running
			
	return Globals.ACTION_STATE.Finished
	
func TravelObjAnim(delta : float, param : Dictionary, actionDepth : int) -> int:
	var obj : Node3D = param["obj"]
	var start_state : String = param["start"]
	var end_state : String = param["end"]
	var obj_tree : AnimationTree = obj.find_child("AnimationTree", true, false)
	var obj_state : AnimationNodeStateMachinePlayback = obj_tree.get("parameters/playback")
	
	if obj_state.get_current_node() != start_state and obj_state.get_current_node() != end_state:
		obj_state.travel(start_state)
		
	if obj_state.get_current_node() == end_state:
		param.erase("start")
		param.erase("end")
		param.erase("anim")
		return Globals.ACTION_STATE.Finished
	
	return Globals.ACTION_STATE.Running
	
func GoBuyFoodstuff(delta : float, param : Dictionary, actionDepth : int) -> int:
	var plan : ActionPlan = param.get("current_plan", null)
	var market : Advertisement = getFirstOf(Globals.AD_TYPE.Market)
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	var target = param.get("target", null)
	
	if target == null and is_top_of_stack:
		param["target"] = market.position
		
	if not isAtLocation(market.position):
		self.pushAction("Goto", actionDepth)
		return Globals.ACTION_STATE.Running
	
	var inv : Array = param.get("inventory", [])
	var foodstuff : Advertisement
	for i in inv:
		var ad = (i as Advertisement)
		if ad.Type == Globals.AD_TYPE.Foodstuff:
			foodstuff = ad
			break
			
	if foodstuff == null:
		param["scene"] = plan.SpawnReward
		self.pushAction("Spawn", actionDepth)
		return Globals.ACTION_STATE.Running
	
	if foodstuff != null and is_top_of_stack:
		param.erase("target")
		param.erase("scene")
		return Globals.ACTION_STATE.Finished
		
	return Globals.ACTION_STATE.Running
	
func Give(delta : float, param : Dictionary, actionDepth : int) -> int:
	var item : Advertisement = param["item"]
	var receiver : Advertisement = param["receiver"]
	
	var inv : Array = param.get("inventory", [])
	inv.erase(item)
	receiver.AdMetaData["inventory"].push_back(item)
	param["inventory"] = inv
		
	return Globals.ACTION_STATE.Finished
	
###################################################################################################
## UTILITY FUNCTION
###################################################################################################

func pushAction(action : String, afterIndex : int) -> void:
	var at_index = afterIndex + 1
	# At the end of the list, simply add the action
	if at_index == self.actionStack.size():
		print("Entity %s Pushed %s" % [self.name, action])
		self.actionStack.push_back(action)
		return
		
	# Trying to add the same action serves as confirmation to keep going
	if self.actionStack[at_index] == action:
		return
		
	# Trying to add a new action means a parent action got cancelled and we should
	# flush the current action Stack
	print("Entity %s Inserted %s at %d" % [self.name, action, at_index])
	self.actionStack = self.actionStack.slice(0, at_index)
	self.actionStack.push_back(action)
	
func popAction() -> void:
	var last_action = self.actionStack[-1]
	print("Entity %s Poped %s" % [self.name, last_action])
	self.lastAction = last_action
	self.actionStack.remove_at(len(self.actionStack)-1)
	
func getCurAction(depth=-1) -> String:
	if len(self.actionStack) <= 0:
		return "Default"
	if depth >= len(self.actionStack):
		return ""
	return self.actionStack[depth]
	
func lastActionIndex() -> int:
	return self.actionStack.size() - 1
	
func isTopOfStack(actionDepth : int) -> bool:
	return not actionDepth < lastActionIndex()

func getFirstOf(t : Globals.AD_TYPE) -> Advertisement:
	var nodes : Array = get_tree().get_nodes_in_group(str(t))
	for n in nodes:
		n = n as Advertisement
		if n and n.BelongTo == null or n.BelongTo == self:
			return n
	return null
	
func getPlayingAnim(param : Dictionary) -> String:
	var anim : AnimationPlayer = self.find_child("AnimationPlayer", true, false)
	if anim != null and not anim.current_animation.is_empty():
		return anim.current_animation
		
	return param.get("last_anim", "")

func isAtLocation(loc : Vector3, min_dist : float = 1.0) -> bool:
	var p : Vector3 = self.position
	loc.y = 0
	p.y = 0
	if p.distance_squared_to(loc) <= (min_dist * min_dist):
		return true
	return false
	
func isAnimPlaying(obj : Node3D) -> bool:
	var obj_tree : AnimationTree = obj.find_child("AnimationTree", true, false)
	var obj_state : AnimationNodeStateMachinePlayback = obj_tree.get("parameters/playback")
	return obj_state.is_playing()
	
func animState(obj : Node3D) -> String:
	var obj_tree : AnimationTree = obj.find_child("AnimationTree", true, false)
	var obj_state : AnimationNodeStateMachinePlayback = obj_tree.get("parameters/playback")
	var cur_anim = obj_state.get_current_node()
	return cur_anim
	
