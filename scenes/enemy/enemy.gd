extends CharacterBody3D
class_name Enemy

@export_group("Quest")
@export var type : String

@export_group("Loot")
@export var drop_chance: float = 0.9 # Chance to drop any loot
@export var currency_chance: float = 0.7 # Chance to drop currency
@export var weapon_chance: float = 0.3 # Chance to drop weapon
@export var armor_chance: float = 0.2 # Chance to drop armor
@export var shield_chance: float = 0.2 # Chance to drop shield
@export var min_currency_value: int = 5 # Minimum gold dropped
@export var max_currency_value: int = 25 # Maximum gold dropped
@export var min_item_power: int = 5 # Minimum item power/protection
@export var max_item_power: int = 15 # Maximum item power/protection

@export_group("ETC")
const RUN_VELOCITY_THRESHOLD := 2.0
@export var RUN_SPEED := 5.0
@export var DETECTION_RADIUS := 5.0
var has_detected_player := false

@export var shields: Array[PackedScene]
@export var weapons: Array[PackedScene]

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@export var xp_value: int = 25
@export var crit_rate: float = 0.05
@export var max_health: float = 20.0
@onready var rig: Node3D = $Rig
@onready var health_component: HealthComponent = $HealthComponent
@onready var player_detector: ShapeCast3D = $Rig/PlayerDetector
@onready var area_attack: ShapeCast3D = $Rig/AreaAttack
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

@onready var player : Player = get_tree().get_first_node_in_group("Player")
@onready var health_bar: HealthBar3D = $HealthBar3D

var loot_container = null

func _ready() -> void:
	rig.set_active_mesh(
		rig.villager_meshes.pick_random()
	)
	rig.replace_shield(shields.pick_random())
	rig.replace_weapon(weapons.pick_random())
	health_component.update_max_health(max_health)
	rig.run_weight_target = -1.0
	health_bar.health_component = health_component
	health_bar.visible = false

func _physics_process(delta: float) -> void:
	var velocity_target := Vector3.ZERO

	if not has_detected_player:
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player <= DETECTION_RADIUS:
			has_detected_player = true
			health_bar.visible = true
	
	if has_detected_player:
		navigation_agent_3d.target_position = player.global_position
	
	if not is_on_floor():
		velocity_target += get_gravity() * delta
	
	if rig.is_idle():
		check_for_attacks()
		
		if has_detected_player and not navigation_agent_3d.is_target_reached():
			velocity_target = get_local_navigation_direction() * RUN_SPEED
			orient_rig(navigation_agent_3d.get_next_path_position())
		else:
			rig.run_weight_target = -1.0
	
	navigation_agent_3d.velocity = velocity_target
	
func check_for_attacks() -> void:
	for collision_id in player_detector.get_collision_count():
		var collider = player_detector.get_collider(collision_id)
		if collider is Player:
			rig.travel("Overhead")
			navigation_agent_3d.avoidance_mask = 0
	
func _on_health_component_defeat() -> void:
	player.stats.xp += xp_value
	rig.travel("Defeat")
	collision_shape_3d.disabled = true
	set_physics_process(false)
	navigation_agent_3d.target_position = global_position
	navigation_agent_3d.velocity = Vector3.ZERO
	health_bar.visible = false
	create_loot_container()
	if not type.is_empty():
		QuestManager.record_enemy_kill(type)
	
func _on_rig_heavy_attack() -> void:
	area_attack.deal_damage(10.0, crit_rate)
	navigation_agent_3d.avoidance_mask = 1

func orient_rig(target_position: Vector3) -> void:
	target_position.y = rig.global_position.y # ? Maybe not lol
	if rig.global_position.is_equal_approx(target_position):
		return
	rig.look_at(target_position, Vector3.UP, true)

func get_local_navigation_direction() -> Vector3:
	var destination = navigation_agent_3d.get_next_path_position()
	var local_destination = destination - global_position
	return local_destination.normalized()

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	if safe_velocity.length() > RUN_VELOCITY_THRESHOLD and has_detected_player:
		rig.run_weight_target = 1.0
	else:
		rig.run_weight_target = -1.0
	velocity = safe_velocity
	move_and_slide()

func create_loot_container() -> void:
	if randf() > drop_chance:
		return

	var loot_scene = preload("res://scenes/interactable/enemy_loot_drop.tscn")
	loot_container = loot_scene.instantiate()

	loot_container.position = Vector3(0, -0.5, 0)

	loot_container.chest_id = "enemy_loot_%d_%d_%d" % [
		round(global_position.x), 
		round(global_position.y), 
		round(global_position.z)
	]

	add_child(loot_container)
	
	generate_loot()
	
	await get_tree().process_frame
	loot_container.check_empty()

func generate_loot() -> void:
	if randf() < currency_chance:
		var currency = preload("res://scenes/user_interface/currency_icon.tscn").instantiate()
		currency.value = randi_range(min_currency_value, max_currency_value)
		currency.visible = false
		loot_container.add_child(currency)
	
	if randf() < weapon_chance:
		var weapon = preload("res://scenes/user_interface/weapon_icon.tscn").instantiate()
		weapon.power = randi_range(min_item_power, max_item_power)
		if weapons.size() > 0:
			weapon.item_model = weapons.pick_random()
		weapon.visible = false
		loot_container.add_child(weapon)
	
	if randf() < shield_chance:
		var shield = preload("res://scenes/user_interface/shield_icon.tscn").instantiate()
		shield.protection = randi_range(min_item_power, max_item_power)

		if shields.size() > 0:
			shield.item_model = shields.pick_random()
		shield.visible = false
		loot_container.add_child(shield)

	if randf() < armor_chance:
		var armor = preload("res://scenes/user_interface/armor_icon.tscn").instantiate()
		armor.protection = randi_range(min_item_power, max_item_power)
		armor.armor = randi() % 3 # 0 or 1 for different armor types
		armor.visible = false
		loot_container.add_child(armor)
