extends Advertisement

@export var Output : PackedScene
@export var CompletionInput : float = 0.0
@export var CompletionOutput : float = 0.5
@export var MinInvStartProcess : int = 3

var AnimPlayer : AnimationPlayer
var ProcessTimer : Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if has_node("Blender/AnimationPlayer"):
		self.AnimPlayer = get_node("Blender/AnimationPlayer")
	self.ProcessTimer = get_node("ProcessTimer")
	self.Wake.connect(OnWake)
	
func OnWake() -> void:
	var to_blend : Array[Advertisement] = []
	for i in self.Inventory:
		var item := i as Advertisement
		var completion : float = item.TagMap.get("completion", -1.0)
		if completion == self.CompletionInput:
			to_blend.append(item)
			
	if to_blend.size() > self.MinInvStartProcess:
		if self.AnimPlayer != null:
			self.AnimPlayer.play("GrinderRun")
		for i in to_blend:
			self.Inventory.erase(i)
		self.ProcessTimer.start()

func _on_process_timer_timeout() -> void:
	if self.AnimPlayer != null:
		self.AnimPlayer.play("GrinderStop")
	var n := self.Output.instantiate() as Advertisement
	self.get_parent().add_child(n)
	n.global_position = self.global_position
	n.visible = false
	n.TagMap["completion"] = self.CompletionOutput
	var inv : Array = self.Inventory
	inv.append(n)
	self.Inventory = inv
	n.AdMetaData["container"] = self
