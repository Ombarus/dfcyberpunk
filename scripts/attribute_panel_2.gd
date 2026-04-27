extends Control

var objRef : Advertisement
var needMap : Dictionary = {}

var needsContainer : Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.OnAdSelected.connect(OnAdSelected_Callback)
	
	var need_ref : Control = self.find_child("Need", true, false)
	needsContainer = need_ref.get_parent()
	for i in Globals.NEEDS.values():
		var need = need_ref.duplicate()
		need.visible = true
		var k = Globals.NEEDS.keys()[i]
		(need.get_node("Label") as Label).text = k
		needMap[i] = need
		self.needsContainer.add_child(need)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if objRef == null:
		return
		
	# inventory
	# name
	# belongto
	# type
	# action stack
	# plan score
	# offered plans
	# skill
	# needs
	# ad metadata?

func OnAdSelected_Callback(obj_ref):
	objRef = obj_ref
	self.visible = true

func _on_close_pressed() -> void:
	self.visible = false
