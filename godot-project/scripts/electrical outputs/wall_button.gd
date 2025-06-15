extends Node2D

var wires: Array[Wire] = []

var player: CharacterBody2D = null

var powering: bool = false


func _physics_process(_delta: float) -> void:
	
	var was_player: CharacterBody2D = player
	player = null
	for body in $Collision.get_overlapping_bodies():
		if body is Player and body.mode == Globals.Modes.PARTICLE:
			player = body
	
	# Pressed
	if not was_player and player:
		if not powering:
			powering = true
			$Button.scale.y = 0.35
			for wire in wires:
				wire.power()
	# Released
	elif was_player and not player:
		$Timer.start()


func _on_timer_timeout() -> void:
	if not player:
		powering = false
		$Button.scale.y = 1
		for wire in wires:
			wire.unpower()
