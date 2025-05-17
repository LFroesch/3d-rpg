extends Control
class_name ShopPanel

signal transaction_completed

@onready var shop_name_label: Label = %ShopNameLabel
@onready var buy_container: GridContainer = %BuyContainer
@onready var sell_container: GridContainer = %SellContainer
@onready var player_gold_label: Label = %PlayerGoldLabel

@export var inventory: Inventory
var current_shop_id: String = ""
var shop_items = []

func _ready() -> void:
	visible = false
	add_to_group("shop_panels")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			close()

func open_shop(shop_id: String) -> void:
	# Get parent UI reference
	var ui = get_parent()
	
	# Close other UI elements
	if ui.loot_container_display and ui.loot_container_display.visible:
		ui.loot_container_display.close()
	
	if ui.inventory and ui.inventory.visible:
		ui.close_menu()
		
	if ui.quest_log and ui.quest_log.visible:
		ui.quest_log.close()
		
	if ui.simple_pause_menu.pause_menu.visible:
		ui.simple_pause_menu.toggle_pause_menu()
	
	current_shop_id = shop_id
	update_shop_display()
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Clean up any temporary items
	for item in shop_items:
		if is_instance_valid(item):
			item.queue_free()
	shop_items.clear()
	
	ShopManager.close_shop()

func _on_back_button_pressed() -> void:
	close()

func update_shop_display() -> void:
	if current_shop_id.is_empty():
		return
	
	# Update shop name
	shop_name_label.text = "Shop of " + ShopManager.get_shop_name(current_shop_id)
	
	# Update player gold
	if inventory:
		player_gold_label.text = str(inventory.gold) + "g"
	
	# Clear existing items
	for child in buy_container.get_children():
		buy_container.remove_child(child)
		child.queue_free()
	
	for child in sell_container.get_children():
		sell_container.remove_child(child)
		child.queue_free()
	
	# Clear old shop items
	for item in shop_items:
		if is_instance_valid(item):
			item.queue_free()
	shop_items.clear()
	
	# Add shop items to buy section
	var shop_item_data = ShopManager.get_shop_items(current_shop_id)
	for i in range(shop_item_data.size()):
		var item_data = shop_item_data[i]
		
		# Create display item
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Create the actual item for display
		var display_item = ShopManager.create_item_from_data(item_data)
		if display_item:
			shop_items.append(display_item)  # Track for cleanup
			vbox.add_child(display_item)
			
			# Add item description
			var desc_label = Label.new()
			if item_data.type == "weapon":
				desc_label.text = "Power: " + str(item_data.power)
			elif item_data.type == "armor" or item_data.type == "shield":
				desc_label.text = "Protection: " + str(item_data.protection)
			elif item_data.type == "trade_good":
				desc_label.text = "Quantity: " + str(item_data.quantity)
			desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(desc_label)
			
			# Create price label
			var price_label = Label.new()
			price_label.text = str(item_data.price) + "g"
			price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(price_label)
			
			# Connect buy button
			var buy_button = Button.new()
			buy_button.text = "Buy"
			buy_button.pressed.connect(_on_buy_item_pressed.bind(i))
			vbox.add_child(buy_button)
			
			buy_container.add_child(vbox)
	
	# Add player inventory items to sell section
	if inventory and inventory.item_grid:
		for i in range(inventory.item_grid.get_child_count()):
			var item = inventory.item_grid.get_child(i)
			if item is ItemIcon:
				# Create container
				var vbox = VBoxContainer.new()
				vbox.alignment = BoxContainer.ALIGNMENT_CENTER
				
				# FIXED: Instantiate the correct icon type based on the original item
				var sell_icon = null
				
				if item is WeaponIcon:
					# Create a new WeaponIcon instance for display
					sell_icon = preload("res://scenes/user_interface/weapon_icon.tscn").instantiate()
					sell_icon.power = item.power
					if item.has_method("get_item_model") and item.get_item_model():
						sell_icon.item_model = item.get_item_model()
					elif item.get("item_model"):
						sell_icon.item_model = item.item_model
				elif item is ArmorIcon:
					# Create a new ArmorIcon instance for display
					sell_icon = preload("res://scenes/user_interface/armor_icon.tscn").instantiate()
					sell_icon.protection = item.protection
					if item.has_method("get_armor") and item.get_armor():
						sell_icon.armor = item.get_armor()
					elif item.get("armor"):
						sell_icon.armor = item.armor
				elif item is ShieldIcon:
					# Create a new ShieldIcon instance for display
					sell_icon = preload("res://scenes/user_interface/shield_icon.tscn").instantiate()
					sell_icon.protection = item.protection
					if item.has_method("get_item_model") and item.get_item_model():
						sell_icon.item_model = item.get_item_model()
					elif item.get("item_model"):
						sell_icon.item_model = item.item_model
				elif item is TradeGoodIcon:
					# Create a new TradeGoodIcon instance for display
					sell_icon = preload("res://scenes/user_interface/trade_good_icon.tscn").instantiate()
					sell_icon.good_type_enum = item.good_type_enum
					sell_icon.quantity = item.quantity
					sell_icon.custom_name = item.custom_name
						
				# Add the icon to the container if created
				if sell_icon:
					sell_icon.visible = true
					shop_items.append(sell_icon)  # Track for cleanup
					vbox.add_child(sell_icon)
				
				# Add description
				var desc_label = Label.new()
				if item is WeaponIcon:
					desc_label.text = "Power: " + str(item.power)
				elif item is ArmorIcon or item is ShieldIcon:
					desc_label.text = "Protection: " + str(item.protection)
				elif item is TradeGoodIcon:
					desc_label.text = "Quantity: " + str(item.quantity)
				desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				vbox.add_child(desc_label)
				
				# Create price label with correct price calculation
				var sell_price = 0
				if item is TradeGoodIcon:
					# For TradeGoodIcons, calculate the sell price of a SINGLE item
					var base_price = 0
					match item.good_type_enum:
						TradeGoodIcon.trade_good_type.HERB: base_price = 4
						TradeGoodIcon.trade_good_type.ORE: base_price = 6
						TradeGoodIcon.trade_good_type.WOOD: base_price = 4
						TradeGoodIcon.trade_good_type.LEATHER: base_price = 4
					sell_price = int(base_price / 2)  # Sell price of ONE item
				else:
					# For other items, use 50% of buy price
					sell_price = int(item.price * 0.5) if item.get("price") != null else 0
				
				var price_label = Label.new()
				
				# For TradeGoodIcons, show price per item and total
				if item is TradeGoodIcon and item.quantity > 1:
					price_label.text = str(sell_price) + "g each (" + str(sell_price * item.quantity) + "g total)"
				else:
					price_label.text = str(sell_price) + "g"
					
				price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				vbox.add_child(price_label)
				
				# Connect sell button
				var sell_button = Button.new()
				sell_button.text = "Sell 1"
				sell_button.pressed.connect(_on_sell_item_pressed.bind(i))
				vbox.add_child(sell_button)
				
				# Add Sell All button for trade goods with quantity > 1
				if item is TradeGoodIcon and item.quantity > 1:
					var sell_all_button = Button.new()
					sell_all_button.text = "Sell All"
					sell_all_button.pressed.connect(_on_sell_all_pressed.bind(i))
					vbox.add_child(sell_all_button)
				
				sell_container.add_child(vbox)

