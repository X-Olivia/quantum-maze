extends Node2D

@export var active: bool = false

@onready var parent: CharacterBody2D = get_parent()
var photon_scene: PackedScene = preload("res://scenes/hazards/photon.tscn")

@export var single_shoot_energy: float = 3
@export var multi_shoot_energy: float = 10
@export var long_press_duration: float = 0.5
@export var multi_shot_photons: int = 8
@export var multi_shot_cooldown: float = 1.0
@export var photon_offset: float = 100.0

var press_start_time: float = 0.0
var multi_shot_timer: float = 0.0
var shooting: bool = false


func _physics_process(delta: float) -> void:
	multi_shot_timer = max(0, multi_shot_timer - delta)


func start_shooting() -> void:
	if not active or shooting:
		return
		
	press_start_time = Time.get_ticks_msec() / 1000.0
	shooting = true


func end_shooting() -> void:
	if not active or not shooting:
		return
		
	shooting = false
	var press_duration = Time.get_ticks_msec() / 1000.0 - press_start_time
	if press_duration >= long_press_duration and multi_shot_timer <= 0.0:
		shoot_multi()
		multi_shot_timer = multi_shot_cooldown
	else:
		shoot_single()


func has_energy(amount: float) -> bool:
	if Globals.energy >= amount:
		return true
	return false


func shoot_single() -> void:
	if not has_energy(single_shoot_energy):
		return
	Globals.energy -= single_shoot_energy

	var direction = (get_global_mouse_position() - parent.global_position).normalized()
	create_photon(direction)


func shoot_multi() -> void:
	if not has_energy(multi_shoot_energy):
		return
	Globals.energy -= multi_shoot_energy

	for i in range(multi_shot_photons):
		var angle = i * 360.0 / multi_shot_photons
		var direction = Vector2(cos(deg_to_rad(angle)), sin(deg_to_rad(angle)))
		create_photon(direction)


func create_photon(direction: Vector2) -> void:
	var photon = photon_scene.instantiate()
	
	if parent is not Ghost and parent.manager.recording:
		parent.record.add("SHOOT", direction)
	elif parent is Ghost:
		photon.can_damage = parent.is_physical
		photon.modulate = parent.modulate
	
	photon.global_position = parent.global_position + direction * photon_offset
	photon.set_direction(direction)
	Globals.level.add_child(photon)
