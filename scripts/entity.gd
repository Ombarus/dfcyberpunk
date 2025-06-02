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

# Actions To Review
#GoGetItemFromGeneric
#WalkRandomly
#Goto
#LoadWait
#Default
#EatSelectedFood
#CookInKitchen2
#GoPutOnCounter
#GoGetFromFridge
#Receive
#Spawn
#Pickup
#Drop
#Wait
#SleepInBed
#FallAsleepInBed
#WakeUpFromBed
#PlayAnim
#Sleep
#RefillFridge
#PutFoodInFridge
#GoDropFoodInFridge
#GoBuyFoodstuff
#Give
#TravelObjAnim
#
#*Eat
#*Cook
#*SleepOnFloor
#*WorkInOffice
#*Work


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
			self.popAction(i)
		i += 1
	
	UpdateThoughts()
	UpdateSatiety(delta)
	UpdateSatisfaction(delta)

func _physics_process(delta: float) -> void:
	# Terrible hack to "cast" player object to CharacterBody3D
	# Without having to make ALL Advertisement inherit from it
	if "velocity" in self:
		# Add the gravity.
		if not self.call("is_on_floor"):
			self.velocity += self.call("get_gravity") * delta
		self.call("move_and_slide")

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

###################################################################################################
## ACTION FUNCTION
###################################################################################################

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

func GoGetItem(delta : float, param : Dictionary, actionDepth : int) -> int:
	# Item might be in container
	#  Go to container, transfer from container to inv. If fridge play more complex anim
	# Item is on the floor
	#  Go to item pos, interact anim, transfer to inv
	var item : Advertisement = param["item"]
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	var inv : Array = param.get("inventory", [])
	
	var target_pos : Vector3 = item.position
	var container : Advertisement = self.getContainer(item)
	var precision := 0.5
	if container != null:
		target_pos = container.position
		precision = 1.5
		
	if not isAtLocation(target_pos, precision):
		param["target"] = target_pos
		param["precision"] = precision
		self.pushAction("Goto", actionDepth)
		return Globals.ACTION_STATE.Running
		
	if self.isItemInInv(inv, item) and is_top_of_stack:
		return Globals.ACTION_STATE.Finished
	
	#TODO: handle NOT container case (just pickup)
	param["item"] = item
	param["from"] = container
	param["to"] = self
	self.pushAction("Transfer", actionDepth)
		
	return Globals.ACTION_STATE.Running
	
func GoDropItem(delta : float, param : Dictionary, actionDepth : int) -> int:
	# Drop in Container or Floor
	# If container
	#  Go to container, transfer from inv to container. if fridge, play more complex anim
	# If no container
	#  Drop on floor at cur position
	var item : Advertisement = param["item"]
	var container : Advertisement = param.get("container", null)
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	var inv : Array = param.get("inventory", [])
	
	var target_pos = self.position
	var precision := 0.0
	if container != null:
		target_pos = container.position
		precision = 1.5
		
	if not isAtLocation(target_pos, precision):
		param["target"] = target_pos
		param["precision"] = precision
		self.pushAction("Goto", actionDepth)
		return Globals.ACTION_STATE.Running
		
	if not self.isItemInInv(inv, item) and is_top_of_stack:
		return Globals.ACTION_STATE.Finished
		
	#TODO: handle NOT container case (just drop)
	param["item"] = item
	param["from"] = self
	param["to"] = container
	self.pushAction("Transfer", actionDepth)
	
	return Globals.ACTION_STATE.Running
	
