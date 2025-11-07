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
	Satiety,
	Energy,
	Satisfaction,
	Wealth
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
	}
}
