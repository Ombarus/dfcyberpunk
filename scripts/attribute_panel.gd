extends Control

var objRef : Advertisement
var needMap : Dictionary = {}

var needsContainer : Control
var currentAction : Label
var entityPlans : Control
var adInfo : Control
var adPlans: Control
var inventoryContainer : Control

func _ready() -> void:
	Events.OnAdSelected.connect(OnAdSelected_Callback)
	
	self.needsContainer = self.find_child("NeedList", true, false)
	self.currentAction = self.find_child("CurrentAction", true, false)
	self.entityPlans = self.find_child("PlanScore", true, false)
	self.adInfo = self.find_child("AdInfo", true, false)
	self.adPlans = self.find_child("AdScore", true, false)
	self.inventoryContainer = self.find_child("Inventory", true, false)
	
	var need_ref : Control = self.find_child("Need", true, false)
	for i in Globals.NEEDS.values():
		var need = need_ref.duplicate()
		need.visible = true
		var k = Globals.NEEDS.keys()[i]
		(need.get_node("Label") as Label).text = k
		needMap[i] = need
		self.needsContainer.add_child(need)
		

func _process(delta: float) -> void:
	if objRef == null:
		return
		
	self.global_position = get_viewport().get_camera_3d().unproject_position(objRef.global_position)
	
	var is_entity = objRef is Entity
	self.needsContainer.get_parent().visible = is_entity
	self.currentAction.get_parent().visible = is_entity
	self.adInfo.visible = not is_entity
	self.adPlans.get_parent().get_parent().visible = not is_entity
	
	var inv : Array = objRef.Inventory
	var example_inv : Control = self.inventoryContainer.get_node("Example")
	for i in range(inv.size()):
		# +1 to skip example row
		if i + 1 >= self.inventoryContainer.get_child_count():
			var newInv = example_inv.duplicate()
			self.inventoryContainer.add_child(newInv)
			newInv.visible = true
		var invNode = self.inventoryContainer.get_child(i + 1)
		var invNodeType : String = Globals.AD_TYPE.keys()[inv[i].Type]
		if invNode.text != invNodeType:
			invNode.text = invNodeType
	
	if inv.size() + 1 < self.inventoryContainer.get_child_count():
		for i in range(inv.size() + 1, self.inventoryContainer.get_child_count()):
			var child_to_delete : Node = self.inventoryContainer.get_child(inv.size() + 1)
			self.inventoryContainer.remove_child(child_to_delete)
			child_to_delete.visible = false
			child_to_delete.queue_free()
			
	$HBoxContainer/Info/Name.text = "Name: " + objRef.name
	
	if is_entity:
		var ent := objRef as Entity
		var actions = ""
		for a in ent.actionStack:
			if actions != "":
				actions += "->"
			actions += a
		self.currentAction.text = actions
		
		for k in self.needMap:
			var p : ProgressBar = self.needMap[k].get_node("Progress")
			var v : float = ent.Needs.GetNeed(k)
			p.value = v
			p.get_node("Label").text = "%0.3f%%" % [v * 100.0]
			
		var greened := false
		for c in self.entityPlans.get_children():
			c.queue_free()
		for info in ent.knownPlans:
			var plan := info["plan"] as ActionPlan
			var score : float = info["score"]
			var l : RichTextLabel = RichTextLabel.new()
			l.bbcode_enabled = true
			var color := "[color=white]"
			var planed_sat : float = plan.GetExpectedReward(Globals.NEEDS.Satiety) + ent.Needs.Current(Globals.NEEDS.Satiety)
			var planed_sati : float = plan.GetExpectedReward(Globals.NEEDS.Satisfaction) + ent.Needs.Current(Globals.NEEDS.Satisfaction) 
			var planed_ener : float = plan.GetExpectedReward(Globals.NEEDS.Energy) + ent.Needs.Current(Globals.NEEDS.Energy)
			if planed_sat < 1.0 and planed_sati < 1.0 and planed_ener < 1.0:
				if greened == false:
					color = "[color=green]"
					greened = true
			else:
				color = "[color=red]"
			l.text = color + plan.ActionName + ": " + str(score) + "[/color]"
			l.custom_minimum_size = Vector2(250, 20)
			l.tooltip_text = "Food: %.4f\nJoy: %.4f\nEner: %.4f\nRich: %.4f" % [
				plan.GetExpectedReward(Globals.NEEDS.Satiety),
				plan.GetExpectedReward(Globals.NEEDS.Satisfaction),
				plan.GetExpectedReward(Globals.NEEDS.Energy),
				plan.GetExpectedReward(Globals.NEEDS.Wealth)
			]
			l.mouse_filter = Control.MOUSE_FILTER_STOP
			self.entityPlans.add_child(l)
	else:
		var belongNode : Label = self.adInfo.get_node("BelongTo")
		var typeNode : Label = self.adInfo.get_node("Type")
		if objRef.BelongTo == null:
			belongNode.text = "Belong To: No One"
		else:
			belongNode.text = "Belong To: " + objRef.BelongTo.name
		typeNode.text = "Type: " + Globals.AD_TYPE.keys()[objRef.Type]
		
func OnAdSelected_Callback(obj_ref):
	objRef = obj_ref
	self.visible = true
	
