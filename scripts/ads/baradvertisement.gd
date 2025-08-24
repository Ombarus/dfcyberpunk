extends Advertisement

var timeSystem : WorldClock

func _ready() -> void:
	super._ready()
	self.timeSystem = self.get_tree().root.find_child("WorldClock", true, false)

func GetActionPlansFor(npc : Entity) -> Array:
	var work_at_bar := ActionPlan.new()
	work_at_bar.ActionName = "WorkAtBar"
	work_at_bar.EnergyReward = 0.0
	work_at_bar.SatietyReward = 0.0
	work_at_bar.SatisfactionReward = 0.40
	work_at_bar.RichnessReward = 0.00015 # 150$ of 1M
	# work hours from 17 to 2am but must start between 16 and 18
	if self.timeSystem.CurDateTime["hour"] >= 16 and self.timeSystem.CurDateTime["hour"] < 19:
		return [work_at_bar]
	else:
		return []
