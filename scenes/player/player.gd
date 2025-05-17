extends CharacterBody3D
class_name Player

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const DECAY := 8.0

# Stores the x/y direction the player is trying to look in
var _look := Vector2.ZERO
# Stores direction player moves when attacking
var _attack_direction := Vector3.ZERO
@export_category("Camera")
@export var player_max_health: float = 30.0
@export var mouse_sensitivity: float = 0.003
@export var min_boundary : float = -60
@export var max_boundary : float = 10
@export_category("Movement / Anim")
@export var rig_rot_interpolation_decay: float = 20.0
@export var attack_move_speed: float = 3.0
@export_category("RPG")
@export var stats : CharacterStats

@onready var horizontal_pivot: Node3D = $HorizontalPivot
@onready var vertical_pivot: Node3D = $HorizontalPivot/VerticalPivot
@onready var rig_pivot: Node3D = $RigPivot
@onready var rig: Node3D = $RigPivot/Rig

@onready var attack_cast: RayCast3D = %AttackCast
@onready var health_component: HealthComponent = $HealthComponent
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var area_attack: ShapeCast3D = $RigPivot/AreaAttack
@onready var user_interface: Control = $UserInterface
@onready var interaction_cast: ShapeCast3D = $RigPivot/InteractionCast
@onready var attack_cd_timer: Timer = $AttackCD

@onready var heal_cd: Timer = $HealCD
@onready var magic_ring: Node3D = $MagicRing
@onready var magic_ring_2: Node3D = $MagicRing2

@onready var health_regen_timer: Timer = $HealthRegenTimer
@export var health_regen_amount: float = 1.0
@export var health_regen_interval: float = 5.0

@export_file("*.tscn") var respawn_level

@export var controller_camera_sensitivity := 3.0  # Adjust to your preference
var last_input_was_controller := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_component.update_max_health(stats.get_max_hp())
	stats.level_up_notification.connect(
		func(): health_component.update_max_health(stats.get_max_hp())
	)
	stats.update_stats.connect(user_interface.update_stats_display)
	user_interface.update_stats_display()
	user_interface.inventory.armor_changed.connect(health_component.update_armor_value)
	SceneTransition.fade_in()
	if PersistentData.current_health:
		health_component.current_health = PersistentData.current_health
		
	health_regen_timer.wait_time = health_regen_interval
	health_regen_timer.one_shot = false
	health_regen_timer.connect("timeout", _on_health_regen_timer_timeout)
	health_regen_timer.start()
	
func _physics_process(delta: float) -> void:
	# Only process camera and movement when the UI is not active
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		handle_controller_camera(delta)
		frame_camera_rotation()
	
		if not is_on_floor():
			velocity += get_gravity() * delta

		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			print(global_position)

		var direction := get_movement_direction()
		rig.update_animation_tree(direction)
		handle_idle_physics_frame(delta, direction)
		handle_slashing_physics_frame(delta)
		handle_overhead_physics_frame()
		interaction_cast.check_interactions()
	else:
		# When UI is active, zero out velocity to prevent movement
		velocity = Vector3.ZERO
	
	move_and_slide()

# Add this new function to handle controller camera input
func handle_controller_camera(delta: float) -> void:
	# Get controller input (right stick)
	var joy_x = Input.get_axis("look_left", "look_right")
	var joy_y = Input.get_axis("look_up", "look_down")
	
	# Only process if we have significant input
	if abs(joy_x) > 0.1 or abs(joy_y) > 0.1:
		# Create look vector from controller input
		var controller_look = Vector2(-joy_x, -joy_y) * controller_camera_sensitivity * delta
		
		# Apply rotation using the same logic as mouse input
		horizontal_pivot.rotate_y(controller_look.x)
		vertical_pivot.rotate_x(controller_look.y)
		
		# Apply the same clamps you have for mouse input
		vertical_pivot.rotation.x = clampf(vertical_pivot.rotation.x, deg_to_rad(min_boundary), deg_to_rad(max_boundary))
		
		# Mark that we used controller
		last_input_was_controller = true

