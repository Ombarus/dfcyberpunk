extends Object
class_name SkillHandler

var CurrentSkills := {
	Globals.SKILLS.Cooking: 0.0,
	Globals.SKILLS.Fighting: 0.0,
	Globals.SKILLS.Driving: 0.0,
	Globals.SKILLS.Medicine: 0.0
}

# skill gain per skill check
# currently unbalanced, could be modified by NPC (rimworld passion-style)
var XPScale := {
	Globals.SKILLS.Cooking: 0.001,
	Globals.SKILLS.Fighting: 0.001,
	Globals.SKILLS.Driving: 0.001,
	Globals.SKILLS.Medicine: 0.001
}

func GetSkill(n : Globals.SKILLS) -> float:
	return CurrentSkills[n]
	
func UpdateSkill(n : Globals.SKILLS, v : float) -> void:
	CurrentSkills[n] = v

func SkillCheck(n : Globals.SKILLS, v : float) -> bool:
	var not_zero := 0.0000001
	var my_skill : float = CurrentSkills[n]
	var p : float = (my_skill + not_zero) / (my_skill + v + not_zero)
	var hit : float = randf()
	CurrentSkills[n] = clamp(my_skill + XPScale[n], 0.0, 1.0)
	return hit >= p
