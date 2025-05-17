extends Node
class_name HealthComponent

signal defeat()
signal health_changed()

@export var body: PhysicsBody3D
@export var character_type: int # 0 Vital NPC, 1 Player, 2 Enemy, 3 Killable NPC?

var max_health: float
var current_health: float:
	set(value):
		current_health = clamp(value, 0.0, max_health)
		if current_health == 0.0:
			defeat.emit()
		health_changed.emit()

var armor_value := 0.0

func update_max_health(max_hp_in: float) -> void:
	max_health = max_hp_in
	current_health = max_health
	
func take_damage(damage_in: float, is_critical: bool) -> void:
	var damage = damage_in
	var damage_blocked = damage * armor_value
	damage = damage - damage_blocked
	var color = Color.WHITE
	if is_critical:
		damage *= 2.0
		color = Color.RED
	current_health -= damage
	VfxManager.spawn_damage_number(damage, color, body.global_position, character_type)

func take_healing(healing_in: float) -> void:
	var color = Color.GREEN
	current_health += healing_in
	VfxManager.spawn_healing_number(healing_in, color, body.global_position, character_type)

func get_health_string() -> String:
	return "%s/%s" % [int(current_health), int(max_health)]

func update_armor_value(armor_in: float) -> void:
	armor_value = armor_in / 100.0