func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("exit_game"): # ~
		#get_tree().quit()
	#if event.is_action_pressed("debug_gain_xp"):
		#stats.xp += 1000
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			_look = -event.relative * mouse_sensitivity
		
		# Process controller input in unhandled_input instead of physics_process
		if event is InputEventJoypadMotion:
			if event.axis == JOY_AXIS_RIGHT_X or event.axis == JOY_AXIS_RIGHT_Y:
				last_input_was_controller = true
				
		# Only process gameplay actions when mouse is captured (not in UI)
		if rig.is_idle():
			if event.is_action_pressed("click"):
				slash_attack()
			if event.is_action_pressed("right_click"):
				rig.travel("Overhead")
			if event.is_action_pressed("middle_click"):
				cast_heal()
				
	# Let this specific interaction through even when UI is active
	if event.is_action_pressed("interact") and user_interface.loot_container_display.visible and interaction_cast.get_collision_count() == 0:
		user_interface.loot_container_display.close()
			
func get_movement_direction() -> Vector3:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var input_vector := Vector3(input_dir.x, 0, input_dir.y).normalized()
	var direction := horizontal_pivot.global_transform.basis * input_vector
	
	return direction

func frame_camera_rotation() -> void:
	horizontal_pivot.rotate_y(_look.x)
	vertical_pivot.rotate_x(_look.y)
	vertical_pivot.rotation.x = clampf(vertical_pivot.rotation.x, deg_to_rad(min_boundary), deg_to_rad(max_boundary))
	
	_look = Vector2.ZERO

func look_toward_direction(direction: Vector3, delta: float) -> void:
	var target_transform := rig_pivot.global_transform.looking_at(
		rig_pivot.global_position + direction,
		Vector3.UP,
		true
	)
	rig_pivot.global_transform = rig_pivot.global_transform.interpolate_with(
		target_transform,
		1.0 - exp(-rig_rot_interpolation_decay * delta)
	)

func slash_attack() -> void:
	if rig.is_slashing() or not attack_cd_timer.is_stopped():
		return
	
	rig.travel("Slash")
	_attack_direction = get_movement_direction()
	if _attack_direction.is_zero_approx():
		_attack_direction = rig.global_basis * Vector3(0,0,1)
	attack_cast.clear_exceptions()
	attack_cd_timer.start()

func handle_slashing_physics_frame(delta: float) -> void:
	if not rig.is_slashing():
		return
	velocity.x = _attack_direction.x * attack_move_speed
	velocity.z = _attack_direction.z * attack_move_speed
	look_toward_direction(_attack_direction, delta)
	attack_cast.deal_damage(user_interface.inventory.get_weapon_value(), stats.get_crit_chance())

func handle_idle_physics_frame(delta: float, direction: Vector3) -> void:
	if not rig.is_idle() and not rig.is_dashing():
		return
	velocity.x = exponential_decay(velocity.x, direction.x * stats.get_base_speed(), DECAY, delta)
	velocity.z = exponential_decay(velocity.z, direction.z * stats.get_base_speed(), DECAY, delta)
	if direction:
		look_toward_direction(direction, delta)

func handle_overhead_physics_frame() -> void:
	if not rig.is_overhead():
		return
	velocity.x = 0.0
	velocity.z = 0.0
	velocity.y = 0.0 if is_on_floor() else -1

func _on_health_component_defeat() -> void:
	rig.travel("Defeat")
	collision_shape_3d.disabled = true
	set_physics_process(false)
	SceneTransition.change_scene(respawn_level, self)
	
func _on_rig_heavy_attack() -> void:
	area_attack.deal_damage(user_interface.inventory.get_weapon_value(), stats.get_crit_chance())

func exponential_decay(a: float, b: float, decay: float, delta: float) -> float:
	return b + (a - b) * exp(-decay * delta)

func cast_heal() -> void:
	if not heal_cd.is_stopped():
		return
	health_component.take_healing(10)
	magic_ring_2.visible = true
	heal_cd.start()
	var visibility_timer = Timer.new()
	add_child(visibility_timer)
	visibility_timer.wait_time = 2.0
	visibility_timer.one_shot = true
	visibility_timer.start()
	await visibility_timer.timeout
	magic_ring_2.visible = false
	visibility_timer.queue_free()

# Function that gets called every health_regen_interval seconds
func _on_health_regen_timer_timeout() -> void:
	# Only regenerate health if player is alive and not at max health
	if health_component.current_health > 0 and health_component.current_health < health_component.max_health:
		health_component.current_health += 1
