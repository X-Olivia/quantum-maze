extends Node2D


const ENERGY_REGEN: int = 10


func _physics_process(delta: float) -> void:
	for body in $PointLight2D/Area2D.get_overlapping_bodies():
		if body is Player and body is not Ghost and body.mode == Globals.Modes.PARTICLE:
			Globals.energy += ENERGY_REGEN * delta
