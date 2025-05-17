extends TextureButton
class_name ItemIcon

signal interact(item)

@onready var stat_label: Label = $MarginContainer/StatLabel
@onready var item_label: Label = $MarginContainer/ItemLabel
@onready var price_label: Label = $MarginContainer/PriceLabel

@export var item_id: String = ""
@export var price: int = 0

func _on_gui_input(event: InputEvent) -> void:
	if event.is_action("click"):
		interact.emit(self)

func get_price() -> int:
	return price
