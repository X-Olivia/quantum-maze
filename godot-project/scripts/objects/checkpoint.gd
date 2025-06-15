extends Area2D
class_name Checkpoint

var activated: bool = false


func _physics_process(_delta: float) -> void:
	set_physics_process(not activated)
	if activated:
		return
	
	for body in get_overlapping_bodies():
		if body is Player:
			activated = true
			Globals.level.activated_checkpoint(global_position)
			modulate = Color(1, 1, 1, 0.3)