func Transfer(delta : float, param : Dictionary, actionDepth : int) -> int:
	var item : Advertisement = param["item"]
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	var from : Advertisement = param["from"]
	var to : Advertisement = param["to"]
	var seq : Sequencer = get_node("Sequencer")
	
	var from_inv : Array
	if from == self:
		from_inv = param.get("inventory", [])
	else:
		from_inv = from.AdMetaData.get("inventory", [])
	
	var to_inv : Array
	if to == self:
		to_inv = param.get("inventory", [])
	else:
		to_inv = from.AdMetaData.get("inventory", [])
		
	if self.isItemInInv(from_inv, item) or not is_top_of_stack or seq.CurState() != seq.SEQ_STATE.IDLE:
		var fridge : Advertisement = null
		if to.Type == Globals.AD_TYPE.Fridge:
			fridge = to
		elif from.Type == Globals.AD_TYPE.Fridge:
			fridge = from
		# Special Sequence of anim for fridge door open/close
		if fridge != null:
			if not is_top_of_stack:
				seq.SetContinue()
				return Globals.ACTION_STATE.Running
			if seq.CurState() == seq.SEQ_STATE.IDLE:
				seq.FridgeSequence(fridge)
				return Globals.ACTION_STATE.Running
			elif seq.CurState() == seq.SEQ_STATE.FINISHED:
				seq.Reset()
				return Globals.ACTION_STATE.Finished
			else:
				var cur_anim = self.animState(fridge)
				if cur_anim == "OpenIdle" and self.isItemInInv(from_inv, item):
					toFromExchange(to, from, item, param)
				seq.SetContinue()
				return Globals.ACTION_STATE.Running
		else:
			#TODO: handle displaying in "inventoryXX" slots
			self.travelAnimOneShot(self, "Interact")
			toFromExchange(to, from, item, param)
		
		return Globals.ACTION_STATE.Running
	
	return Globals.ACTION_STATE.Finished

# This could be much simpler if Entity used AdMetaData
func toFromExchange(to : Advertisement, from : Advertisement, item : Advertisement, param : Dictionary):
	var from_inv : Array
	
	if from == self:
		from_inv = param.get("inventory", [])
	else:
		from_inv = from.AdMetaData.get("inventory", [])
	
	var to_inv : Array
	if to == self:
		to_inv = param.get("inventory", [])
	else:
		to_inv = from.AdMetaData.get("inventory", [])
		
	var inv_slot : Node3D = to.find_child("Inventory01", true, false)
		
	from_inv.erase(item)
	to_inv.push_back(item)
	item.AdMetaData["container"] = to
	if inv_slot != null:
		item.visible = true
		item.global_transform = inv_slot.global_transform
		
	if from == self:
		param["inventory"] = from_inv
	else:
		from.AdMetaData["inventory"] = from_inv
		
	if to == self:
		item.BelongTo = self
		param["inventory"] = to_inv # in case inventory wasn't init before
	else:
		item.BelongTo = null
		to.AdMetaData["inventory"] = to_inv
	
func TravelAnimState(delta : float, param : Dictionary, actionDepth : int) -> int:
	var obj : Node3D = param["obj"]
	var end_state : String = param["state"]
	var obj_tree : AnimationTree = obj.find_child("AnimationTree", true, false)
	var obj_state : AnimationNodeStateMachinePlayback = obj_tree.get("parameters/playback")
	
	if obj_state.get_current_node() != end_state:
		obj_state.travel(end_state)
		
	if "anim_transform" in param:
		var anim_transform : Transform3D = param["anim_transform"]
		var interpolate_time : float = param.get("interpolate_time", 0.0)
		var npc_transform : Transform3D = self.global_transform
		if interpolate_time < delta:
			param.erase("anim_transform")
			param.erase("interpolate_time")
			self.global_transform = anim_transform
		else:
			var interpolated : Transform3D = anim_transform.interpolate_with(npc_transform, delta / interpolate_time)
			param["interpolate_time"] = interpolate_time - delta
			self.global_transform = interpolated
		
	if obj_state.get_current_node() == end_state:
		param.erase("state")
		return Globals.ACTION_STATE.Finished
	
	return Globals.ACTION_STATE.Running

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

