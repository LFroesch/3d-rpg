extends Control
class_name Inventory

const MIN_ARMOR_RATING := 0.0
const MAX_ARMOR_RATING := 80.0

signal armor_changed(protection: float)

@onready var level_label: Label = %LevelLabel
@onready var strength_value: Label = %StrengthValue
@onready var agility_value: Label = %AgilityValue
@onready var endurance_value: Label = %EnduranceValue
@onready var speed_value: Label = %SpeedValue
@onready var attack_value: Label = %AttackValue
@onready var armor_value: Label = %ArmorValue

@onready var weapon_slot: CenterContainer = %WeaponSlot
@onready var shield_slot: CenterContainer = %ShieldSlot
@onready var armor_slot: CenterContainer = %ArmorSlot

@onready var player: Player = get_parent().player
@onready var item_grid: GridContainer = %ItemGrid

@onready var gold := 0:
	set(value):
		gold = value
		gold_label.text = str(value) + "g"
@onready var gold_label: Label = %GoldLabel

func _ready() -> void:
	update_stats()
	update_gear_stats()
	load_items_from_persistent_data()

func update_stats() -> void:
	strength_value.text = str(player.stats.strength.ability_score)
	agility_value.text = str(player.stats.agility.ability_score)
	endurance_value.text = str(player.stats.endurance.ability_score)
	speed_value.text = str(player.stats.speed.ability_score)
	level_label.text = "Level %s" % player.stats.level

func update_gear_stats() -> void:
	attack_value.text = str(get_weapon_value())
	armor_value.text = str(get_armor_value())
	armor_changed.emit(get_armor_value())

func get_weapon_value() -> int:
	var damage = 0
	if get_weapon():
		damage += get_weapon().power
	damage += player.stats.get_damage_modifier()
	return damage

func _on_back_button_pressed() -> void:
	get_parent().close_menu()

func add_item(icon: ItemIcon) -> void:
	for connection in icon.interact.get_connections():
		icon.interact.disconnect(connection.callable)
	var parent = icon.get_parent()
	if parent:
		parent.remove_child(icon)
	item_grid.add_child(icon)
	icon.interact.connect(interact)

func add_currency(currency_in: int) -> void:
	gold += currency_in

func equip_item(item: ItemIcon, item_slot: CenterContainer) -> void:
	for child in item_slot.get_children():
		add_item(child)
	item.get_parent().remove_child(item)
	item_slot.add_child(item)

func interact(item: ItemIcon) -> void:
	if item is WeaponIcon:
		equip_item(item, weapon_slot)
		get_tree().call_group("PlayerRig","replace_weapon", item.item_model)
	if item is ArmorIcon:
		equip_item(item, armor_slot)
		get_tree().call_group("PlayerRig","replace_armor", item.armor)
	if item is ShieldIcon:
		equip_item(item, shield_slot)
		get_tree().call_group("PlayerRig","replace_shield", item.item_model)
	update_gear_stats()

func get_weapon() -> WeaponIcon:
	if weapon_slot.get_child_count() != 1:
		return null
	return weapon_slot.get_child(0)

func get_shield() -> ShieldIcon:
	if shield_slot.get_child_count() != 1:
		return null
	return shield_slot.get_child(0)
	
func get_armor() -> ArmorIcon:
	if armor_slot.get_child_count() != 1:
		return null
	return armor_slot.get_child(0)

func get_armor_value() -> float:
	var armor := 0.0
	if get_armor():
		armor += get_armor().protection
	if get_shield():
		armor += get_shield().protection
	armor = clampf(armor, MIN_ARMOR_RATING, MAX_ARMOR_RATING)
	return armor

func load_items_from_persistent_data() -> void:
	for item in PersistentData.get_inventory():
		add_item(item)
	for item in PersistentData.get_equipped_items():
		add_item(item)
		interact(item)
	gold = PersistentData.gold
	
