extends Area2D
class_name ParryAbility

@export var active := false

@onready var parent: CharacterBody2D = get_parent()

## Damage multiplier applied to photons that hit shield
@export var damage_multiplier: float = 0.5

## Constant energy drain of shield
@export var energy_drain: float = 10

# Flags

## If the shield is out or not
var blocking := false

var is_perfect_parry := false

var can_power := true


func start_parry():
	if not active:
		return
	
	can_power = not (parent is Ghost and not parent.is_physical)
	
	if parent is not Ghost and parent.manager.recording:
		parent.record.add("PARRY_START", null)
	
	is_perfect_parry = true
	$Timer.start()
	
	blocking = true
	visible = true


func end_parry():
	if parent is not Ghost and parent.manager.recording:
		parent.record.add("PARRY_END", null)
	
	blocking = false
	visible = false


func _physics_process(delta: float) -> void:
	if parent is Ghost:
		return
		
	if blocking:
		for thing in get_overlapping_areas() + get_overlapping_bodies():
			if thing is Photon:
				handle_photon(thing)
			elif thing is Enemy:
				handle_enemy(thing)
			
	if blocking and not is_perfect_parry:
		Globals.energy -= energy_drain * delta
	
	if Globals.energy <= 0:
		end_parry()
		return


func handle_photon(photon: Photon) -> void:
	if photon.parried:
		return
	photon.parried = true
	
	# Deflect photon
	if is_perfect_parry:
		var previous_direction = photon.direction.normalized()
		var normal_line = get_parent().global_position.direction_to(photon.global_position)
		var dot_product = previous_direction.dot(normal_line)
		if dot_product <= 0:
			var reflected_direction = previous_direction - 2 * previous_direction.dot(normal_line) * normal_line
			photon.set_direction(reflected_direction.normalized())
	# Decrease photon damage
	else:
		photon.damage *= damage_multiplier


func handle_enemy(enemy: Enemy) -> void:
	# Stun enemy
	if is_perfect_parry and not enemy.stunned:
		enemy.stun()


func _on_timer_timeout() -> void:
	is_perfect_parry = false
