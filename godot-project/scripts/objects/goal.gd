extends Area2D

@export var rotation_speed: float = -0.03

func _process(delta: float) -> void:
	$Goal.rotation += rotation_speed * delta * TAU

func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is Player and body.mode == Globals.Modes.PARTICLE:
			Globals.player_frozen = true
			
			if Globals.game_manager and Globals.game_manager.current_level:						
				if Globals.game_manager.current_level.name == "level4":
					Globals.game_manager.play_level4_ending()
				else:
					Globals.game_manager.play_goal_transition()
			
			set_physics_process(false)
			return
