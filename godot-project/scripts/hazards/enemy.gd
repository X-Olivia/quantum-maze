extends CharacterBody2D
class_name Enemy

@export var active: bool = true

@export var speed: float = 112

@export var max_health: float = 100

var health: float = max_health:
	set(new_health):
		if new_health < health:
			flash()
		health = clampf(new_health, 0.0, max_health)
		if health == 0.0:
			kill()

@onready var home_position: Vector2 = global_position

var stunned: bool = false

var player: Player = null

var recalc_timer: float = 0.0
const recalc_duration: float = 0.3


# For entanglement
var connections: Array[Entanglement] = []
const ENTANGLEMENT_DAMAGE: float = 20
const collapsed := false


func _physics_process(delta: float):
	
	if stunned or not active:
		return
	
	# Set player if they have entered the Aggro area
	for body in $Aggro.get_overlapping_bodies():
		if body is Player and body is not Ghost and body.mode == Globals.Modes.PARTICLE:
			if not player:
				player = body
	
	# Set player to null if they have left the Deaggro area
	var found: Player = null
	for body in $Deaggro.get_overlapping_bodies():
		if body is Player and body is not Ghost and body.mode == Globals.Modes.PARTICLE:
			found = body
	if player and not found:
		player = null
	
	
	# Recalculating navigation
	recalc_timer += delta
	if recalc_timer >= recalc_duration:
		recalc_timer = 0.0
		if player:
			$NavigationAgent2D.target_position = player.global_position
		else:
			$NavigationAgent2D.target_position = home_position
		
	
	# Get the next position on the path, convert it to local space, normalize it, and set velocity.
	var axis = to_local($NavigationAgent2D.get_next_path_position()).normalized()
	velocity = speed * axis
	
	# Movement and collision handling
	if move_and_slide():
		var collider = get_last_slide_collision().get_collider()
		
		# Collided with the player
		if collider is Player and collider is not Ghost:
			collider.kill("default")
			kill()


var flashing := false
var flash_cooldown := false
func flash():
	if flashing:
		return
	flashing = true
	
	var tween = create_tween()
	tween.pause()
	tween.finished.connect(func(): flashing = false)
	tween.tween_property(self, "modulate", Color(5, 5, 5), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.play()


func _process(_delta: float) -> void:
	if health <= 20 and not flash_cooldown:
		flash()
		flash_cooldown = true
		get_tree().create_timer(0.5).timeout.connect(func(): flash_cooldown = false)


func update(_source: Node2D, _value: int) -> void:
	health -= ENTANGLEMENT_DAMAGE


func revert() -> void:
	pass


func damage(value: Variant) -> void:
	if value is Dictionary and value.has("damage"):
		health -= value.damage
	

func kill() -> void:
	var value = 0 if randf() < 0.5 else 1
	for connection in connections.duplicate():
		connection.update(self, value)
	
	queue_free()


func stun() -> void:
	stunned = true
	$StunnedTimer.start()


func _on_stunned_timer_timeout() -> void:
	stunned = false
