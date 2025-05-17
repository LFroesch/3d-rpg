extends Node3D

const DAMAGE_NUMBER = preload("res://scenes/player/damage_number.tscn")

func spawn_damage_number(damage: int, color: Color, position: Vector3, character_type: int) -> void:
	var new_number = DAMAGE_NUMBER.instantiate()
	if character_type == 2:
		new_number.setup(damage, color, position)
		add_child(new_number)
	if character_type == 1:
		new_number.setup(damage, Color("f5b76c"), position)
		add_child(new_number)

func spawn_healing_number(healing: int, color: Color, position: Vector3, character_type: int) -> void:
	var new_number = DAMAGE_NUMBER.instantiate()
	if character_type == 1:
		new_number.setup(healing, color, position)
		add_child(new_number)
