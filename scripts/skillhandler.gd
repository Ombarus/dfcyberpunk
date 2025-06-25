extends Object
class_name SkillHandler

var CurrentSkills := {
	Globals.SKILLS.Cooking: 0.0,
	Globals.SKILLS.Fighting: 0.0,
	Globals.SKILLS.Driving: 0.0
}

func GetSkill(n : Globals.SKILLS) -> float:
	return CurrentSkills[n]
	
func UpdateSkill(n : Globals.SKILLS, v : float) -> void:
	CurrentSkills[n] = v
