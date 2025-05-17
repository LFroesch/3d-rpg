extends CenterContainer
var current_container: LootContainer
@onready var grid_container: GridContainer = $PanelContainer/VBoxContainer/GridContainer
@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleTexture/TitleLabel
@export var inventory: Inventory

func _ready() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			close()

func close() -> void:
	visible = false
	get_tree().paused = false  # Unpause the game when closing
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if is_instance_valid(current_container):
		for item in grid_container.get_children():
			item.interact.disconnect(pickup_item)
			grid_container.remove_child(item)
			current_container.add_child(item)
			item.visible = false
		current_container.check_empty()
	
func open(loot: LootContainer) -> void:
	if visible:
		close()
	else:
		# Close quest log if open
		var ui = get_parent()
		if ui.has_node("QuestLog") and ui.get_node("QuestLog").visible:
			ui.get_node("QuestLog").close()
			
		if ui.inventory and ui.inventory.visible:
			ui.inventory.visible = false
			
		if ui.shop_panel and ui.shop_panel.visible:
			ui.shop_panel.close()

		if ui.simple_pause_menu.pause_menu.visible:
			ui.simple_pause_menu.toggle_pause_menu()
			
		current_container = loot
		title_label.text = loot.name.capitalize()
		for item in loot.get_items():
			current_container.remove_child(item)
			grid_container.add_child(item)
			item.visible = true
			item.interact.connect(pickup_item)
		visible = true
		get_tree().paused = true  # Pause the game when opening
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_back_button_pressed() -> void:
	close()

func pickup_item(icon: ItemIcon) -> void:
	icon.interact.disconnect(pickup_item)
	
	# Mark this item as removed
	PersistentData.remove_item(icon.item_id)
	
	if icon is CurrencyIcon:
		inventory.add_currency(icon.value)
		icon.queue_free()
	else:
		inventory.add_item(icon)

func _on_loot_all_button_pressed() -> void:
	for item in grid_container.get_children():
		pickup_item(item)
