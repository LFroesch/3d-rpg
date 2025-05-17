extends Control
class_name QuestLog

@onready var quest_container = $MarginContainer/VBoxContainer/HBoxContainer/QuestListPanel/ScrollContainer/QuestContainer
@onready var quest_details_text = $MarginContainer/VBoxContainer/HBoxContainer/QuestDetailsPanel/ScrollContainer/MarginContainer/QuestDetailsText

func _ready() -> void:
	visible = false
	QuestManager.quest_started.connect(_on_quest_changed)
	QuestManager.quest_updated.connect(_on_quest_progress)
	QuestManager.quest_objectives_completed.connect(_on_quest_changed)
	QuestManager.quest_completed.connect(_on_quest_changed)
	
	# Add to quest_panels group for auto-updating
	add_to_group("quest_panels")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_quest_log"):
		if visible:
			close()
		else:
			open()
	if event.is_action_pressed("ui_cancel"):
		if visible:
			close()

func open() -> void:
	var ui = get_parent()
	
	# Close other UI elements
	if ui.loot_container_display.visible:
		ui.loot_container_display.close()
	
	if ui.inventory.visible:
		ui.inventory.visible = false
		get_tree().paused = false
	
	if ui.simple_pause_menu.pause_menu.visible:
		ui.simple_pause_menu.toggle_pause_menu()
		
	if ui.shop_panel.visible:
		ui.shop_panel.close()
	
	update_quest_display()
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_back_button_pressed() -> void:
	close()

func update_quest_display() -> void:
	# Clear existing quests
	for child in quest_container.get_children():
		quest_container.remove_child(child)
		child.queue_free()
	
	# Get active quests
	var active_quests = QuestManager.get_active_quests()
	
	if active_quests.size() == 0:
		var no_quests_label = Label.new()
		no_quests_label.text = "You don't have any active quests."
		no_quests_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_quests_label.add_theme_font_size_override("font_size", 20)
		quest_container.add_child(no_quests_label)
		quest_details_text.text = ""
		return
	
	# Create quest entries
	var first_quest_id = null
	
	# Process quests ready for turn-in first
	for quest_id in QuestManager.ready_for_turnin_quests:
		if active_quests.has(quest_id):
			if not first_quest_id:
				first_quest_id = quest_id
			
			var quest_button = Button.new()
			quest_button.text = active_quests[quest_id].title + " (Ready to Turn In)"
			quest_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			quest_button.pressed.connect(_on_quest_entry_pressed.bind(quest_id))
			quest_button.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
			quest_button.add_theme_font_size_override("font_size", 20)
			quest_button.focus_mode = Control.FOCUS_NONE
			
			quest_container.add_child(quest_button)
	
	# Then process normal active quests
	for quest_id in active_quests:
		if QuestManager.ready_for_turnin_quests.has(quest_id):
			continue
		
		if not first_quest_id:
			first_quest_id = quest_id
		
		var quest_button = Button.new()
		quest_button.text = active_quests[quest_id].title
		quest_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		quest_button.pressed.connect(_on_quest_entry_pressed.bind(quest_id))
		quest_button.add_theme_font_size_override("font_size", 20)
		quest_button.focus_mode = Control.FOCUS_NONE
		
		quest_container.add_child(quest_button)
	
	# Select first quest by default if any are available
	if first_quest_id:
		_on_quest_entry_pressed(first_quest_id)

func _on_quest_entry_pressed(quest_id: String) -> void:
	# Update selected quest visual
	for child in quest_container.get_children():
		if child is Button:
			child.add_theme_color_override("font_color", Color.WHITE)
	
	for child in quest_container.get_children():
		if child is Button and child.text.begins_with(QuestManager.active_quests[quest_id].title):
			child.add_theme_color_override("font_color", Color(0.96, 0.72, 0.42))
	
	# Update quest details
	update_quest_details(quest_id)

func update_quest_details(quest_id: String) -> void:
	var quest = QuestManager.active_quests[quest_id]
	
	var is_ready_for_turnin = QuestManager.ready_for_turnin_quests.has(quest_id)
	# Changed from [center] to left alignment
	var details = "[color=#F5B76C][b]%s[/b][/color]\n\n" % quest.title
	
	details += "[b]Description:[/b]\n%s\n\n" % quest.description
	
	# Format objectives
	details += "[b]Objectives:[/b]\n"
	for objective_key in quest.objectives:
		var objective = quest.objectives[objective_key]
		
		if objective_key == "kill_enemy":
			var enemy_name = objective.enemy_type.capitalize()
			details += "• Kill %d %s: %d/%d" % [objective.count, enemy_name, objective.current, objective.count]
			
			if is_ready_for_turnin:
				details += " [color=#7CFC00](Complete)[/color]"
			details += "\n"
			
		elif objective_key == "collect_item":
			var item_name = objective.item_type.capitalize()
			details += "• Collect %d %s: %d/%d" % [objective.count, item_name, objective.current, objective.count]
			
			if is_ready_for_turnin:
				details += " [color=#7CFC00](Complete)[/color]"
			details += "\n"
			
		elif objective_key == "talk_to":
			var npc_name = objective.target.capitalize().replace("_", " ")
			details += "• Talk to %s" % npc_name
			
			if is_ready_for_turnin:
				details += " [color=#7CFC00](Complete)[/color]"
			details += "\n"
	
	details += "\n[b]Rewards:[/b]\n"
	
	# Format rewards
	var rewards = quest.rewards
	if rewards.has("experience"):
		details += "• %d XP\n" % rewards.experience
	
	if rewards.has("gold"):
		details += "• %d Gold\n" % rewards.gold
	
	if rewards.has("items") and rewards.items.size() > 0:
		for item in rewards.items:
			# Use type instead of item_id
			if item.has("type"):
				var item_name = item.type.capitalize()
				
				# Add additional details based on item type
				if item.type == "weapon" and item.has("power"):
					item_name += " (Power: %d)" % item.power
				elif (item.type == "armor" or item.type == "shield") and item.has("protection"):
					item_name += " (Protection: %d)" % item.protection
				
				# Since your items don't have a count property, default to 1
				var count = item.get("count", 1)
				details += "• %s x%d\n" % [item_name, count]
			
	quest_details_text.text = details

func _on_quest_changed(_quest_id: String) -> void:
	if visible:
		update_quest_display()

func _on_quest_progress(quest_id: String, _progress: float) -> void:
	if visible:
		# Check if this quest is currently displayed in details panel
		var is_current = false
		for child in quest_container.get_children():
			if child is Button and child.get_theme_color("font_color", "Button") == Color(0.96, 0.72, 0.42):
				if child.text.begins_with(QuestManager.active_quests[quest_id].title):
					is_current = true
					break
		
		if is_current:
			update_quest_details(quest_id)
		
		# Update the list anyway
		update_quest_display()
