extends Control

var objRef : Advertisement
var objRefEntity : Entity
var needMap : Dictionary = {}
var skillMap : Dictionary = {}

var needsContainer : Control
var skillsContainer : Control
var inventoryList: Control
var belongTolbl: Label
var typelbl: Label
var currentAction: Label
var actionPlanList: Control
var planScoreList: Control
var metadatalbl: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.OnAdSelected.connect(OnAdSelected_Callback)
	
	self.inventoryList = find_child("InventoryList", true, false)
	self.belongTolbl = $TabContainer/Status/VBoxContainer/AdInfo/BelongTo
	self.typelbl = $TabContainer/Status/VBoxContainer/AdInfo/Type
	self.currentAction = $TabContainer/Debug/VBoxContainer/PlansGroup/CurrentAction
	self.actionPlanList = $TabContainer/Inventory/VBoxContainer/AdOffers/ColorRect2/AdScore
	self.planScoreList = $TabContainer/Debug/VBoxContainer/PlansGroup/ColorRect/ScrollContainer/PlanScore
	self.metadatalbl = $TabContainer/Debug/VBoxContainer/PlansGroup/ColorRect2/ScrollContainer/Metadatalbl
	
	var need_ref : Control = self.find_child("Need", true, false)
	need_ref.visible = false
	needsContainer = need_ref.get_parent()
	for i in Globals.NEEDS.values():
		var need = need_ref.duplicate()
		need.visible = true
		var k = Globals.NEEDS.keys()[i]
		(need.get_node("Label") as Label).text = k
		self.needMap[i] = need
		self.needsContainer.add_child(need)
		
	var skill_ref : Control = self.find_child("Skill", true, false)
	skill_ref.visible = false # just for layout, should not be visible
	self.skillsContainer = skill_ref.get_parent()
	for i in Globals.SKILLS.values():
		var skill = skill_ref.duplicate()
		skill.visible = true
		var k = Globals.SKILLS.keys()[i]
		(skill.get_node("Label") as Label).text = k
		self.skillMap[i] = skill
		self.skillsContainer.add_child(skill)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if objRef == null:
		return
		
	# inventory
	var inv : Array = objRef.Inventory
	var example_inv : Control = self.inventoryList.get_node("Example")
	for i in range(inv.size()):
		# +1 to skip example row
		if i + 1 >= self.inventoryList.get_child_count():
			var newInv = example_inv.duplicate()
			self.inventoryList.add_child(newInv)
			newInv.visible = true
		var invNode = self.inventoryList.get_child(i + 1)
		var invNodeType : String = Globals.AD_TYPE.keys()[inv[i].Type]
		if invNode.text != invNodeType:
			invNode.text = invNodeType
	
	if inv.size() + 1 < self.inventoryList.get_child_count():
		for i in range(inv.size() + 1, self.inventoryList.get_child_count()):
			var child_to_delete : Node = self.inventoryList.get_child(inv.size() + 1)
			self.inventoryList.remove_child(child_to_delete)
			child_to_delete.visible = false
			child_to_delete.queue_free()
	
	# type
	typelbl.text = "Type: " + Globals.AD_TYPE.keys()[objRef.Type]
	
	# belongto
	if objRef.BelongTo == null:
		belongTolbl.text = "Belong To: No One"
	else:
		belongTolbl.text = "Belong To: " + objRef.BelongTo.name
	
	# action stack
	if self.objRefEntity != null:
		var actions = ""
		for a in self.objRefEntity.actionStack:
			if actions != "":
				actions += "->"
			actions += a
		self.currentAction.text = actions

	# offered plans
	# Won't include "special" plans that override getActionPlansFor()
	# Though right now getActionPlansFor only filters, I don't think we create plans on the fly
	var i := 0
	for p in objRef.ActionPlans:
		var l : Label = null
		if i >= self.actionPlanList.get_child_count():
			l = Label.new()
			l.visible = true
			self.actionPlanList.add_child(l)
		else:
			l = self.actionPlanList.get_child(i)
		l.text = p.ActionName
		i += 1
	var listSize : int = self.actionPlanList.get_child_count()
	for j in range(listSize - 1, i - 1, -1):
		var todel : Label = self.actionPlanList.get_child(j)
		self.actionPlanList.remove_child(todel)
		todel.visible = false
		todel.queue_free()
		
	
	# needs
	if self.objRefEntity != null:
		self.needMap[0].get_parent().visible = true
		self.skillMap[0].get_parent().visible = true
		for k in self.needMap:
			var p : ProgressBar = self.needMap[k].get_node("Progress")
			var v : float = self.objRefEntity.Needs.GetNeed(k)
			p.value = v
			p.get_node("Label").text = "%0.3f%%" % [v * 100.0]
	
		# skills
		for k in self.skillMap:
			var p : ProgressBar = self.skillMap[k].get_node("Progress")
			var v : float = self.objRefEntity.Skills.GetSkill(k)
			p.value = v
			p.get_node("Label").text = "%0.3f%%" % [v * 100.0]
	else:
		self.needMap[0].get_parent().visible = false
		self.skillMap[0].get_parent().visible = false
	
	# ad metadata?
	self.metadatalbl.text = JSON.stringify(self.objRef.AdMetaData, "  ")
	
	# plan score
	if self.objRefEntity != null:
		self.planScoreList.visible = true
		i = 0
		#var data = {
			#"plan": i,
			#"ad": ad,
			#"score": Needs.GetRewardScoreFromPlan(i as ActionPlan)
		#}
		var high_score : float = self.objRefEntity.knownPlans[0]["score"]
		var low_score : float = self.objRefEntity.knownPlans[self.objRefEntity.knownPlans.size() - 1]["score"]
		for p in self.objRefEntity.knownPlans:
			var cur_score = p["score"]
			var cur_name = p["plan"].ActionName
			var t = (cur_score - low_score) / (high_score - low_score) if high_score != low_score else 1.0
			var color := Color.WHITE.lerp(Color.RED, 1.0 - t)
			var l : RichTextLabel = null
			if i >= self.planScoreList.get_child_count():
				l = RichTextLabel.new()
				l.visible = true
				l.bbcode_enabled = true
				l.custom_minimum_size = Vector2(250, 24)
				self.planScoreList.add_child(l)
			else:
				l = self.planScoreList.get_child(i)
			l.text = "[color=#%s]%s: %0.3f[/color]\n" % [color.to_html(false), cur_name, cur_score]
			i += 1
		listSize = self.planScoreList.get_child_count()
		for j in range(listSize - 1, i - 1, -1):
			var todel : RichTextLabel = self.planScoreList.get_child(j)
			self.planScoreList.remove_child(todel)
			todel.visible = false
			todel.queue_free()
	else:
		self.planScoreList.visible = false

func OnAdSelected_Callback(obj_ref):
	self.objRef = obj_ref
	self.objRefEntity = objRef as Entity
	var namelbl : Label = $TabContainer/Status/VBoxContainer/Name
	namelbl.text = "Name: " + objRef.name
	self.visible = true

func _on_close_pressed() -> void:
	self.visible = false
