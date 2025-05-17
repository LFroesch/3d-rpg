# Modified user_interface.gd

extends Control

@onready var level_label: Label = %LevelLabel
@onready var health_bar: TextureProgressBar = %HealthBar
@onready var xp_bar: TextureProgressBar = %XPBar
@onready var health_label: Label = %HealthLabel
@onready var inventory: Control = $Inventory
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interact_text: Label = %InteractText
@onready var loot_container_display: CenterContainer = $LootContainerDisplay
@onready var quest_log: Control = $QuestLog
@onready var shop_panel: Control = $ShopPanel
@onready var simple_pause_menu: CanvasLayer = $SimplePauseMenu

@export var player: Player

func _ready() -> void:
	# Connect the signal from pause menu to close other UIs
	simple_pause_menu.connect("pause_toggled", _on_pause_toggled)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_inventory"):
		if inventory.visible:
			close_menu()
		else:
			open_menu()
	if event.is_action_pressed("ui_cancel"):
		if inventory.visible:
			close_menu()
		elif shop_panel.visible:
			shop_panel.close()
		elif quest_log.visible:
			quest_log.close()
		elif loot_container_display.visible:
			loot_container_display.close()
	# The quest_log handles its own "open_quest_log" input

# Called when pause menu is toggled
func _on_pause_toggled(is_paused: bool) -> void:
	if is_paused:
		# Close other UI elements when pause menu opens
		if inventory.visible:
			inventory.visible = false
		if loot_container_display.visible:
			loot_container_display.close()
		if quest_log.visible:
			quest_log.close()
		if shop_panel.visible:
			shop_panel.close()

func update_stats_display() -> void:
	level_label.text = str(player.stats.level)
	xp_bar.max_value = player.stats.percentage_level_up_boundary()
	xp_bar.value = player.stats.xp
	inventory.update_stats()
	
func update_health() -> void:
	health_bar.max_value = player.health_component.max_health
	health_bar.value = player.health_component.current_health
	health_label.text = player.health_component.get_health_string()

func open_menu() -> void:
	# Close all other UI elements
	if loot_container_display.visible:
		loot_container_display.close()
	
	if quest_log.visible:
		quest_log.close()
		
	if shop_panel.visible:
		shop_panel.close()
	
	# Close pause menu if it's open
	if simple_pause_menu.pause_menu.visible:
		simple_pause_menu.toggle_pause_menu()
		
	inventory.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	inventory.update_gear_stats()
	
func close_menu() -> void:
	inventory.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func update_interact_text(text: String) -> void:
	animation_player.stop()
	animation_player.play("fade_out_text")
	interact_text.text = text

func open_loot_container(loot: LootContainer) -> void:
	# Close all other UI elements
	if inventory.visible:
		close_menu()
		
	if quest_log.visible:
		quest_log.close()
		
	if shop_panel.visible:
		shop_panel.close()
	
	# Close pause menu if it's open
	if simple_pause_menu.pause_menu.visible:
		simple_pause_menu.toggle_pause_menu()
	
	loot_container_display.open(loot)
