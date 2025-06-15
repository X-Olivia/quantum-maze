extends CharacterBody2D
class_name Player
###
# A particle or a possibility
# One at a time is controlled by the player


## Whether the player is currently controlling this instance or not
var active := false
var was_active := false
var dead = false

## Parent reference to player manager
@onready var manager: PlayerManager = get_parent()


## Player's mode, either PARTICLE or WAVE
var mode := Globals.Modes.UNSET:
	set(new_mode):
		mode = new_mode
		
		if manager:
			match mode:
				Globals.Modes.PARTICLE:	
					manager.set_to_particle(self)
				Globals.Modes.WAVE:
					manager.set_to_possibility(self)
		
		$Sprite2D.visible = mode == Globals.Modes.PARTICLE
		
		$ShootAbility.end_shooting()
		$ParryAbility.end_parry()
		cleanup_ghosts()
		
		if record:
			record.add("MODE", mode)
					

var wave_area: Area2D

## Shape of player's main collision
var collision_shape: CircleShape2D

## Shape of player's wave function when in wave mode
var wave_shape: CircleShape2D


@export var max_health: float = 100
var health: float = max_health:
	set(new_health):
		if new_health < health:
			flash()
		health = clampf(new_health, 0.0, max_health)
		if health == 0.0:
			kill()


## The player's maximum movement speed
@export var max_speed: float = 500

## Time taken to reach max speed (in seconds)
const acc_time: float = 0.5


var record: Recording = null


class Recording:
	
	var frames := []
	var actions := []
	var start_frame: int
	var current_frame: int
	var paused := false
	
	var last_pos := Vector2.ZERO

	var fps: float = Engine.physics_ticks_per_second  ## Recording fps (60)
	var dist_threshold: float = 10 / fps  ## Distance moved before unpausing
	var time_threshold: float = 0.1 * fps  ## Seconds stationary until ghost is paused
	var pause_frames: int = 0  ## Frames stationary
	
	func _init(frame: int):
		start_frame = frame
		current_frame = start_frame
	
	func next_frame(global_pos: Vector2) -> void:
		
		# Pause/resume due to (in)activity
		if last_pos.distance_squared_to(global_pos) < dist_threshold ** 2:
			pause_frames += 1
			if pause_frames > time_threshold:
				pause()
		else:
			resume()
		
		add("POS", global_pos)
		
		if not actions.is_empty():
			frames.append(actions.duplicate())
			actions.clear()
		
		last_pos = global_pos
		current_frame += 1
			
	func add(action_name: String, value: Variant) -> void:
		# Resume if any waking action occurs
		if action_name not in ["PAUSE", "RESUME", "POS"]:
			resume()
		
		if not paused:
			actions.append([action_name, value])
		
	func pause() -> void:
		if not paused:
			add("PAUSE", current_frame)
			paused = true
			
	func resume() -> void:
		if paused:
			paused = false
			pause_frames = 0
			add("RESUME", current_frame)


func start_recording(start_time: int) -> void:
	if not record:
		record = Recording.new(start_time)
	

func stop_recording() -> void:
	if record:
		manager.records[record.start_frame] = record.frames
		record = null
	

###
# Creating nodes that must be unique to the instance
# Runs once when the instance is created
func _ready() -> void:
	collision_shape = CircleShape2D.new()
	$CollisionShape2D.shape = collision_shape
	collision_shape.radius = 0
	
	wave_shape = CircleShape2D.new()
	$WaveArea/CollisionShape2D.shape = wave_shape
	wave_shape.radius = 0
	
	wave_area = $WaveArea



const max_ghosts = 40  ## Maximum number of ghosts that can exist at once
const pulse_time = 5  ## Seconds ring pulses take to reach boundary
var ghosts := []
var ring_timer = 0


func spawn_ghost(r: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = $Sprite2D.texture.duplicate()
	
	sprite.modulate = Color.TRANSPARENT
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0.3), 0.5)
	
	add_child(sprite)
	
	var pos = global_position + Globals.circle_sample(r)
	var speed = randf() * max_speed
	
	# Player at full speed, ratio = 0, dir within 45 degrees of velocity
	# Player stationary, ratio = 1, dir random (within 360 degrees of velocity)
	var ratio = 1.0 - clamp(velocity.length() / max_speed, 0.0, 1.0)
	var max_angle = 0.5 * PI * (3.0 * ratio + 1.0)  # Ranges from π/2 to 2π
	var angle = randf_range(-max_angle, max_angle)
	
	var base = Vector2.RIGHT if velocity.is_zero_approx() else velocity.normalized()

	ghosts.append({"sprite": sprite, "pos": pos, "speed": speed, "dir": base.rotated(angle)})
	

func cleanup_ghosts():
	for ghost in ghosts:
		ghost.sprite.queue_free()
	ghosts.clear()
	ring_timer = 0


func _draw() -> void:
	if dead or mode != Globals.Modes.WAVE:
		return
	
	var r = wave_shape.radius
		
	if ring_timer >= pulse_time:
		ring_timer = 0
		
	draw_circle(Vector2.ZERO, r, Color(1, 1, 1, 0.2))
	
	var ring_r = r * ring_timer / pulse_time
	draw_circle(Vector2.ZERO, ring_r, Color(1, 1, 1, 0.2), false, 50)
	
	var ghost_num = ceili(max_ghosts * r / manager.max_spread_radius)
	for i in range(ghost_num - len(ghosts)):
		spawn_ghost(r)