func Goto(delta : float, param : Dictionary, actionDepth : int) -> int:
	# Maybe one day I can handle different type of movement. For now only accept
	# CharacterBody3D movement
	if not "velocity" in self:
		return Globals.ACTION_STATE.Finished

	var precision : float = param.get("precision", 1.0)
	var nav_agent := self.find_child("NavigationAgent3D", true, false) as NavigationAgent3D
	nav_agent.target_position = param["target"] as Vector3
	var next := nav_agent.get_next_path_position()
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	
	var dir = (next - self.position).normalized()
	# For some reason it's REALLY hard to keep the capsule properly
	# aligned on the Y axis
	# So just hack it if we run into problems
	if abs(dir.y) > 0.8:
		self.position.y = next.y
	dir *= self.MovePixSec
	var look_at_vec : Vector3 = next
	look_at_vec.y = self.position.y
	var anim : AnimationPlayer = self.find_child("AnimationPlayer", true, false)
	
	if nav_agent.is_target_reached() or isAtLocation(nav_agent.target_position, precision):
		if is_top_of_stack:
			param["obj"] = self
			param["state"] = "Idle"
		self.pushAction("TravelAnimState", actionDepth)
		self.position = nav_agent.target_position
		self.velocity = Vector3.ZERO
		if self.animState(self) == "Idle" and is_top_of_stack:
			return Globals.ACTION_STATE.Finished
		else:
			return Globals.ACTION_STATE.Running
	
	if self.animState(self) != "Walk" and is_top_of_stack:
		param["obj"] = self
		param["state"] = "Walk"
		self.pushAction("TravelAnimState", actionDepth)
	
	# With state machine it might take time before we're in the "Walk" state
	# So wait until we've reached "walk" state before setting velocity and rotation
	if self.animState(self) == "Walk":
		self.look_at(look_at_vec, Vector3.UP)
		# I might have made a mistake aligning the models to Y- in Blender
		# Seems like it becomes z+ in Godot and look_at assume Z-?
		self.rotate_y(deg_to_rad(180.0))
		self.velocity = Vector3(dir.x, self.velocity.y, dir.z)
	var energy : float = self.MoveEnerSec * delta
	Needs.ApplyNeed(Globals.NEEDS.Energy, -energy)
	return Globals.ACTION_STATE.Running

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
	
func Wait(delta : float, param : Dictionary, actionDepth: int) -> int:
	var wait_left : float = param["wait"]
	wait_left -= delta
	if wait_left <= 0.0:
		return Globals.ACTION_STATE.Finished
	param["wait"] = wait_left
	return Globals.ACTION_STATE.Running
	
func GoSleepInBed(delta : float, param : Dictionary, actionDepth : int) -> int:
	var plan : ActionPlan = param.get("current_plan", null)
	var bed : Advertisement = param.get("plan_ad", null)
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	var energy : float = Needs.GetNeed(Globals.NEEDS.Energy)
	#var next_action := getCurAction(actionDepth+1) # return "" if top_of_stack

	if bed == null:
		return Globals.ACTION_STATE.Error
		
	if not is_top_of_stack:
		return Globals.ACTION_STATE.Running
		
	if not self.isAtLocation(bed.position, 0.5):
		param["target"] = bed.position
		param["precision"] = 0.5
		self.pushAction("Goto", actionDepth)
		return Globals.ACTION_STATE.Running
	
	bed.BelongTo = self
	var cur_state : String = self.animState(self)
	if cur_state != "SleepBedIdle" and energy < 0.5: # 0.5 is arbitrary: just "we're tired"
		param["obj"] = self
		param["state"] = "SleepBedIdle"
		param["anim_transform"] = bed.global_transform
		param["interpolate_time"] = 1.0
		self.pushAction("TravelAnimState", actionDepth)
		return Globals.ACTION_STATE.Running
		
	if cur_state == "SleepBedIdle" and energy < 0.5: # 0.5 is arbitrary: just "we're tired"
		var base_sleep = plan.EnergyReward
		var jitter = randf_range(-self.SleepJitter, self.SleepJitter)
		var wake = clamp(Needs.GetNeed(Globals.NEEDS.Energy) + base_sleep + jitter, 0.0, 1.0)
		param["wake"] = wake
		self.pushAction("Sleep", actionDepth)
		return Globals.ACTION_STATE.Running
		
	if cur_state == "SleepBedIdle" and energy >= 0.5:
		param["obj"] = self
		param["state"] = "Idle"
		self.pushAction("TravelAnimState", actionDepth)
		return Globals.ACTION_STATE.Running
	
	bed.BelongTo = null
	return Globals.ACTION_STATE.Finished
	
