extends Gatherable
class_name LogGatherable

func _ready() -> void:
	# Set default values for a log
	gatherable_type = "Log"
	display_name = "Log"
	min_quantity = 1
	max_quantity = 2
	
	mesh_instance = $log/log
	collision_shape = $CollisionShape3D
	
	# Call the parent _ready function to handle the rest
	super._ready()
