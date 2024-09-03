extends Node2D

enum STATE {
	RUNNING,
	FINISHED,
	ERROR
}

@export var MovePixSec : float = 100.0
@export var EatUnitSec : float = 0.3334
@export var CookUnitSec : float = 0.3334
@export var SleepEnerSec : float = 0.1

@export var Satiety : float = 0.0
@export var Energy : float = 0.0

var curParam : Dictionary
var actionStack : Array
var lastAction : String
var lastState : int
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
	var cur_action = self.getCurAction()
	var s = self.callv(cur_action, [delta, self.curParam])
	if (s == STATE.FINISHED):
		self.popAction()
	
	self.lastState = s
	UpdateThoughts()
	#self.modulate.r = self.Satiety
	#self.modulate.g = self.Energy

func UpdateThoughts():
	self.debugThoughtsEnergy.value = self.Energy
	self.debugThoughtsSatiety.value = self.Satiety
	var actions = ""
	for a in actionStack:
		if actions != "":
			actions += "->"
		actions += a
	self.debugThoughtsAction.text = actions

func Goto(delta : float, param : Dictionary) -> int:
	var cur_pos := self.position
	var dir := (param["target"] as Vector2) - cur_pos
	var dir_norm = dir.normalized()
	var move : Vector2 = dir_norm * self.MovePixSec * delta
	var ret_val = STATE.RUNNING
	if move.length_squared() > dir.length_squared() or move.length_squared() <= 0.0001:
		move = dir
		ret_val = STATE.FINISHED
	self.position += move
	return ret_val

func Eat(delta : float, param : Dictionary) -> int:
	var ret_val = STATE.RUNNING
	var food_left := param["food"] as float
	var eat := self.EatUnitSec * delta
	if eat > food_left:
		eat = food_left
		ret_val = STATE.FINISHED
	param["food"] = food_left - eat
	self.Satiety = clamp(self.Satiety + eat, 0.0, 1.0)
	
	return ret_val
	
func Cook(delta : float, param : Dictionary) -> int:
	if param.get("scene", "") != "":
		return STATE.FINISHED
		
	var ret_val = STATE.RUNNING
	var cook_left := param["meal"] as float
	var progress := self.CookUnitSec * delta
	if progress > cook_left:
		progress = cook_left
		param["scene"] = "res://scenes/food.tscn"
		param["pos"] = self.position
		self.pushAction("Spawn")
	param["meal"] = cook_left - progress
	return ret_val

func Default(delta : float, param : Dictionary) -> int:
	var ret_val := STATE.RUNNING
	if self.Energy <= 0.001:
		self.pushAction("SleepInBed")
	elif self.Satiety <= 0.001 and not self.position.is_equal_approx(Vector2(150, 300)):
		self.pushAction("Goto")
		param["target"] = Vector2(150, 300)
	elif self.Satiety <= 0.001 and self.position.is_equal_approx(Vector2(150, 300)):
		self.pushAction("Cook")
		param["meal"] = 1.0
	return ret_val

func Spawn(delta : float, param : Dictionary) -> int:
	var ret_val := STATE.RUNNING
	var scene_name : String = param["scene"] as String
	var pos : Vector2 = param["pos"] as Vector2
	var pack := load(scene_name) as PackedScene
	var n : Node2D = pack.instantiate() as Node2D
	self.get_parent().add_child(n)
	n.position = pos
	ret_val = STATE.FINISHED
	return ret_val

func Pickup(delta : float, param : Dictionary) -> int:
	var item : Node2D = param["item"] as Node2D
	param.erase("item")
	var inv : Array = param.get("inventory", [])
	inv.push_back(item.name)
	param["inventory"] = inv
	item.queue_free()
	return STATE.FINISHED
	
func SleepInBed(delta : float, param : Dictionary) -> int:
	var ret_val := STATE.RUNNING
	if self.Energy > 0.8:
		return STATE.FINISHED
	var bed : Node2D = self.get_parent().find_child("Bed", false, false) as Node2D
	if self.position != bed.position:
		param["target"] = bed.position
		self.pushAction("Goto")
	else:
		param["wake"] = randf_range(0.90, 1.00)
		self.pushAction("Sleep")
	return ret_val
	
func Sleep(delta : float, param : Dictionary) -> int:
	var ret_val := STATE.RUNNING
	var recover := self.SleepEnerSec * delta
	var wake_ener : float = param["wake"] as float
	if self.Energy + recover > wake_ener:
		self.Energy = wake_ener
		return STATE.FINISHED
	self.Energy += recover
	return ret_val

func pushAction(action : String) -> void:
	print("Entity %s Pushed %s" % [self.name, action])
	self.actionStack.push_back(action)
	
func popAction() -> void:
	var last_action = self.actionStack[-1]
	print("Entity %s Poped %s" % [self.name, last_action])
	self.lastAction = last_action
	self.actionStack.remove_at(len(self.actionStack)-1)
	
func getCurAction() -> String:
	if len(self.actionStack) <= 0:
		return "Default"
	return self.actionStack[-1]