func Sleep(delta : float, param : Dictionary, actionDepth : int) -> int:
	var recover := self.SleepEnerSec * delta
	var wake_ener : float = param["wake"] as float
	if Needs.GetNeed(Globals.NEEDS.Energy) + recover > wake_ener:
		Needs.SetNeed(Globals.NEEDS.Energy, wake_ener)
		return Globals.ACTION_STATE.Finished
	Needs.ApplyNeed(Globals.NEEDS.Energy, recover)
	return Globals.ACTION_STATE.Running
	
func CookInKitchen2(delta : float, param : Dictionary, actionDepth : int) -> int:
	var plan : ActionPlan = param.get("current_plan", null)
	var fridge : Advertisement = param.get("plan_ad", null)
	var kitchen : Advertisement = self.getFirstOf(Globals.AD_TYPE.Kitchen)
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	var fridge_inv : Array = fridge.AdMetaData.get("inventory", [])
	var player_inv : Array = param.get("inventory", [])
	var kitchen_inv : Array = kitchen.AdMetaData.get("inventory", [])
	
	var fridge_foodstuff : Advertisement = self.findItemInInv(fridge_inv, Globals.AD_TYPE.Foodstuff)
	var player_foodstuff : Advertisement = self.findItemInInv(player_inv, Globals.AD_TYPE.Foodstuff)
	var kitchen_foodstuff : Advertisement = self.findItemInInv(kitchen_inv, Globals.AD_TYPE.Foodstuff)
	var player_food : Advertisement = self.findItemInInv(player_inv, Globals.AD_TYPE.Food)
	
	if not is_top_of_stack:
		return Globals.ACTION_STATE.Running
	
	# 1. grab from fridge
	if fridge_foodstuff != null:
		if not self.isAtLocation(fridge.position, 1.5):
			param["target"] = fridge.position
			param["precision"] = 1.5
			self.pushAction("Goto", actionDepth)
			return Globals.ACTION_STATE.Running
		else:
			param["item"] = fridge_foodstuff
			param["from"] = fridge
			param["to"] = self
			self.pushAction("Transfer", actionDepth)
			return Globals.ACTION_STATE.Running
	
	# 2. put on closest kitchen counter
	if player_foodstuff != null:
		if not self.isAtLocation(kitchen.position, 1.0):
			param["target"] = kitchen.position
			param["precision"] = 1.0
			self.pushAction("Goto", actionDepth)
			return Globals.ACTION_STATE.Running
		else:
			param["item"] = player_foodstuff
			param["from"] = self
			param["to"] = kitchen
			self.pushAction("Transfer", actionDepth)
			return Globals.ACTION_STATE.Running
	
	# 3. Cook
	if kitchen_foodstuff != null:
		var cooking_left = kitchen_foodstuff.AdMetaData.get("cooking_left", 6.0)
		cooking_left -= delta
		kitchen_foodstuff.AdMetaData["cooking_left"] = cooking_left
		if cooking_left > 0:
			self.travelAnimOneShot(self, "Interact")
		else:
			param["scene"] = plan.SpawnReward
			self.pushAction("Spawn", actionDepth)
			kitchen_foodstuff.queue_free()
			kitchen_foodstuff.visible = false
			kitchen_inv.erase(kitchen_foodstuff)
			kitchen.AdMetaData["inventory"] = kitchen_inv
			return Globals.ACTION_STATE.Running
	
	# 4. Finished
	if player_food != null:
		return Globals.ACTION_STATE.Finished
	
	return Globals.ACTION_STATE.Running
	
