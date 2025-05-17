extends ItemIcon
class_name TradeGoodIcon

@export var good_type_enum: trade_good_type
@export var quantity: int = 1
@export var custom_name: String = ""  # For custom item names

enum trade_good_type {
	HERB,
	ORE,
	WOOD,
	LEATHER
}

func _ready() -> void:
	# Set up the icon display
	stat_label.text = "x" + str(quantity)
	
	# Use custom name if provided, otherwise use the enum key
	if custom_name != "":
		item_label.text = custom_name
	else:
		item_label.text = trade_good_type.keys()[good_type_enum]
		item_label.text = item_label.text.capitalize()
	
	# Default price is based on type and quantity
	if price == 0:
		var base_price = 0
		match good_type_enum:
			trade_good_type.HERB: base_price = 4
			trade_good_type.ORE: base_price = 6
			trade_good_type.WOOD: base_price = 4
			trade_good_type.LEATHER: base_price = 4
		price = int(base_price * quantity) / 2
	price_label.text = str(price) + "g"

# Called when the node enters the scene tree for the first time.
func _process(delta: float) -> void:
	# This ensures the label is updated even if custom_name is changed after _ready
	if custom_name != "" and item_label.text != custom_name:
		item_label.text = custom_name
