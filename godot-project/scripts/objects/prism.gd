extends Area2D
class_name Prism

## Colour of the prism (accepted by matching terminals)
@export var colour := Color.WHITE

var is_picked_up = false 		# Track if the object is picked up

const regen_rate = 2.0  		# Rate of energy regen (per sec)


## Set colour
func _ready() -> void:
	# modulate = colour  # Commented out to keep original sprite appearance
	add_to_group("obstacles")  


func drop() -> void:
	is_picked_up = false
	z_index = 0


func pickup() -> void:
	is_picked_up = true
	z_index = 3


## run every physics frame
func _physics_process(delta: float) -> void:
	
	var player: Player = null
	for body in get_overlapping_bodies():
		if body is Player and body is not Ghost:
			player = body
			
	if not player or player.mode == Globals.Modes.WAVE:
		if is_picked_up:
			drop()
		return
	
	# When the player is in the area and presses the interact key
	if Input.is_action_just_pressed("interact"):
		if is_picked_up:
			drop()
		else:
			pickup()
			
	if is_picked_up:
		global_position = player.global_position

	# Regenerate energy if the player is near
	Globals.energy += regen_rate * delta
