extends Node3D
class_name POI

@export var PoiType : Globals.POI_TYPE
@export var Belongings : Array[Advertisement]
@export var Spawnable : bool = true

func _ready() -> void:
	self.add_to_group("Poi" + str(self.PoiType))
