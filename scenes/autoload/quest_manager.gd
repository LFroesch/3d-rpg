extends Node

signal quest_started(quest_id: String)
signal quest_updated(quest_id: String, progress: float)
signal quest_objectives_completed(quest_id: String)
signal quest_completed(quest_id: String)

var active_quests: Dictionary = {}
var completed_quests: Array = []
var ready_for_turnin_quests: Array = []

var quests: Dictionary = {
	"kill_bandits": {
		"title": "Bandits!",
		"description": "Kill 5 bandits in the forest to help protect the village.",
		"objectives": {
			"kill_enemy": {
				"enemy_type": "bandit",
				"count": 5,
				"current": 0
			}
		},
		"rewards": {
			"experience": 200,
			"gold": 100,
			"items": [
				{
					"type": "weapon",
					"power": 20,
					"model": "res://assets/Character/Gear/Longsword.glb"
				},
				{
					"type": "armor",
					"protection": 25,
					"armor_type": 2 # 0, 1, or 2 for different armor types as in your enemy code
				}
			]
		},
		"requires_turnin": true,
		"repeatable": true
	},
	"more_bandits": {
		"title": "Bandits 2!",
		"description": "Kill 5 bandits at the farm to help protect his crops.",
		"objectives": {
			"kill_enemy": {
				"enemy_type": "bandit2",
				"count": 5,
				"current": 0
			}
		},
		"rewards": {
			"experience": 200,
			"gold": 100,
			"items": [
				{
					"type": "weapon",
					"power": 20,
					"model": "res://assets/Character/Gear/Longsword.glb"
				},
				{
					"type": "armor",
					"protection": 25,
					"armor_type": 2 # 0, 1, or 2 for different armor types as in your enemy code
				}
			]
		},
		"requires_turnin": true,
		"repeatable": true
	},
	"gather_herbs": {
		"title": "Medicinal Herbs",
		"description": "Collect 8 healing herbs for the town healer.",
		"objectives": {
			"collect_item": {
				"item_type": "herb",
				"count": 8,
				"current": 0
			}
		},
		"rewards": {
			"experience": 100,
			"gold": 50,
			"items": []
		},
		"requires_turnin": true,
		"repeatable": true
	},
	"deliver_message": {
		"title": "Urgent Message",
		"description": "Deliver the sealed letter to the Vendor.",
		"objectives": {
			"talk_to": {
				"target": "vendor1"
			}
		},
		"rewards": {
			"experience": 100,
			"gold": 50,
			"items": [
				{
					"type": "weapon",
					"power": 7,
					"model": "res://scenes/added_weapons/claymore.tscn"
				},
				{
					"type": "armor",
					"protection": 10,
					"armor_type": 0 # 0, 1, or 2 for different armor types as in your enemy code
				}
			]
		},
		"requires_turnin": true,
		"repeatable": false
	},
	"find_fred": {
		"title": "Find Fred",
		"description": "Deliver the sealed letter to Farmer Fred. The King says his farm is somewhere through a cave outside of the village.",
		"objectives": {
			"talk_to": {
				"target": "farmerfred"
			}
		},
		"rewards": {
			"experience": 100,
			"gold": 50,
			"items": [
				{
					"type": "weapon",
					"power": 7,
					"model": "res://scenes/added_weapons/claymore.tscn"
				},
				{
					"type": "armor",
					"protection": 10,
					"armor_type": 0 # 0, 1, or 2 for different armor types as in your enemy code
				}
			]
		},
		"requires_turnin": true,
		"repeatable": false
	}
}

func _ready() -> void:
	pass

func start_quest(quest_id: String) -> void:
	if not quests.has(quest_id):
		return
	
	if completed_quests.has(quest_id):
		var quest = quests[quest_id]
		if not quest.has("repeatable") or not quest.repeatable:
			return
	
	if ready_for_turnin_quests.has(quest_id):
		return
	
	active_quests[quest_id] = quests[quest_id].duplicate(true)
	
	for objective_key in active_quests[quest_id].objectives:
		var objective = active_quests[quest_id].objectives[objective_key]
		if objective_key == "kill_enemy" or objective_key == "collect_item":
			objective.current = 0
	
	quest_started.emit(quest_id)

func record_enemy_kill(enemy_type: String) -> void:
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		for objective_key in quest.objectives:
			var objective = quest.objectives[objective_key]
			if objective_key == "kill_enemy" and objective.enemy_type == enemy_type:
				objective.current += 1
				
				var progress = float(objective.current) / float(objective.count)
				quest_updated.emit(quest_id, progress)
				
				check_quest_objectives(quest_id)

func record_item_collection(item_type: String, quantity: int = 1) -> void:
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		for objective_key in quest.objectives:
			var objective = quest.objectives[objective_key]
			if objective_key == "collect_item" and objective.item_type == item_type:
				objective.current += quantity
				
				var progress = float(objective.current) / float(objective.count)
				quest_updated.emit(quest_id, progress)
				
				check_quest_objectives(quest_id)

func record_npc_interaction(npc_id: String) -> void:
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		for objective_key in quest.objectives:
			var objective = quest.objectives[objective_key]
			if objective_key == "talk_to" and objective.target == npc_id:
				quest_updated.emit(quest_id, 1.0)
				mark_quest_ready_for_turnin(quest_id)
				print("recorded interaction with %s" % npc_id)