func handle_ghosts(delta: float) -> void:
	for i in range(len(ghosts) - 1, -1, -1):
		var ghost = ghosts[i]
		var sprite = ghost.sprite
		ghost.pos += ghost.dir * ghost.speed * delta
		sprite.global_position = ghost.pos
		if global_position.distance_squared_to(sprite.global_position) >= wave_shape.radius * wave_shape.radius:
			ghosts.remove_at(i)
			sprite.queue_free()


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


func spread_out_wave(delta: float) -> void:
	wave_shape.radius = min(wave_shape.radius + manager.spread_speed * delta, manager.max_spread_radius)
	ring_timer += delta
	handle_ghosts(delta)
	queue_redraw()
	

###
# Runs for every instance each physics frame
# `active` boolean is used to run code on just the current instance
# 
# Arguments
# - delta : Time since last physics update.
# 
# Return : None
func _physics_process(delta: float) -> void:
	if Globals.level.process_mode == Node.PROCESS_MODE_DISABLED:
		return
	
	# Spreading out wave function
	if mode == Globals.Modes.WAVE:
		spread_out_wave(delta)
	
	# Updating Globals with active instance
	if not was_active and active:
		if record:
			record.resume()
	was_active = active
	
	if active:
		basic_handling(delta)

		match mode:
			Globals.Modes.PARTICLE:
				particle_mode_handling(delta)
			Globals.Modes.WAVE:
				wave_mode_handling(delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, max_speed * delta / acc_time)
		
	movement_and_collision_handling(delta)
	
	if record:
		record.next_frame(global_position)


var previous_velocity: Vector2
var next_position: Vector2


###
# Handles movement and any collisions that occur
# 
# Arguments
# - delta : Time since last physics update.
# 
# Return : None
func movement_and_collision_handling(delta: float) -> void:
	# Store movement state
	previous_velocity = velocity
	next_position = global_position + velocity * delta
		
	# Update movement and collision state
	var collided: bool = move_and_slide()
	
	# Check if player fell into bottomless pit
	if not %DashAbility.dashing and Globals.floor_tiles.is_name(global_position, "bottomless pit"):
		kill("death_zone")
		return
	
	# Check if player particle is standing on spikes
	if mode == Globals.Modes.PARTICLE and Globals.floor_tiles.is_name(global_position, "spikes"):
		kill()
		return
	
	if not collided:
		return  # Return if player hasn't collided with anything
				
	# Collided with a destructable tile whilst dashing
	if %DashAbility.collided(get_last_slide_collision()):
		# Revert movement state, ignoring collision
		velocity = previous_velocity
		global_position = next_position


###
# Code that should run for the current instance
# Called every physics frame
# 
# Arguments
# - delta : Time since last physics update.
# 
# Return : None
var physical_recording := false
func basic_handling(delta: float) -> void:
	
	if not Globals.player_frozen:
		# Handling the player's movement
		var dir = Input.get_vector("left", "right", "up", "down").normalized()
		velocity = velocity.move_toward(dir * max_speed, max_speed * delta / acc_time)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, max_speed * delta / acc_time)
	
	if Input.is_action_just_pressed("toggle mode"):
		mode = Globals.Modes.PARTICLE if mode == Globals.Modes.WAVE else Globals.Modes.WAVE
		
	# Record physical interaction toggles
	if record and Input.is_action_just_pressed("control dialogue"):
		physical_recording = not physical_recording
		print("Physical recording " + "ON" if physical_recording else "OFF")
		record.add("PHYSICAL", null)
		

###
# Code that should run for the current instance, when in particle mode
# Called every physics frame
# 
# Arguments
# - delta : Time since last physics update.
# 
# Return : None
func particle_mode_handling(_delta: float) -> void:
	# 如果玩家被冻结，不处理任何能力输入
	if Globals.player_frozen:
		return
	
	# Dash ability
	if Input.is_action_just_pressed("dash"):
		%DashAbility.dash()
	
	# Photon shooting ability
	if Input.is_action_pressed("lclick"):
		$ShootAbility.start_shooting()
	else:
		$ShootAbility.end_shooting()
	
	# Parry ability
	if Input.is_action_just_pressed("rclick") and Globals.energy > 0:
		$ParryAbility.start_parry()
	elif Input.is_action_just_released("rclick"):
		$ParryAbility.end_parry()


###
# Code that should run for the current instance, when in wave mode
# Called every physics frame
# 
# Arguments
# - delta : Time since last physics update.
# 
# Return : None
func wave_mode_handling(delta: float) -> void:
	# 如果玩家被冻结，只减少wave模式计时器，不处理其他输入
	if Globals.player_frozen:
		# 仍然减少wave模式计时器
		Globals.wave_mode_timer -= delta
		return
	
	# Decreasing wave mode timer, death at 0
	Globals.wave_mode_timer -= delta
	
	# Creating a new possibility
	if Input.is_action_just_pressed("interact"):
		manager.create_possibility()
		
	# Cycling left or right through active possibilities
	var cycled_left: bool = Input.is_action_just_pressed("cycle left")
	if cycled_left or Input.is_action_just_pressed("cycle right"):
		manager.cycle_possibility(-1 if cycled_left else 1)


func damage(value: Variant) -> void:
	if value is Dictionary and value.has("damage"):
		health -= value.damage
	

func kill(_death_type: String = "default") -> void:
	dead = true
	manager.kill(self, _death_type)
