extends Node
class_name PeepSpawner

#######################################
# Sickness Manager
######################################
# Idea is to have this system connect all the Entities to the world
# Make sure to set their starting skills, randomize their needs and personality, etc.
# It should also build a budget of "needed" peeps.
# For example, look at how many "appartments" there are, 
# if there's an Hospital, spawn nurses and doctors, etc.

# The tricky part for now is how do I assign ownership?
# I don't have a concept of "appartment", I was just manually assigning "owned"
# items like bed and chairs in an appartment.
# Event worst, how to do it accross prefabs? 
# (Like set up the doctor with an appartment and his workplace at the hospital)

@export var Spawnables : Array[PackedScene]

func _ready() -> void:
	for n in get_tree().get_nodes_in_group("poi"):
		n = n as POI
		if n == null:
			continue
			
		if (n.PoiType == Globals.POI_TYPE.MarketWorker or n.PoiType == Globals.POI_TYPE.BarWorker) and n.Spawnable:
			var peep := self.Spawnables.pick_random().instantiate() as Entity
			n.get_parent().add_child(peep)
			peep.global_transform = n.global_transform
			for owned : Advertisement in n.Belongings:
				owned.BelongTo = peep
			if n.name.contains("Poi"):
				peep.name = n.name.replace("Poi", "Peep")
			n.Spawnable = false
