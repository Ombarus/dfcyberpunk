extends Node

var AD_GROUP := "advertisements"
var DEFAULT_TABLE_HEIGHT := 0.73

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
	Other
}

enum NEEDS {
	Satiety,
	Energy,
	Satisfaction,
	Richness
}

enum SKILLS {
	Cooking,
	Fighting,
	Driving
}