func GoPutFoodInFridge(delta : float, param : Dictionary, actionDepth : int) -> int:
	var plan : ActionPlan = param.get("current_plan", null)
	var item : Advertisement = param.get("plan_ad", null)
	var fridge : Advertisement = self.getFirstOf(Globals.AD_TYPE.Fridge)
	var container : Advertisement = item.AdMetaData.get("container", null)
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	
	if not is_top_of_stack:
		return Globals.ACTION_STATE.Running
	
	if container.Type == Globals.AD_TYPE.Fridge:
		return Globals.ACTION_STATE.Finished
	
	if container == self:
		param["item"] = item
		param["container"] = fridge
		self.pushAction("GoDropItem", actionDepth)
	else:
		param["item"] = item
		self.pushAction("GoGetItem", actionDepth)
	
	return Globals.ACTION_STATE.Running
	
func RefillFridge2(delta : float, param : Dictionary, actionDepth : int) -> int:
	var plan : ActionPlan = param.get("current_plan", null)
	var fridge : Advertisement = param.get("plan_ad", null)
	var market : Advertisement = self.getFirstOf(Globals.AD_TYPE.Market)
	var player_inv : Array = param.get("inventory", [])
	var fridge_inv : Array = fridge.AdMetaData.get("inventory", [])
	var player_foodstuff : Advertisement = self.findItemInInv(player_inv, Globals.AD_TYPE.Foodstuff)
	var fridge_foodstuff : Advertisement = self.findItemInInv(fridge_inv, Globals.AD_TYPE.Foodstuff)
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	
	if not is_top_of_stack:
		return Globals.ACTION_STATE.Running
		
	if fridge_foodstuff != null:
		return Globals.ACTION_STATE.Finished
		
	if player_foodstuff == null and not self.isAtLocation(market.position):
		param["target"] = market.position
		param["precision"] = 0.5
		self.pushAction("Goto", actionDepth)
		return Globals.ACTION_STATE.Running
		
	if player_foodstuff == null and self.isAtLocation(market.position):
		param["scene"] = plan.SpawnReward
		self.travelAnimOneShot(self, "Interact")
		self.pushAction("Spawn", actionDepth)
		return Globals.ACTION_STATE.Running
		
	if player_foodstuff != null and not self.isAtLocation(fridge.position, 1.5):
		param["target"] = fridge.position
		param["precision"] = 1.5
		self.pushAction("Goto", actionDepth)
		return Globals.ACTION_STATE.Running
		
	if player_foodstuff != null and self.isAtLocation(fridge.position, 1.5):
		param["item"] = player_foodstuff
		param["from"] = self
		param["to"] = fridge
		self.pushAction("Transfer", actionDepth)
		return Globals.ACTION_STATE.Running
	
	return Globals.ACTION_STATE.Running
	

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
	n.AdMetaData["container"] = self
	return Globals.ACTION_STATE.Finished
	
	
