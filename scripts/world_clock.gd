extends Node
class_name WorldClock

const SECOND_IN_DAY : int = 86400
const SECOND_IN_HOUR : int = 3600
const SECOND_IN_MINUTE : int = 60

@export var DayLengthSec : float = 100.0

@export var CurDateTime := {
	"year": 2035,
	"month": 1,
	"day": 1,
	"hour": 6,
	"minute": 0,
	"second": 0
}

var unixTime : int
var frac : float

func _ready() -> void:
	self.unixTime = Time.get_unix_time_from_datetime_dict(CurDateTime)
	self.frac = 0.0

func _process(delta: float) -> void:
	# depending on the FPS, even if time moves faster in-game, it's possible one frame is
	# less than "one game second" so we need to keep track of fractions even if unixTime
	# is only second precision
	var world_sec : float = delta * (86400.0 / DayLengthSec) + frac
	var whole_sec = floor(world_sec)
	frac = world_sec - whole_sec
	self.unixTime += whole_sec
	self.CurDateTime = Time.get_datetime_dict_from_unix_time(self.unixTime)
	
# Year and Months is too complex, just express it in days or whatever!
# params are optional and can be "day", "hour", "minute" or "second"
func GetDelta(arg : Dictionary) -> int:
	var delta : int = 0
	delta += arg.get("day", 0) * SECOND_IN_DAY
	delta += arg.get("hour", 0) * SECOND_IN_HOUR
	delta += arg.get("minute", 0) * SECOND_IN_MINUTE
	delta += arg.get("second", 0)
	return delta

func GetDeltaDateTime(delta : int) -> Dictionary:
	return Time.get_datetime_dict_from_unix_time(self.unixTime + delta)
	
# Second would move too fast considering the length of a day in game
# So I don't think we need to display it
func GetCurDateTimeString() -> String:
	return "%04d-%02d-%02d %02d:%02d" % [
		self.CurDateTime["year"],
		self.CurDateTime["month"],
		self.CurDateTime["day"],
		self.CurDateTime["hour"],
		self.CurDateTime["minute"]
	]

func GetDeltaDateTimeString(ts : int) -> String:
	var d : Dictionary = Time.get_datetime_dict_from_unix_time(ts)
	return "%04d-%02d-%02d %02d:%02d" % [
		self.CurDateTime["year"],
		self.CurDateTime["month"],
		self.CurDateTime["day"],
		self.CurDateTime["hour"],
		self.CurDateTime["minute"]
	]