# Add a new function to handle selling all items at once
func _on_sell_all_pressed(item_index: int) -> void:
	if inventory and inventory.item_grid and item_index < inventory.item_grid.get_child_count():
		var item = inventory.item_grid.get_child(item_index)
		if item is TradeGoodIcon:
			# Sell all at once
			var base_price = 0
			match item.good_type_enum:
				TradeGoodIcon.trade_good_type.HERB: base_price = 4
				TradeGoodIcon.trade_good_type.ORE: base_price = 6
				TradeGoodIcon.trade_good_type.WOOD: base_price = 4
				TradeGoodIcon.trade_good_type.LEATHER: base_price = 4
			
			# Calculate total sell price (half of base price * quantity)
			var total_sell_price = int(base_price / 2) * item.quantity
			
			# Add gold for all items
			inventory.add_currency(total_sell_price)
			
			# Remove the item
			var parent = item.get_parent()
			if parent:
				parent.remove_child(item)
			item.queue_free()
			
			transaction_completed.emit()
			update_shop_display()

func _on_buy_item_pressed(item_index: int) -> void:
	if ShopManager.buy_item(item_index):
		transaction_completed.emit()
		update_shop_display()

func _on_sell_item_pressed(item_index: int) -> void:
	if inventory and inventory.item_grid and item_index < inventory.item_grid.get_child_count():
		var item = inventory.item_grid.get_child(item_index)
		if item is ItemIcon:
			if ShopManager.sell_item(item):
				transaction_completed.emit()
				update_shop_display()
