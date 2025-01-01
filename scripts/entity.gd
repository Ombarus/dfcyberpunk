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
# Action don't know if child action is done or not
# How to express preferences? ie: NPC like to eat healthy so he should get a bonus to cooking healthy food...
#    but just from the needs/reward of the action plan we can't really tell


@export var MovePixSec : float = 100.0
@export var MoveEnerSec : float = 0.01
@export var EatUnitSec : float = 0.3334
@export var CookEnerSec : float = 0.01
@export var SleepEnerSec : float = 0.1
@export var SatSec : float = 0.01 # consider 1 day = 100 seconds, 0.01 means 1 to 0 in 100 seconds
@export var SatisSec : float = 0.001
@export var SleepJitter : float = 0.1 # Random variation in % (if bed give +0.9, this will add/remove 10% of 0.9)

var Needs := NeedHandler.new()

var curParam : Dictionary
var actionStack : Array
var lastAction : String
var debugThoughtsAction : Label
var debugThoughtsSatiety : ProgressBar
var debugThoughtsEnergy : ProgressBar
var debugThoughtsSatisfaction : ProgressBar


func _ready() -> void:
	var target := Vector2(100, 100)
	self.curParam = {"target": target}
	self.actionStack = ["Goto"]
	self.debugThoughtsEnergy = self.find_child("EnergyProgress", true, false) as ProgressBar
	self.debugThoughtsSatiety = self.find_child("SatietyProgress", true, false) as ProgressBar
	self.debugThoughtsSatisfaction = self.find_child("SatisfactionProgress", true, false) as ProgressBar
	self.debugThoughtsAction = self.find_child("Action", true, false) as Label

func _process(delta: float) -> void:
	if self.actionStack.size() == 0:
		self.pushAction("Default", -1)
	for i in self.actionStack.size():
		var s = self.callv(self.actionStack[i], [delta, self.curParam, i])
		
		if (s == Globals.ACTION_STATE.Finished):
			self.popAction()
	
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

func UpdateSatiety(delta : float) -> void:
	Needs.ApplyNeedOverTime(Globals.NEEDS.Satiety, -self.SatSec, delta)
	
func UpdateSatisfaction(delta : float) -> void:
	Needs.ApplyNeedOverTime(Globals.NEEDS.Satisfaction, -self.SatisSec, delta)

func Goto(delta : float, param : Dictionary, actionDepth : int) -> int:
	var cur_pos := self.position
	var dir := (param["target"] as Vector2) - cur_pos
	var dir_norm = dir.normalized()
	var move : Vector2 = dir_norm * self.MovePixSec * delta
	var ret_val = Globals.ACTION_STATE.Running
	if move.length_squared() > dir.length_squared():
		move = dir
		ret_val = Globals.ACTION_STATE.Finished
	var energy : float = move.length() / self.MovePixSec * self.MoveEnerSec
	self.position += move
	Needs.ApplyNeed(Globals.NEEDS.Energy, -energy)
	return ret_val

func Eat(delta : float, param : Dictionary, actionDepth : int) -> int:
	var ret_val = Globals.ACTION_STATE.Running
	var food_left := param["food"] as float
	var eat := self.EatUnitSec * delta
	if eat > food_left:
		eat = food_left
		ret_val = Globals.ACTION_STATE.Finished
	param["food"] = food_left - eat
	
	# Can you eat more than your fill? (maybe you get fat?)
	Needs.ApplyNeed(Globals.NEEDS.Satiety, eat)
	
	return ret_val
	
func Cook(delta : float, param : Dictionary, actionDepth : int) -> int:
	# You cannot be interrupted while cooking?
	if not isTopOfStack(actionDepth):
		return Globals.ACTION_STATE.Running
		
	var cook_left := param["meal"] as float
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
	var cur_plan : ActionPlan = param["current_plan"]
	
	if cook_left == 0:
		if food_to_drop != null:
			param["item"] = food_to_drop
			self.pushAction("Drop", actionDepth)
			return Globals.ACTION_STATE.Running
		else:
			return Globals.ACTION_STATE.Finished
		
	var ener := self.CookEnerSec * delta
	if ener >= cook_left:
		ener = cook_left
		param["scene"] = cur_plan.SpawnReward
		self.pushAction("Spawn", actionDepth)
	Needs.ApplyNeed(Globals.NEEDS.Energy, -ener)
	# Can't be bottered to redo the logic so just flip the sign
	# (see comment above)
	param["meal"] = -(cook_left - ener)
	return Globals.ACTION_STATE.Running

