extends Node
class_name ControllerMouseCursor

@export var cursor_speed: float = 1000.0
@export var dead_zone: float = 0.1
@export var debug_mode: bool = true

func _ready() -> void:
	# Make sure we can process while game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if debug_mode:
		print("ControllerCursor initialized with process_mode: ", process_mode)

func _process(delta: float) -> void:
	# Only control the cursor when in UI mode
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		return
	
	# Get controller input
	var stick_x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	var stick_y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	
	# Apply dead zone
	if abs(stick_x) < dead_zone:
		stick_x = 0
	if abs(stick_y) < dead_zone:
		stick_y = 0
	
	# Calculate movement
	var movement = Vector2(stick_x, stick_y) * cursor_speed * delta
	
	# Only update if there's movement
	if movement.length() > 0:
		# Get current position and add movement
		var new_position = get_viewport().get_mouse_position() + movement
		
		# Clamp to screen boundaries
		var screen_size = get_viewport().get_visible_rect().size
		new_position.x = clamp(new_position.x, 0, screen_size.x)
		new_position.y = clamp(new_position.y, 0, screen_size.y)
		
		# Move the cursor
		get_viewport().warp_mouse(new_position)

func _unhandled_input(event: InputEvent) -> void:
	# Only handle interaction when in UI mode
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		return
	
	# Check for controller "interact" button or any UI accept action
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		if debug_mode:
			print("Interact button pressed - clicking at: ", get_viewport().get_mouse_position())
		
		# Get current mouse position
		var pos = get_viewport().get_mouse_position()
		
		# Create press event
		var click = InputEventMouseButton.new()
		click.position = pos
		click.global_position = pos
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		
		# Send to multiple places to ensure it's processed
		get_viewport().push_input(click, true)  # Force input to be processed
		
		# Brief delay
		await get_tree().create_timer(0.05).timeout
		
		# Create release event
		click.pressed = false
		get_viewport().push_input(click, true)
