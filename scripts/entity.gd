extends Advertisement
class_name Entity

enum STATE {
	RUNNING,
	FINISHED,
	ERROR
}

@export var MovePixSec : float = 100.0
@export var MoveEnerSec : float = 0.01
@export var EatUnitSec : float = 0.3334
@export var CookUnitSec : float = 0.3334
@export var CookEnerSec : float = 0.07
@export var SleepEnerSec : float = 0.1
@export var SatSec : float = 0.01 # consider 1 day = 100 seconds, 0.01 means 1 to 0 in 100 seconds

@export var Satiety : float = 0.3
@export var Energy : float = 0.3

var curParam : Dictionary
var actionStack : Array
var lastAction : String
var debugThoughtsAction : Label
var debugThoughtsSatiety : ProgressBar
var debugThoughtsEnergy : ProgressBar

func _ready() -> void:
	var target := Vector2(100, 100)
	self.curParam = {"target": target}
	self.actionStack = ["Goto"]
	self.debugThoughtsEnergy = self.find_child("EnergyProgress", true, false) as ProgressBar
	self.debugThoughtsSatiety = self.find_child("SatietyProgress", true, false) as ProgressBar
	self.debugThoughtsAction = self.find_child("Action", true, false) as Label

func _process(delta: float) -> void:
	if self.actionStack.size() == 0:
		self.pushAction("Default", -1)
	for i in self.actionStack.size():
		var s = self.callv(self.actionStack[i], [delta, self.curParam, i])
		
		if (s == STATE.FINISHED):
			self.popAction()
	
	UpdateThoughts()
	UpdateSatiety(delta)

func UpdateThoughts():
	self.debugThoughtsEnergy.value = self.Energy
	self.debugThoughtsSatiety.value = self.Satiety
	var actions = ""
	for a in actionStack:
		if actions != "":
			actions += "->"
		actions += a
	self.debugThoughtsAction.text = actions

func UpdateSatiety(delta : float) -> void:
	self.Satiety -= self.SatSec * delta

func Goto(delta : float, param : Dictionary, actionDepth : int) -> int:
	var cur_pos := self.position
	var dir := (param["target"] as Vector2) - cur_pos
	var dir_norm = dir.normalized()
	var move : Vector2 = dir_norm * self.MovePixSec * delta
	var ret_val = STATE.RUNNING
	if move.length_squared() > dir.length_squared() or move.length_squared() <= 0.0001:
		move = dir
		ret_val = STATE.FINISHED
	var energy : float = move.length() / self.MovePixSec * self.MoveEnerSec
	self.position += move
	self.Energy -= energy
	return ret_val

func Eat(delta : float, param : Dictionary, actionDepth : int) -> int:
	var ret_val = STATE.RUNNING
	var food_left := param["food"] as float
	var eat := self.EatUnitSec * delta
	if eat > food_left:
		eat = food_left
		ret_val = STATE.FINISHED
	param["food"] = food_left - eat
	# Can you eat more than your fill? (maybe you get fat?)
	self.Satiety = clamp(self.Satiety + eat, 0.0, 1.0)
	
	return ret_val
	
func Cook(delta : float, param : Dictionary, actionDepth : int) -> int:
	# You cannot be interrupted while cooking?
	if not isTopOfStack(actionDepth):
		return STATE.RUNNING
		
	var cook_left := param["meal"] as float
	if cook_left == 0:
		return STATE.FINISHED
		
	var progress := self.CookUnitSec * delta
	var ener := self.CookEnerSec * delta
	if progress >= cook_left:
		progress = cook_left
		# calculate energy loss based on the fraction of the dt we used to cook
		ener = self.CookEnerSec * (progress / self.CookUnitSec)
		param["scene"] = "res://scenes/food.tscn"
		param["pos"] = self.position + Vector2(randi_range(-50.0, 50.0), randi_range(-50.0, 50.0))
		self.pushAction("Spawn", actionDepth)
	self.Energy -= ener
	param["meal"] = cook_left - progress
	return STATE.RUNNING

