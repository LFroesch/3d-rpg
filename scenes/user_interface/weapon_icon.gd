extends ItemIcon
class_name WeaponIcon

@export var power: int
@export var item_model: PackedScene

func _ready() -> void:
	stat_label.text = "+" + str(power)
	item_label.text = item_model.resource_path.get_file()
	var extension = item_model.resource_path.get_extension()
	item_label.text = item_label.text.rstrip("." + extension)
	item_label.text = item_label.text.capitalize()
	if price == 0:
		price = power * 5
	price_label.text = str(int(price / 2)) + "g"
