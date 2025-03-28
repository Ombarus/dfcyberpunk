extends Node

var AD_GROUP := "advertisements"

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
	Other
}

enum NEEDS {
	Satiety,
	Energy,
	Satisfaction,
	Richness
}
