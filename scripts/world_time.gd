extends Node
class_name WorldTime

@export var DayTickLength : float = 100.0
@export var TickLengthSec : float = 3.0

var cur_tick : float = 0.0
var cur_day : int = 0

func _process(delta: float) -> void:
	cur_tick += delta / TickLengthSec
	while cur_tick >= DayTickLength:
		cur_tick -= DayTickLength
		cur_day += 1

func GetTickOfDay() -> float:
	return cur_tick
	
func GetDay() -> int:
	return cur_day
	
func GetAbsoluteTick() -> float:
	return (cur_day * DayTickLength) + cur_tick

func GameHoursToGameTick(hours : float) -> float:
	return hours / 24.0 * DayTickLength

func RealSecondToGameTick(seconds : float) -> float:
	return  seconds / TickLengthSec
