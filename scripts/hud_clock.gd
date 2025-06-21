extends Label

var timeSystem : WorldClock

func _ready() -> void:
	self.timeSystem = self.get_tree().root.find_child("WorldClock", true, false)

func _process(delta: float) -> void:
	self.text = self.timeSystem.GetCurDateTimeString()
