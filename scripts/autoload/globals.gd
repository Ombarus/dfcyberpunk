extends Node

var AD_GROUP := "advertisements"
var DEFAULT_TABLE_HEIGHT := 0.73
var DAY_LENGTH_SEC := 900.0

enum ACTION_STATE {
	Running,
	Finished,
	Error
}

enum AD_TYPE {
	Bed,
	Food,
	Foodstuff,
	Kitchen,
	Currency,
	Market,
	Office,
	Chair,
	Fridge,
	Table,
	Cashing,
	Other
}

enum NEEDS {
	Satiety, # Hunger, goes down automatically, need to eat
	Energy, # Tiredness, goes down automatically, need to sleep or rest
	Satisfaction, # Feeling of being needed, of having accomplished something
	Wealth, # How much money you have (not really a need to be honest) 1 = Really really rich
	Health, # HP, 0 = dead, 1 = full health. Goes down when hurt or sick
	Humanity, # "Essence" in Shadowrun. Cyberware make it go down over time. Need medecine or "good deeds" to recover it
	Joy, # To oppose Satisfaction. Sometime fullfilling jobs are not fun so you need to watch TV
	Security, # To ecourage company to spend money on security system. To encourage thugs to get guns
	Curiosity, # To oppose Satisfaction and encourage Peeps to go to school. Learn skills but also take risks
	Comfort # Encourage Peeps to buy useless things or better things (more comfortable couch, or better car)
}

enum SKILLS {
	Cooking,
	Fighting,
	Driving
}

# To eventually help PCG most pieces should fit in a standard
# grid. Right now I'm leaning toward 2x2x2m
var FLOOR_HEIGHT : float = 3.0
var FLOOR_WIDTH : float = 2.0


# Balancing plan reward is hard. I'm thinking having a "base" reward value then a modifier per plan 
# will allow me to make global adjustement easily but also tweak per-plan
enum GRADE {
	VBig,
	Big,
	Medium,
	Small,
	VSmall,
	Unset # backward compat
}

# Values are Daily or by action
# Satiety 0.72 / day, Energy 0.54 / day, Satisfaction 0.45 / day
var REWARD_BASE := {
	NEEDS.Satiety: {
		GRADE.VBig: 0.7,
		GRADE.Big: 0.6,
		GRADE.Medium: 0.4,
		GRADE.Small: 0.2,
		GRADE.VSmall: 0.01
	},
	NEEDS.Energy: {
		GRADE.VBig: 0.7,
		GRADE.Big: 0.5,
		GRADE.Medium: 0.3,
		GRADE.Small: 0.2,
		GRADE.VSmall: 0.1
	},
	NEEDS.Satisfaction: {
		GRADE.VBig: 0.4,
		GRADE.Big: 0.2,
		GRADE.Medium: 0.02,
		GRADE.Small: 0.01,
		GRADE.VSmall: 0.001
	},
	NEEDS.Wealth: {
		GRADE.VBig: 0.1, # ~100 000$
		GRADE.Big: 0.01, # ~10 000$
		GRADE.Medium: 0.001, # ~1 000$
		GRADE.Small: 0.0002, # ~200$
		GRADE.VSmall: 0.00005 # ~50$
	},
	NEEDS.Health: {
		GRADE.VBig: 1.5, # instant kill. Or certain death if not treated
		GRADE.Big: 0.99, # near death
		GRADE.Medium: 0.5, # ouch
		GRADE.Small: 0.1, # annoyance
		GRADE.VSmall: 0.05 # did you feel something?
	},
	NEEDS.Humanity: {
		GRADE.VBig: 0.83, # 5/6 essence (wired reflex lvl3)
		GRADE.Big: 0.5, # 3/6 essence (wired reflex lvl2)
		GRADE.Medium: 0.33, # 2/6 essence (wired reflex lvl1)
		GRADE.Small: 0.09, # 0.5/6 essence (bone lacing, cyber eye, cyberarm, etc.)
		GRADE.VSmall: 0.033 # 0.2 essence (datajack, commlink, simrig, etc)
	},
	NEEDS.Joy: {
		GRADE.VBig: 0.4,
		GRADE.Big: 0.2,
		GRADE.Medium: 0.02,
		GRADE.Small: 0.01,
		GRADE.VSmall: 0.001
	},
	NEEDS.Security: {
		GRADE.VBig: 0.4,
		GRADE.Big: 0.2,
		GRADE.Medium: 0.02,
		GRADE.Small: 0.01,
		GRADE.VSmall: 0.001
	},
	NEEDS.Curiosity: {
		GRADE.VBig: 0.4,
		GRADE.Big: 0.2,
		GRADE.Medium: 0.02,
		GRADE.Small: 0.01,
		GRADE.VSmall: 0.001
	},
	NEEDS.Comfort: {
		GRADE.VBig: 0.4,
		GRADE.Big: 0.2,
		GRADE.Medium: 0.02,
		GRADE.Small: 0.01,
		GRADE.VSmall: 0.001
	}
}
