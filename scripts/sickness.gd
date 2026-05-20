extends Node
class_name SicknessManager

#######################################
# Sickness Manager
######################################
# Simplified for now to just randomly make some peep sick.
# Might need to make it a tag on the Peep instead of keeping it in the System (to be a bit more ECS-ish)
# Future improvement could be:
#   Specific Sickness with different characteristics and healing rate/needs
#   More Control spread by proximity and virulance
#   Peeps could have imunities, vulnerabilities, chronic sicknesses, etc.

@export var sicksPerDay := 1.0
#TODO: Would be more fun if randomized per NPC in the future (to simulate different sicknesses)
@export var damagePerDay := -0.2
# One time drop, encourage peeps to do stuff like watch tv when sick maybe?
@export var joyDrop : Globals.GRADE

var sicks : Array[Entity]
var nextSickTime : float
var timeSystem : WorldClock

func _ready() -> void:
	self.timeSystem = self.get_tree().root.find_child("WorldClock", true, false)
	next_sick.call_deferred()

func _process(delta: float) -> void:
	var hp_drop : float = self.damagePerDay / Globals.DAY_LENGTH_SEC * delta
	for sick in sicks:
		sick.Needs.ApplyNeed(Globals.NEEDS.Health, hp_drop)

	if self.timeSystem.unixTime < self.nextSickTime:
		return

	next_sick()
	var nodes : Array = get_tree().get_nodes_in_group(str(Globals.AD_TYPE.Peep))
	var pick : int = randi_range(0, nodes.size()-1)
	var n = nodes[pick] as Entity
	if n and not n in sicks:
		print(n.name + " has become sick!")
		sicks.push_back(n)
		n.Needs.ApplyNeed(Globals.NEEDS.Joy, self.joyDrop)

func next_sick() -> void:
	# Poisson distribution (says chatgpt)
	# roll dice to see how long until next person get sick
	# Very small chance of multiple sickness or long time without sickness
	# on average sicksPerDay per day
	var rnd := randf()
	var next_sick_day : float = abs(log(rnd) / self.sicksPerDay)
	# There is a tiny tiny chance to get crazy numbers like 10000 years, so let's clamp it just in case
	next_sick_day = clamp(next_sick_day, 0.0, 3.0)
	var unix_delta : int = self.timeSystem.GetDelta({"day": next_sick_day})
	self.nextSickTime = self.timeSystem.unixTime + unix_delta
	print("Next sickness in " + str(unix_delta) + ", rolled " + str(rnd))

func IsSick(n : Entity) -> bool:
	return n in self.sicks