func check_quest_objectives(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
		
	var quest = active_quests[quest_id]
	var all_complete = true
	
	for objective_key in quest.objectives:
		var objective = quest.objectives[objective_key]
		if objective_key == "kill_enemy" or objective_key == "collect_item":
			if objective.current < objective.count:
				all_complete = false
				break
	
	if all_complete:
		mark_quest_ready_for_turnin(quest_id)

func mark_quest_ready_for_turnin(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
		
	var quest = active_quests[quest_id]
	
	if not quest.has("requires_turnin") or not quest.requires_turnin:
		complete_quest(quest_id)
		return
	
	if not ready_for_turnin_quests.has(quest_id):
		ready_for_turnin_quests.append(quest_id)
		quest_objectives_completed.emit(quest_id)

func complete_quest(quest_id: String) -> void:
	if not (active_quests.has(quest_id) or ready_for_turnin_quests.has(quest_id)):
		return
	
	var quest = active_quests.get(quest_id, quests.get(quest_id))
	
	# Remove collected items if needed
	for objective_key in quest.objectives:
		var objective = quest.objectives[objective_key]
		if objective_key == "collect_item":
			# This would be handled by your inventory system
			pass
	
	# Give rewards
	if quest.rewards.has("experience"):
		var xp_reward = quest.rewards.experience
		# Use your character XP system
		if get_tree().has_group("Player"):
			var player = get_tree().get_first_node_in_group("Player")
			if player != null:
				player.stats.xp += xp_reward
	
	if quest.rewards.has("gold"):
		var gold_amount = quest.rewards.gold
		# Use your gold system
		if get_tree().has_group("Player"):
			var player = get_tree().get_first_node_in_group("Player")
			if player != null:
				# Assuming gold is a property in the player's inventory
				player.user_interface.inventory.add_currency(gold_amount)
				
	if quest.rewards.has("items") and quest.rewards.items.size() > 0:
		if get_tree().has_group("Player"):
			var player = get_tree().get_first_node_in_group("Player")
			if player != null:
				for item_data in quest.rewards.items:
					give_item_reward(player, item_data)
					
	# Clean up quest status
	active_quests.erase(quest_id)
	if ready_for_turnin_quests.has(quest_id):
		ready_for_turnin_quests.erase(quest_id)
	
	completed_quests.append(quest_id)
	
	quest_completed.emit(quest_id)
	
	# Update quest UI if it's visible
	var quest_panels = get_tree().get_nodes_in_group("quest_panels")
	for panel in quest_panels:
		if panel.visible and panel.has_method("update_quest_display"):
			panel.update_quest_display()

func is_quest_active(quest_id: String) -> bool:
	return active_quests.has(quest_id)

func is_quest_ready_for_turnin(quest_id: String) -> bool:
	return ready_for_turnin_quests.has(quest_id)

func is_quest_completed(quest_id: String) -> bool:
	return completed_quests.has(quest_id)

func can_repeat_quest(quest_id: String) -> bool:
	if not quests.has(quest_id):
		return false
	
	if not completed_quests.has(quest_id) and not active_quests.has(quest_id) and not ready_for_turnin_quests.has(quest_id):
		return true
		
	var quest = quests[quest_id]
	
	if not quest.has("repeatable") or not quest.repeatable:
		return false

	if active_quests.has(quest_id) or ready_for_turnin_quests.has(quest_id):
		return false
	
	return true

func get_quest_progress(quest_id: String) -> float:
	if is_quest_ready_for_turnin(quest_id):
		return 1.0
		
	if not active_quests.has(quest_id):
		return 0.0
		
	var quest = active_quests[quest_id]
	var total_objectives = 0
	var completed_objective_points = 0.0
	
	for objective_key in quest.objectives:
		var objective = quest.objectives[objective_key]
		total_objectives += 1
		
		if objective_key == "talk_to":
			# Talk quests are binary - either complete or not
			completed_objective_points += 0  # Not complete by default
			
		elif objective.has("current") and objective.has("count"):
			var progress = float(objective.current) / float(objective.count)
			completed_objective_points += progress
		
	if total_objectives > 0:
		return completed_objective_points / total_objectives
	return 0.0

func get_active_quests() -> Dictionary:
	return active_quests

func get_quest(quest_id: String) -> Dictionary:
	if quests.has(quest_id):
		return quests[quest_id]
	return {}

func give_item_reward(player: Player, item_data: Dictionary) -> void:
	var item_icon: ItemIcon = null
	
	# Create the appropriate item type
	if item_data.type == "weapon":
		var weapon = preload("res://scenes/user_interface/weapon_icon.tscn").instantiate()
		weapon.power = item_data.power
		if item_data.has("model"):
			weapon.item_model = load(item_data.model)
		item_icon = weapon
	
	elif item_data.type == "armor":
		var armor = preload("res://scenes/user_interface/armor_icon.tscn").instantiate()
		armor.protection = item_data.protection
		if item_data.has("armor_type"):
			armor.armor = item_data.armor_type
		item_icon = armor
	
	elif item_data.type == "shield":
		var shield = preload("res://scenes/user_interface/shield_icon.tscn").instantiate()
		shield.protection = item_data.protection
		if item_data.has("model"):
			shield.item_model = load(item_data.model)
		item_icon = shield
	
	# Add the item to the player's inventory
	if item_icon != null:
		player.user_interface.inventory.add_item(item_icon)
