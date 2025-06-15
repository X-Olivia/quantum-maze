extends Node2D
class_name HeavyButton

var wires: Array[Wire] = []

const min_activation_speed: float = 1500

var pressed: bool = false


func press(presser) -> void:
	if pressed or presser is not Player:
		return
	
	var vel = presser.previous_velocity
	var dot = Vector2.DOWN.rotated(global_rotation).dot(vel.normalized())
	var len2 = vel.length_squared()
	
	if dot >= cos(deg_to_rad(45)) and len2 > min_activation_speed ** 2:
		# Pressed
		pressed = true
		$Button.scale.y = 0.35
		for wire in wires:
			wire.power()
		Signals.update_navigation()