func Default(delta : float, param : Dictionary, actionDepth : int) -> int:
	var food : Advertisement = self.getFirstOf(Globals.AD_TYPE.Food)
	var bed : Advertisement = self.getFirstOf(Globals.AD_TYPE.Bed)
	var prefered_energy_action := ""
	var prefered_energy_reward := 0.0
	if bed != null:
		for a in bed.ActionPlans:
			if a.EnergyReward > prefered_energy_reward:
				prefered_energy_reward = a.EnergyReward
				prefered_energy_action = a.ActionName
	var prefered_satiety_action := ""
	var prefered_satiety_reward := 0.0
	if food != null:
		for a in food.ActionPlans:
			if a.SatietyReward > prefered_satiety_reward:
				prefered_satiety_reward = a.SatietyReward
				prefered_satiety_action = a.ActionName

	# next_action implement "sticky" actions, so we don't alternate between two high-prio cancel
	var next_action : String = getCurAction(actionDepth+1)
	var cur_ener : float = Needs.GetNeed(Globals.NEEDS.Energy)
	var cur_sat : float = Needs.GetNeed(Globals.NEEDS.Satiety)
	if bed != null and (cur_ener <= 0.03 or (prefered_energy_action != "" and next_action == prefered_energy_action)):
		self.pushAction(prefered_energy_action, actionDepth)
	elif bed == null and (cur_ener <= 0.03 or (prefered_energy_action != "" and next_action == prefered_energy_action) or next_action == "SleepOnFloor"):
		self.pushAction("SleepOnFloor", actionDepth)
	elif cur_sat <= 0.03 and (food != null or (prefered_satiety_action != "" and next_action == prefered_satiety_action)):
		self.pushAction(prefered_satiety_action, actionDepth)
	elif food == null:
		var choosen_plan : ActionPlan = param.get("current_plan", null)
		if choosen_plan == null or choosen_plan.SpawnRewardType != Globals.AD_TYPE.Food:
			var food_plans := []
			var ads = get_parent().get_children()
			for o in ads:
				var ad := (o as Advertisement)
				for ao in ad.ActionPlans:
					var plan := (ao as ActionPlan)
					if plan.SpawnRewardType == Globals.AD_TYPE.Food:
						food_plans.append(plan)
			choosen_plan = food_plans.pick_random()
			param["current_plan"] = choosen_plan
		self.pushAction(choosen_plan.ActionName, actionDepth)
	elif isTopOfStack(actionDepth):
		var view_size = get_viewport_rect().size / get_viewport().get_camera_2d().zoom
		var pos_x := randi_range(25, view_size.x - 25)
		var pos_y := randi_range(10, view_size.y - 10)
		param["target"] = Vector2(pos_x, pos_y)
		self.pushAction("Goto", actionDepth)
		
	return Globals.ACTION_STATE.Running
	
func EatClosestFood(delta : float, param : Dictionary, actionDepth : int) -> int:
	# By running every frame, this will automatically change target
	# if it disappear or move and pick new food if it get stolen or something
	var inv : Array = param.get("inventory", [])
	var food_to_eat : Advertisement
	for i in inv:
		var ad = (i as Advertisement)
		if (i as Advertisement).Type == Globals.AD_TYPE.Food:
			food_to_eat = ad
			break
			
	if Needs.GetNeed(Globals.NEEDS.Satiety) > 0.1 and isTopOfStack(actionDepth):
		inv.erase(food_to_eat)
		food_to_eat.queue_free()
		return Globals.ACTION_STATE.Finished
	
	if food_to_eat != null:
		if isTopOfStack(actionDepth):
			var prefered_satiety_reward := 0.0
			for a in food_to_eat.ActionPlans:
				if a.ActionName == "EatClosestFood":
					prefered_satiety_reward = a.SatietyReward
			param["food"] = prefered_satiety_reward
		self.pushAction("Eat", actionDepth)
		return Globals.ACTION_STATE.Running

	var food : Advertisement = self.getFirstOf(Globals.AD_TYPE.Food)
	if food == null:
		return Globals.ACTION_STATE.Error
		
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
	#var food : Advertisement = self.getFirstOf(TYPE.FOOD)
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	var meal_left = param.get("meal", null)
	if meal_left != null and meal_left <= 0 and is_top_of_stack:
		param.erase("meal")
		param.erase("meal_sati")
		param.erase("current_plan")
		return Globals.ACTION_STATE.Finished
	if self.position != kitchen.position:
		param["target"] = kitchen.position
		self.pushAction("Goto", actionDepth)
	else:
		if is_top_of_stack:
			param["meal"] = cur_plan.EnergyReward
			param["meal_sati"] = cur_plan.SatisfactionReward
		self.pushAction("Cook", actionDepth)
	return Globals.ACTION_STATE.Running

func Spawn(delta : float, param : Dictionary, actionDepth : int) -> int:
	var pos : Vector2 = self.position
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
	var pos = self.position + Vector2(randi_range(-50.0, 50.0), randi_range(-50.0, 50.0))
	item.position = pos
	return Globals.ACTION_STATE.Finished
	
func Wait(delta : float, param : Dictionary, actionDepth: int) -> int:
	var wait_left : float = param["wait"]
	wait_left -= delta
	if wait_left <= 0.0:
		return Globals.ACTION_STATE.Finished
	param["wait"] = wait_left
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
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	var bed : Advertisement = self.getFirstOf(Globals.AD_TYPE.Bed)
	if bed == null:
		return Globals.ACTION_STATE.Error
		
	if Needs.GetNeed(Globals.NEEDS.Energy) > 0.8 and is_top_of_stack:
		bed.BelongTo = null
		return Globals.ACTION_STATE.Finished
	if self.position != bed.position:
		param["target"] = bed.position
		self.pushAction("Goto", actionDepth)
	else:
		if is_top_of_stack:
			var prefered_action_reward = 0
			if bed != null:
				for a in bed.ActionPlans:
					if a.EnergyReward > prefered_action_reward:
						prefered_action_reward = a.EnergyReward
			var base_sleep = prefered_action_reward
			var jitter = randf_range(-self.SleepJitter, self.SleepJitter)
			var wake = clamp(Needs.GetNeed(Globals.NEEDS.Energy) + base_sleep + jitter, 0.0, 1.0)
			param["wake"] = wake
			bed.BelongTo = self
		self.pushAction("Sleep", actionDepth)
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
	print("Entity %s Inserted %s at %i" % [self.name, action, at_index])
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
