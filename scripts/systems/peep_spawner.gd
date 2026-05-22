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

# if something is not spawnable it means it's already been used
# I was planing to distinguish between "generic" Poi and "spawnable" poi.. 
# but for now it's more of a "used" or "unused"

@export var Spawnables : Array[PackedScene]

func _ready() -> void:
	deferred_init.call_deferred()
	
func deferred_init() -> void:
	# Doctor have priority over generic Appartment tenant
	# Technically, CEO too, but right now CEOOffice also contain the appartment (weird I know)
	for n in get_tree().get_nodes_in_group("Poi" + str(Globals.POI_TYPE.DoctorOffice)):
		n = n as POI
		if n == null:
			continue
			
		var livingPoi : POI = null
		for a in get_tree().get_nodes_in_group("Poi" + str(Globals.POI_TYPE.Appartment)):
			a = a as POI
			if a == null or a.Spawnable == false:
				continue
			
			livingPoi = a
			break
			
		if livingPoi == null:
			print("ERROR!! Could not find an appartment for Doctor Poi")
			continue
			
		var peep := generic_spawn(livingPoi)
		for owned : Advertisement in n.Belongings:
			owned.BelongTo = peep
		peep.Skills.UpdateSkill(Globals.SKILLS.Medicine, max(randf(), 0.2))
		n.Spawnable = false
			
	for n in get_tree().get_nodes_in_group("poi"):
		n = n as POI
		if n == null:
			continue
		
		#TODO: prioritize spawn (doctors and CEOs are more important than unemployed to claim poi
		if (n.PoiType == Globals.POI_TYPE.MarketWorker or 
		  n.PoiType == Globals.POI_TYPE.BarWorker or 
		  n.PoiType == Globals.POI_TYPE.DeliveryWorker or 
		  n.PoiType == Globals.POI_TYPE.CEOOffice) and n.Spawnable:
			var peep := generic_spawn(n)
			
		if n.PoiType == Globals.POI_TYPE.Appartment and n.Spawnable:
			var peep := generic_spawn(n)
			peep.TagMap["unemployed"] = 1.0


func generic_spawn(n : POI) -> Entity:
	var peep := self.Spawnables.pick_random().instantiate() as Entity
	n.get_parent().add_child(peep)
	peep.global_transform = n.global_transform
	for owned : Advertisement in n.Belongings:
		owned.BelongTo = peep
	if n.name.contains("Poi"):
		peep.name = n.name.replace("Poi", "Peep")
	n.Spawnable = false
	return peep
