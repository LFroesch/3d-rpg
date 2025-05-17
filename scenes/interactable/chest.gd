extends StaticBody3D
class_name LootContainer

@export var chest_id: String = ""

func _ready() -> void:

	if chest_id.is_empty():
		chest_id = "chest_%d_%d_%d" % [
			round(global_position.x), 
			round(global_position.y), 
			round(global_position.z)
		]

	var items = get_items()
	for i in range(items.size()):
		if items[i].item_id.is_empty():
			items[i].item_id = chest_id + "_item_" + str(i)
	
	for i in range(items.size() - 1, -1, -1):
		if PersistentData.was_item_removed(items[i].item_id):
			items[i].queue_free()
	
func get_items() -> Array:
	return get_children().filter(
		func(child): return child is ItemIcon
	)

func check_empty() -> void:
	if get_items().size() == 0:
		print("Loot container is empty, removing: ", chest_id)
		queue_free()
