extends Area2D
class_name EnergyItem

@export var small: bool = true

var ENERGY: int = 10

func _ready() -> void:
	if small:
		scale *= 0.5
	else:
		ENERGY *= 2


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is Player and body is not Ghost and body.mode == Globals.Modes.PARTICLE:
			Globals.energy += ENERGY
			queue_free()

