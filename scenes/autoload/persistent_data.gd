extends Control

@onready var inventory_node: Control = $InventoryNode
@onready var shield_node: Control = $ShieldNode
@onready var armor_node: Control = $ArmorNode
@onready var weapon_node: Control = $WeaponNode

var gold := 0
var current_health := 0
var removed_items = []  # Just a list of removed item IDs

func remove_item(item_id: String) -> void:
	if not item_id in removed_items:
		removed_items.append(item_id)

func was_item_removed(item_id: String) -> bool:
	return item_id in removed_items

func cache_gear(player: Player) -> void:
	print("cache_gear called with player: ", player)
	
	if not is_instance_valid(player):
		print("ERROR: Player is not valid!")
		return
		
	if not player.get("user_interface"):
		print("ERROR: Player has no user_interface!")
		return
	for item in player.user_interface.inventory.item_grid.get_children():
		cache_item(item, inventory_node)
	cache_item(
		player.user_interface.inventory.get_weapon(),
		weapon_node
	)
	cache_item(
		player.user_interface.inventory.get_shield(),
		shield_node
	)
	cache_item(
		player.user_interface.inventory.get_armor(),
		armor_node
	)
	gold = player.user_interface.inventory.gold

func cache_player_data(player: Player) -> void:
	current_health = player.health_component.current_health

func get_inventory() -> Array:
	return inventory_node.get_children()

func get_equipped_items() -> Array:
	var equipped_items := []
	if weapon_node.get_child_count() > 0:
		equipped_items.append(weapon_node.get_child(0))
	if armor_node.get_child_count() > 0:
		equipped_items.append(armor_node.get_child(0))
	if shield_node.get_child_count() > 0:
		equipped_items.append(shield_node.get_child(0))
	return equipped_items

func cache_item(item: ItemIcon, storage_node: Control) -> void:
	item.get_parent().remove_child(item)
	storage_node.add_child(item)
