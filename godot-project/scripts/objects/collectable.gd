extends Area2D
class_name Collectable

@export var id: int
@export var collectable_as_wave: bool

var was_collectable: bool = false
var bounce_height: float = 15.0
var bounce_speed: float = 3.0
var original_position: Vector2
var time: float = 0.0
var is_bouncing: bool = false


func _ready() -> void:
	set_collectable(false)


func set_collectable(collectable: bool) -> void:
	visible = collectable
	monitorable = collectable
	monitoring = collectable


func start_bouncing() -> void:
	original_position = global_position
	is_bouncing = true
	time = 0.0


var last_pos = null
func _physics_process(_delta: float) -> void:
	if last_pos and global_position.is_equal_approx(last_pos):
		start_bouncing()
		set_physics_process(false)
	last_pos = global_position


func _process(delta: float) -> void:
	
	if is_bouncing:
		time += delta
		global_position.y = original_position.y - bounce_height * abs(sin(time * bounce_speed))
	
	var player: Player = Globals.player
	if not player:
		return
		
	var collectable: bool = (player.mode == Globals.Modes.WAVE) == collectable_as_wave
	
	if collectable != was_collectable:
		set_collectable(collectable)
		was_collectable = collectable
		
	if collectable:
		if player in get_overlapping_bodies() or player.wave_area in get_overlapping_areas():
			Globals.level.got_collectable(id)
			queue_free()
