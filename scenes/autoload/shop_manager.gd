extends Node


signal shop_opened(shop_id: String)
signal shop_closed()

# Store weapon and shield models as PackedScenes (like in your enemy class)
var weapon_models = {
	"longsword": preload("res://assets/Character/Gear/Longsword.glb"),
	"battleaxe": preload("res://assets/Character/Gear/Battleaxe.glb"),
	"claymore": preload("res://scenes/added_weapons/claymore.tscn")
}

var shield_models = {
	"small": preload("res://assets/Character/Gear/Short_Shield.glb"),
	"large": preload("res://assets/Character/Gear/Tall_Shield.glb")
}

# Dictionary to store shop inventories
var shops: Dictionary = {
	"vendor1": {
		"name": "Vagar",
		"items": [
			{
				"type": "weapon",
				"power": 15,
				"model_key": "longsword",
				"price": 75
			},
			{
				"type": "weapon",
				"power": 25,
				"model_key": "battleaxe",
				"price": 125
			},
			{
				"type": "armor",
				"protection": 15,
				"armor_type": 0,
				"price": 75
			},
			{
				"type": "armor",
				"protection": 30,
				"armor_type": 1,
				"price": 150
			},
			{
				"type": "armor",
				"protection": 40,
				"armor_type": 2,
				"price": 200
			},
			{
				"type": "shield",
				"protection": 10,
				"model_key": "small",
				"price": 50
			},
			{
				"type": "shield",
				"protection": 20,
				"model_key": "large",
				"price": 100
			}
		]
	}
}

var current_shop_id: String = ""
var player_inventory: Inventory = null

func _ready() -> void:
	pass

func open_shop(shop_id: String) -> void:
	if not shops.has(shop_id):
		push_error("Shop ID not found: " + shop_id)
		return
	
	current_shop_id = shop_id
	
	# Find the player's inventory
	if get_tree().has_group("Player"):
		var player = get_tree().get_first_node_in_group("Player")
		if player != null:
			player_inventory = player.user_interface.inventory
	
	# IMPORTANT: Add a deferred call to actually show the shop panel
	# This gives time for the dialogue system to properly end
	call_deferred("_deferred_show_shop", shop_id)
	
	shop_opened.emit(shop_id)

# Add this new method to handle the deferred shop opening:
func _deferred_show_shop(shop_id: String) -> void:
	# This runs in the next frame after the dialogue system is done
	
	# Show the shop panel
	var shop_panels = get_tree().get_nodes_in_group("shop_panels")
	for panel in shop_panels:
		if panel.has_method("open_shop"):
			panel.open_shop(shop_id)
	
	# Force the mouse to be visible after a short delay
	await get_tree().create_timer(0.1).timeout
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)

func close_shop() -> void:
	current_shop_id = ""
	shop_closed.emit()

func get_shop_name(shop_id: String) -> String:
	if not shops.has(shop_id):
		return "Unknown Shop"
	return shops[shop_id].name

func get_shop_items(shop_id: String) -> Array:
	if not shops.has(shop_id):
		return []
	return shops[shop_id].items

# Following your enemy.gd pattern with preloaded models
func create_item_from_data(item_data: Dictionary) -> ItemIcon:
	var item_icon = null
	
	if item_data.type == "weapon":
		var weapon = preload("res://scenes/user_interface/weapon_icon.tscn").instantiate()
		weapon.power = item_data.power
		
		# Use the model key to get the preloaded model
		if item_data.has("model_key") and weapon_models.has(item_data.model_key):
			weapon.item_model = weapon_models[item_data.model_key]
			
		weapon.price = item_data.price
		item_icon = weapon
	
	elif item_data.type == "armor":
		var armor = preload("res://scenes/user_interface/armor_icon.tscn").instantiate()
		armor.protection = item_data.protection
		if item_data.has("armor_type"):
			armor.armor = item_data.armor_type
		armor.price = item_data.price
		item_icon = armor
	
	elif item_data.type == "shield":
		var shield = preload("res://scenes/user_interface/shield_icon.tscn").instantiate()
		shield.protection = item_data.protection
		
		# Use the model key to get the preloaded model
		if item_data.has("model_key") and shield_models.has(item_data.model_key):
			shield.item_model = shield_models[item_data.model_key]
			
		shield.price = item_data.price
		item_icon = shield
	
	elif item_data.type == "trade_good":
		var trade_good = preload("res://scenes/user_interface/trade_good_icon.tscn").instantiate()
		trade_good.good_type_enum = item_data.good_type_enum
		trade_good.quantity = item_data.quantity
		if item_data.has("custom_name"):
			trade_good.custom_name = item_data.custom_name
		# For shop items, this would be the buy price (full price)
		trade_good.price = item_data.price 
		item_icon = trade_good
	
	# Following your enemy.gd pattern for visibility
	if item_icon:
		item_icon.visible = true  # Make visible for shop display
	
	return item_icon

func buy_item(item_index: int) -> bool:
	if current_shop_id.is_empty() or player_inventory == null:
		return false
	
	var shop_items = get_shop_items(current_shop_id)
	if item_index < 0 or item_index >= shop_items.size():
		return false
	
	var item_data = shop_items[item_index]
	var price = item_data.price
	
	# Check if player has enough gold
	if player_inventory.gold < price:
		return false
	
	# Create the item using our pattern with preloaded models
	var item = create_item_from_data(item_data)
	if item == null:
		return false
	
	# Deduct gold and add item to inventory
	player_inventory.gold -= price
	player_inventory.add_item(item)
	
	return true

func sell_item(item: ItemIcon) -> bool:
	if player_inventory == null:
		return false
	
	# Handle TradeGoodIcon specially
	if item is TradeGoodIcon:
		# Get the individual item price (not the stack price)
		var base_price = 0
		match item.good_type_enum:
			TradeGoodIcon.trade_good_type.HERB: base_price = 4
			TradeGoodIcon.trade_good_type.ORE: base_price = 6
			TradeGoodIcon.trade_good_type.WOOD: base_price = 4
			TradeGoodIcon.trade_good_type.LEATHER: base_price = 4
		
		# Calculate single item sell price (half of base price)
		var single_item_sell_price = int(base_price / 2)
		
		# Add gold for one item
		player_inventory.add_currency(single_item_sell_price)
		
		# Decrease quantity
		item.quantity -= 1
		item.stat_label.text = "x" + str(item.quantity)
		
		# Update price for remaining items
		item.price = int(base_price * item.quantity) / 2
		item.price_label.text = str(item.price) + "g"
		
		# If quantity is now 0, remove the item
		if item.quantity <= 0:
			var parent = item.get_parent()
			if parent:
				parent.remove_child(item)
			item.queue_free()
		
		return true
	else:
		# For non-TradeGoodIcon items, use original logic
		var sell_price = int(item.price * 0.5)
		
		# Remove from inventory if it's equipped
		var parent = item.get_parent()
		if parent:
			parent.remove_child(item)
		
		# Add gold
		player_inventory.add_currency(sell_price)
		
		# Free the item
		item.queue_free()
		
		return true