func Default(delta : float, param : Dictionary, actionDepth : int) -> int:
	var food : Advertisement = self.getFirstOf(TYPE.FOOD)
	var bed : Advertisement = self.getFirstOf(TYPE.BED)
	# next_action implement "sticky" actions, so we don't alternate between two high-prio cancel
	var next_action : String = getCurAction(actionDepth+1)
	if bed != null and (self.Energy <= 0.03 or next_action == "SleepInBed"):
		self.pushAction("SleepInBed", actionDepth)
	elif bed == null and (self.Energy <= 0.03 or next_action == "SleepInBed" or next_action == "SleepOnFloor"):
		self.pushAction("SleepOnFloor", actionDepth)
	elif self.Satiety <= 0.03 and food != null or next_action == "EatClosestFood":
		self.pushAction("EatClosestFood", actionDepth)
	elif food == null and isTopOfStack(actionDepth):
		self.pushAction("CookInKitchen", actionDepth)
	elif isTopOfStack(actionDepth):
		var pos_x := randi_range(50, get_viewport_rect().size.x - 50)
		var pos_y := randi_range(20, get_viewport_rect().size.y - 20)
		param["target"] = Vector2(pos_x, pos_y)
		self.pushAction("Goto", actionDepth)
		
	return STATE.RUNNING
	
func EatClosestFood(delta : float, param : Dictionary, actionDepth : int) -> int:
	# By running every frame, this will automatically change target
	# if it disappear or move and pick new food if it get stolen or something
	var inv : Array = param.get("inventory", [])
	if self.Satiety > 0.1 and isTopOfStack(actionDepth):
		var f = inv.pop_back()
		return STATE.FINISHED
	
	if inv.size() > 0:
		if isTopOfStack(actionDepth):
			# TODO: get from food value in inventory?
			param["food"] = 0.6
		self.pushAction("Eat", actionDepth)
		return STATE.RUNNING

	var food : Advertisement = self.getFirstOf(TYPE.FOOD)
	if food == null:
		return STATE.ERROR
		
	if self.position != food.position:
		param["target"] = food.position
		self.pushAction("Goto", actionDepth)
	else:
		param["item"] = food
		self.pushAction("Pickup", actionDepth)

	return STATE.RUNNING
	
func CookInKitchen(delta : float, param : Dictionary, actionDepth : int) -> int:
	var kitchen : Advertisement = self.getFirstOf(TYPE.KITCHEN)
	var food : Advertisement = self.getFirstOf(TYPE.FOOD)
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	if food != null and is_top_of_stack:
		return STATE.FINISHED
	if self.position != kitchen.position:
		param["target"] = kitchen.position
		self.pushAction("Goto", actionDepth)
	else:
		if is_top_of_stack:
			param["meal"] = 1.0
		self.pushAction("Cook", actionDepth)
	return STATE.RUNNING

func Spawn(delta : float, param : Dictionary, actionDepth : int) -> int:
	var scene_name : String = param["scene"] as String
	var pos : Vector2 = param["pos"] as Vector2
	var pack := load(scene_name) as PackedScene
	var n : Node2D = pack.instantiate() as Node2D
	self.get_parent().add_child(n)
	n.position = pos
	return STATE.FINISHED

func Pickup(delta : float, param : Dictionary, actionDepth : int) -> int:
	var item : Node2D = param["item"] as Node2D
	param.erase("item")
	var inv : Array = param.get("inventory", [])
	inv.push_back(item.name)
	param["inventory"] = inv
	item.queue_free()
	return STATE.FINISHED
	
func SleepOnFloor(delta : float, param : Dictionary, actionDepth : int) -> int:
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	if self.Energy > 0.5 and is_top_of_stack:
		return STATE.FINISHED
	else:
		if is_top_of_stack:
			param["wake"] = randf_range(0.5, 0.8)
		self.pushAction("Sleep", actionDepth)
	return STATE.RUNNING
	
func SleepInBed(delta : float, param : Dictionary, actionDepth : int) -> int:
	var is_top_of_stack : bool = isTopOfStack(actionDepth)
	var bed : Advertisement = self.getFirstOf(TYPE.BED)
	if bed == null:
		return STATE.ERROR
		
	if self.Energy > 0.8 and is_top_of_stack:
		bed.Owner = null
		return STATE.FINISHED
	if self.position != bed.position:
		param["target"] = bed.position
		self.pushAction("Goto", actionDepth)
	else:
		if is_top_of_stack:
			param["wake"] = randf_range(0.90, 1.00)
			bed.Owner = self
		self.pushAction("Sleep", actionDepth)
	return STATE.RUNNING
	
func Sleep(delta : float, param : Dictionary, actionDepth : int) -> int:
	var ret_val := STATE.RUNNING
	var recover := self.SleepEnerSec * delta
	var wake_ener : float = param["wake"] as float
	if self.Energy + recover > wake_ener:
		self.Energy = wake_ener
		return STATE.FINISHED
	self.Energy += recover
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

func getFirstOf(t : TYPE) -> Advertisement:
	var nodes : Array = get_tree().get_nodes_in_group(str(t))
	for n in nodes:
		n = n as Advertisement
		if n and n.Owner == null or n.Owner == self:
			return n
	return null