func EatSelectedFood(delta : float, param : Dictionary, actionDepth : int) -> int:
	var plan : ActionPlan = param.get("current_plan", null)
	var food : Advertisement = param.get("plan_ad", null)
	var food_container : Advertisement = food.AdMetaData.get("container", null)
	var player_inv : Array = param.get("inventory", [])
	var player_food : Advertisement = self.findItemInInv(player_inv, Globals.AD_TYPE.Food)
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	var chair : Advertisement = self.getFirstOf(Globals.AD_TYPE.Chair)
	var table : Advertisement = self.getFirstOf(Globals.AD_TYPE.Table)
	var table_inv : Array = table.AdMetaData.get("inventory", [])
	var table_food : Advertisement = self.findItemInInv(table_inv, Globals.AD_TYPE.Food)
	var player_state : String = self.animState(self)
	
	if not is_top_of_stack:
		return Globals.ACTION_STATE.Running
	
	if player_food == null and not self.isAtLocation(food_container.position, 1.0):
		param["target"] = food_container.position
		param["precision"] = 1.0
		self.pushAction("Goto", actionDepth)
		return Globals.ACTION_STATE.Running
		
	if player_food == null and self.isAtLocation(food_container.position, 1.0):
		param["item"] = food
		param["from"] = food_container
		param["to"] = self
		self.pushAction("Transfer", actionDepth)
		return Globals.ACTION_STATE.Running
		
	if player_food != null and table_food == null and not self.isAtLocation(table.position, 1.0):
		param["target"] = food_container.position
		param["precision"] = 1.0
		self.pushAction("Goto", actionDepth)
		return Globals.ACTION_STATE.Running
		
	if player_food != null and table_food == null and self.isAtLocation(table.position, 1.0):
		param["item"] = player_food
		param["from"] = self
		param["to"] = table
		self.pushAction("Transfer", actionDepth)
		return Globals.ACTION_STATE.Running
		
	if table_food != null and not self.isAtLocation(chair.position, 1.0):
		param["target"] = chair.position
		param["precision"] = 1.0
		self.pushAction("Goto", actionDepth)
		return Globals.ACTION_STATE.Running
		
	if table_food != null and self.isAtLocation(chair.position, 1.0) and player_state != "SitChairIdle":
		param["obj"] = self
		param["state"] = "SitChairIdle"
		self.pushAction("TravelAnimState", actionDepth)
		return Globals.ACTION_STATE.Running
		
	if table_food != null and player_state == "SitChairIdle":
		var food_left = table_food.AdMetaData.get("food_left", 6.0)
		food_left -= delta
		table_food.AdMetaData["food_left"] = food_left
		if food_left > 0:
			#TODO: add sitting interact anim?
			return Globals.ACTION_STATE.Running
		else:
			table_food.queue_free()
			table_food.visible = false
			table_inv.erase(table_food)
			table.AdMetaData["inventory"] = table_inv
			return Globals.ACTION_STATE.Finished

	return Globals.ACTION_STATE.Finished
	
###################################################################################################
## ACTION FUNCTION (NEED REVISION)
###################################################################################################
	
func SleepOnFloor(delta : float, param : Dictionary, actionDepth : int) -> int:
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	if Needs.GetNeed(Globals.NEEDS.Energy) > 0.5 and is_top_of_stack:
		return Globals.ACTION_STATE.Finished
	else:
		if is_top_of_stack:
			param["wake"] = randf_range(0.5, 0.8)
		self.pushAction("Sleep", actionDepth)
	return Globals.ACTION_STATE.Running

	
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
	
func popAction(depth) -> void:
	var last_action = self.actionStack[depth]
	print("Entity %s Poped %s" % [self.name, last_action])
	self.lastAction = last_action
	self.actionStack = self.actionStack.slice(0, depth)
	
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
	
func isTypeInInv(inv : Array, target : Globals.AD_TYPE) -> bool:
	for i in inv:
		if (i as Advertisement).Type == target:
			return true
	return false
	
func isItemInInv(inv : Array, target : Advertisement) -> bool:
	for i in inv:
		if (i as Advertisement) == target:
			return true
	return false
	
func findItemInInv(inv : Array, target : Globals.AD_TYPE) -> Advertisement:
	for i in inv:
		var ad := i as Advertisement
		if ad.Type == target:
			return ad
	return null
	
func animState(obj : Node3D) -> String:
	var obj_tree : AnimationTree = obj.find_child("AnimationTree", true, false)
	var obj_state : AnimationNodeStateMachinePlayback = obj_tree.get("parameters/playback")
	var cur_anim = obj_state.get_current_node()
	return cur_anim
	
func travelAnimOneShot(obj : Node3D, target : String) -> void:
	var obj_tree : AnimationTree = obj.find_child("AnimationTree", true, false)
	var obj_state : AnimationNodeStateMachinePlayback = obj_tree.get("parameters/playback")
	obj_state.travel(target)
	
func getContainer(obj : Advertisement) -> Advertisement:
	return obj.AdMetaData.get("container", null)
	
class Sorter:
	var sort_key
	func _init(k):
		sort_key = k
		
	func sort_desc(a, b):
		if a[sort_key] > b[sort_key]:
			return true
		return false
		
