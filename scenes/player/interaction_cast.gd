extends ShapeCast3D
var balloon_scene = preload("res://dialogue/game_dialogue_balloon.tscn")
@export var ui: Control
@export var player: Player
var active_dialogue: BaseGameDialogueBalloon = null

func check_interactions() -> void:
	# Skip if already in dialogue
	if active_dialogue != null and is_instance_valid(active_dialogue):
		return
		
	for collision in get_collision_count():
		var collider = get_collider(collision)
		if collider is LootContainer:
			ui.update_interact_text("Loot")
			if Input.is_action_just_pressed("interact"):
				ui.open_loot_container(collider)
		if collider is Passage:
			ui.update_interact_text("Travel")
			if Input.is_action_just_pressed("interact"):
				collider.travel(player)
		if collider is King:
			ui.update_interact_text("Talk")
			if Input.is_action_just_pressed("interact"):
				start_dialogue("res://dialogue/conversations/king.dialogue", "start")
		if collider is Vendor:
			ui.update_interact_text("Shop")
			if Input.is_action_just_pressed("interact"):
				start_dialogue("res://dialogue/conversations/vendor.dialogue", "start")
		if collider is Farmer:
			ui.update_interact_text("Talk")
			if Input.is_action_just_pressed("interact"):
				start_dialogue("res://dialogue/conversations/farmer_fred.dialogue", "start")

func start_dialogue(resource_path: String, title: String) -> void:
	# Clean up existing dialogue if any
	if active_dialogue != null and is_instance_valid(active_dialogue):
		active_dialogue.queue_free()
	
	# Create new dialogue
	active_dialogue = balloon_scene.instantiate()
	get_tree().current_scene.add_child(active_dialogue)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Start dialogue
	active_dialogue.start(load(resource_path), title)
