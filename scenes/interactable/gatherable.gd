extends LootContainer
class_name Gatherable

@export var gatherable_type: String = "Lily"  # For quest tracking
@export var display_name: String = "Lily"  # For display in inventory
@export var min_quantity: int = 1
@export var max_quantity: int = 3
@export var randomize_quantity: bool = true

@onready var mesh_instance: MeshInstance3D
@onready var collision_shape: CollisionShape3D

var is_collected: bool = false

func _ready() -> void:
	super._ready()  # Call parent _ready
	
	# Update any TradeGoodIcons with the correct name and hide them while in the world
	for item in get_items():
		if item is TradeGoodIcon:
			item.custom_name = display_name
			
			# Randomize quantity if enabled
			if randomize_quantity:
				item.quantity = randi_range(min_quantity, max_quantity)
				
				# Update quantity display
				item.stat_label.text = "x" + str(item.quantity)
				
				# Recalculate price based on the new quantity
				var base_price = 0
				match item.good_type_enum:
					TradeGoodIcon.trade_good_type.HERB: base_price = 4
					TradeGoodIcon.trade_good_type.ORE: base_price = 6
					TradeGoodIcon.trade_good_type.WOOD: base_price = 4
					TradeGoodIcon.trade_good_type.LEATHER: base_price = 4
				
				item.price = int(base_price * item.quantity) / 2
				item.price_label.text = str(item.price) + "g"
			
			# Hide the item icon while in the world
			item.visible = false

func gather(player_inventory: Inventory) -> void:
	if is_collected:
		return
	
	# Mark as collected
	is_collected = true
	
	# Hide the gatherable
	mesh_instance.visible = false
	collision_shape.disabled = true
	
	# Add all contained items to the inventory
	var items = get_items()
	for item in items:
		if item is TradeGoodIcon:
			# Make sure the custom name is set
			item.custom_name = display_name
			
			# Make the icon visible again before adding to inventory
			item.visible = true
		
		var parent = item.get_parent()
		if parent:
			parent.remove_child(item)
		player_inventory.add_item(item)
	
	# Record item collection in the QuestManager
	QuestManager.record_item_collection(gatherable_type)
	
	# Remove the gatherable entirely
	queue_free()
