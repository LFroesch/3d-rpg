extends ItemIcon
class_name ArmorIcon

@export var protection: int
@export var armor: armor_type

enum armor_type {
	IRON_PLATE,
	STEEL_PLATE,
	ORCISH_PLATE
}

func _ready() -> void:
	stat_label.text = "+" + str(protection)
	item_label.text = armor_type.keys()[armor]
	item_label.text = item_label.text.capitalize()
	if price == 0:
		price = protection * 5
	price_label.text = str(int(price / 2)) + "g"
