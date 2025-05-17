extends CanvasLayer

@onready var fader: ColorRect = $Fader
var transition_in_progress := false

func _ready() -> void:
	fade_in()

func fade_in() -> void:
	var tween = create_tween()
	tween.tween_interval(0.1)
	tween.tween_property(fader, "color:a", 0.0, 1.0).from(1.0)

func change_scene(next_level: String, player: Player) -> void:
	# Prevent double transitions
	if transition_in_progress:
		print("Scene transition already in progress, ignoring new request")
		return
		
	transition_in_progress = true
	print("Starting scene change to ", next_level)
	print("Player object: ", player)
	print("Player has user_interface: ", player.has_method("get_user_interface") or player.get("user_interface") != null)
	
	var tween = create_tween()
	tween.tween_property(fader, "color:a", 1.0, 1.0)
	tween.tween_interval(0.1)
	tween.tween_callback(
		func():
			print("Before caching gear")
			if is_instance_valid(player) and player.get("user_interface") != null:
				PersistentData.cache_gear(player)
				PersistentData.cache_player_data(player)
			else:
				print("ERROR: Player invalid at cache time!")
			get_tree().change_scene_to_file(next_level)
			# Reset the lock in the next frame after scene change
			call_deferred("_reset_transition_lock")
	)

# Add this new method:
func _reset_transition_lock() -> void:
	transition_in_progress = false
