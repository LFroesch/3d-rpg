extends Node3D

@export var speed_multiplier := 4.0
@export var player: Player
var direction := Vector3.ZERO
@onready var timer: Timer = $Timer
@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D

var dash_duration := 0.1
var time_remaining := 0.0

func _unhandled_input(event: InputEvent) -> void:
	if not timer.is_stopped():
		return
	if not player.is_physics_processing():
		return
	# could cause issues potentially
	if not player.rig.is_idle():
		return
	if event.is_action_pressed("dash"):
		direction = player.get_movement_direction()
		if not direction.is_zero_approx():
			gpu_particles_3d.emitting = true
			player.rig.travel("Dash")
			var cooldown = player.stats.get_dash_cooldown()
			timer.start(cooldown)
			time_remaining = dash_duration

func _physics_process(delta: float) -> void:
	if direction.is_zero_approx():
		return
	player.velocity = direction * player.stats.get_base_speed() * speed_multiplier
	time_remaining -= delta
	if time_remaining <= 0:
		direction = Vector3.ZERO
		gpu_particles_3d.emitting = false
