extends Node2D


## Only 1 incoming connection required to activate if true (OR), else all required (AND)
@export var OR: bool = false

## The current number of powering connections
var energy: int = 0

## The number of powering connections required to activate
var connections_required: int = 0

const open_close_duration: float = 0.5


func on_connection() -> void:
	if OR:
		connections_required = 1
	else:
		connections_required += 1


func power() -> void:
	energy += 1
	if energy == connections_required:
		animate(true)


func unpower() -> void:
	if energy == connections_required:
		animate(false)
	energy -= 1
	
	
func animate(opening: bool) -> void:
	var tween: Tween = create_tween().set_parallel()
	for door in [$Left, $Right]:
		tween.tween_property(door, "scale:x", 0.3 if opening else 1.0, open_close_duration)
	tween.finished.connect(Signals.update_navigation)
