# loot_indicator.gd
extends Node3D

@export var rotation_speed: float = 1.0
@export var bob_height: float = 0.1
@export var bob_speed: float = 2.0

var time_passed: float = 0.0
var original_y: float = 0.0

func _ready():
	original_y = position.y

func _process(delta):
	# Rotate the indicator
	rotate_y(rotation_speed * delta)
	
	# Make it bob up and down
	time_passed += delta
	position.y = original_y + sin(time_passed * bob_speed) * bob_height
