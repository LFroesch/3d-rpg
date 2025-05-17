# Modified simpe_pause_menu.gd

extends CanvasLayer

signal pause_toggled(is_paused: bool)

@onready var pause_menu = $PauseMenu
@onready var settings_menu = $SettingsMenu
var confirmation_dialog: ConfirmationDialog

func _ready():
	pause_menu.visible = false
	settings_menu.visible = false

func _input(event):
	if event.is_action_pressed("pause_menu"):
		# Close other menus first
		var ui = get_parent()
		
		if ui.inventory and ui.inventory.visible:
			ui.close_menu()
			
		if ui.loot_container_display and ui.loot_container_display.visible:
			ui.loot_container_display.close()
			
		if ui.quest_log and ui.quest_log.visible:
			ui.quest_log.close()
			
		if ui.shop_panel and ui.shop_panel.visible:
			ui.shop_panel.close()
		
		# Then toggle pause menu
		toggle_pause_menu()
		settings_menu.visible = false

func toggle_pause_menu():
	pause_menu.visible = !pause_menu.visible
	
	get_tree().paused = pause_menu.visible
	
	if pause_menu.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Emit signal to notify other UI elements
	pause_toggled.emit(pause_menu.visible)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
	
func _on_resume_button_pressed() -> void:
	toggle_pause_menu()

func _on_settings_button_pressed() -> void:
	settings_menu.visible = true

func _on_back_button_pressed() -> void:
	settings_menu.visible = false

func _on_unstuck_button_pressed() -> void:
	get_tree().paused = false
	toggle_pause_menu()

func _on_update_button_pressed() -> void:
	OS.shell_open("https://lfroesch.itch.io")
