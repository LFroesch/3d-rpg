extends CharacterBody3D
class_name Farmer

@export_group("Quest")
@export var farmer_id : String

func _on_player_interaction_area_body_entered(body: Node3D) -> void:
	QuestManager.record_npc_interaction(farmer_id)
