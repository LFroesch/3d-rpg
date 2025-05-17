extends Node3D
class_name HealthBar3D

@export var health_component: HealthComponent

@onready var health_bar: ProgressBar = $SubViewport/HealthBar

func _ready() -> void:
	await get_tree().process_frame
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		_update_health_display()

func _update_health_display() -> void:
	if health_component:
		health_bar.max_value = health_component.max_health
		health_bar.value = health_component.current_health

func _on_health_changed() -> void:
	_update_health_display()
