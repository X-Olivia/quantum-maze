extends Node2D

@export var active: bool = false

## Reference to parent
@onready var parent: CharacterBody2D = get_parent()

# Enums and variables
enum DashModes {PLAYER, ACCELERATOR}
var dash_mode: DashModes
var dash_direction: Vector2

@export var dash_duration: float = 0.3
@export var dash_cooldown: float = 0.5
@export var dash_speed: float = 2000
@export var energy_to_dash: float = 10

var last_accelerator: Accelerator = null

# Flags
var can_dash: bool = true
var dashing: bool = false


## Sets up dash timers
func _ready() -> void:
	$DashTimer.wait_time = dash_duration
	$DashCooldown.wait_time = dash_cooldown


### 
# Makes the parent dash in a direction every frame
# If the dash is a PLAYER dash, the direction is towards the mouse cursor
# If the dash is an ACCELERATOR dash, the direction is fixed
func _physics_process(_delta: float) -> void:
	
	if not dashing:
		return
	
	# Stop dashing if in wave mode
	if parent.mode == Globals.Modes.WAVE:
		stop_dashing()
		return
	
	# Determine dash direction depending on type of dash
	var direction: Vector2
	match dash_mode:
		DashModes.PLAYER:
			var player_position: Vector2 = get_viewport_rect().get_center()
			var mouse_position: Vector2 = get_viewport().get_mouse_position()
			direction = (mouse_position - player_position).normalized()
		DashModes.ACCELERATOR:
			direction = dash_direction
	
	parent.velocity = direction * dash_speed


## Initialises dash by consuming energy and setting variables
func dash(direction: Vector2 = Vector2.ZERO) -> void:
	if parent.mode == Globals.Modes.WAVE:
		return

	# Determine dash mode
	if direction == Vector2.ZERO:
		# Ignore player dash if already dashing or accelerated
		if not active or dashing or not can_dash:  
			return
		dash_mode = DashModes.PLAYER
	else:
		dash_mode = DashModes.ACCELERATOR

	dash_direction = direction

	if dash_mode == DashModes.PLAYER:
		if Globals.energy >= energy_to_dash:
			Globals.energy -= energy_to_dash
			start_dashing()
	else:
		start_dashing()


func start_dashing() -> void:
	if parent is not Ghost and parent.manager.recording:
		parent.record.add("DASH", null)
	
	dashing = true
	can_dash = false

	if dash_mode == DashModes.PLAYER:
		$DashTimer.start()
	else:
		$DashTimer.stop()

	$SafetyTimer.start()
	$FlamingTrail.emitting = true


func stop_dashing() -> void:
	dashing = false

	if dash_mode == DashModes.PLAYER:
		$DashCooldown.start()
	else:
		can_dash = true

	$SafetyTimer.stop()
	parent.velocity = Vector2.ZERO
	$FlamingTrail.emitting = false
	
	$DashBurst.restart()
	
	if parent is not Ghost:
		Globals.start_camera_shake(10, 15)


###
# Handles collisions when dashing, such as:
# breaking destructable wall tiles, opening chests, pushing heavy buttons
# Uses a damage function call to fetch stopping or reverting data
# 
# Arguments:
# - collision_info : Details of parent's collision
# 
# Return : Whether the parent should revert the collision
func collided(collision_info: KinematicCollision2D) -> bool:
	if not dashing:
		return false

	var stop = true
	var revert = false
	
	var collider = collision_info.get_collider()
		
	# Handle collision
	if collider.has_method("damage"):
		
		var result = collider.damage({"callee": parent, "collider": collision_info.get_collider_rid()})
		if result and result is Dictionary:
			if result.has("stop"):
				stop = result.stop
			if result.has("revert"):
				revert = result.revert

	# Stop dashing on collision in ACCELERATOR mode
	if dash_mode == DashModes.ACCELERATOR and stop:
		stop_dashing()
		
	# Ignore collisions with breakable tiles
	return revert


## Called when player dash ends
func _on_dash_timer_timeout() -> void:
	stop_dashing()


## Called when player dash cooldown ends
func _on_dash_cooldown_timeout() -> void:
	can_dash = true


## Called if dashing infinitely (level design shouldn't allow this to happen)
func _on_safety_timer_timeout() -> void:
	stop_dashing()
