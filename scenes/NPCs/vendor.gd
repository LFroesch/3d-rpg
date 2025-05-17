extends CharacterBody3D
class_name Vendor

@export_group("Quest")
@export var vendor_id : String


func _on_player_interaction_area_body_entered(body: Node3D) -> void:
	QuestManager.record_npc_interaction(vendor_id)
