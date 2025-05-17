extends Gatherable
class_name LilyGatherable

func _ready() -> void:
	# Set specific values for a lily
	gatherable_type = "Lily"
	display_name = "Lily"
	min_quantity = 1
	max_quantity = 3
	
	# Set mesh and collision references
	mesh_instance = $_flower_1/flower_1
	collision_shape = $CollisionShape3D
	
	# Set the correct trade good type
	for item in get_items():
		if item is TradeGoodIcon:
			item.good_type_enum = TradeGoodIcon.trade_good_type.HERB
	
	# Now call parent _ready
	super._ready()
