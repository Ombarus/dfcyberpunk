extends Control

var objRef : Advertisement
var needMap : Dictionary = {}

var needsContainer : Control
var currentAction : Label
var entityPlans : Control
var adInfo : Control
var adPlans: Control

func _ready() -> void:
	Events.OnAdSelected.connect(OnAdSelected_Callback)
	
	self.needsContainer = self.find_child("NeedList", true, false)
	self.currentAction = self.find_child("CurrentAction", true, false)
	self.entityPlans = self.find_child("PlanScore", true, false)
	self.adInfo = self.find_child("AdInfo", true, false)
	self.adPlans = self.find_child("AdScore", true, false)
	
	var need_ref : Control = self.find_child("Need", true, false)
	for i in Globals.NEEDS.values():
		var need = need_ref.duplicate()
		var k = Globals.NEEDS.keys()[i]
		(need.get_node("Label") as Label).text = k
		needMap[i] = need
	need_ref.get_node("../..").visible = false
	
	currentAction.get_parent().visible = false
		

func _process(delta: float) -> void:
	if objRef == null:
		return
		
	self.position = get_viewport().get_camera_3d().unproject_position(objRef.position)
	var is_entity = objRef is Entity
	self.needsContainer.get_parent().visible = is_entity
	self.currentAction.get_parent().visible = is_entity
	self.adInfo.visible = not is_entity
	self.adPlans.get_parent().get_parent().visible = not is_entity
		
func OnAdSelected_Callback(obj_ref):
	objRef = obj_ref
	self.visible = true
	
