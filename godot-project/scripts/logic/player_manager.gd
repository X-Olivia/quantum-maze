extends Node2D
class_name PlayerManager
###
# Manages all particle/possibility instances
# These instances are the children of this node


## Array of instances (particle or multiple possibilities)
var instances: Array[Player] = []
## Index of the instance in `instances` the player is currently controlling
var current: int = 0

## Blueprint for the player scene
var player_scene: PackedScene = preload("res://scenes/player/player.tscn")

const temp_ghost_data_path: String = "res://data/temp_ghost_data.txt" 

## Maximum distance a possibilitiy can spread out in all directions
const max_spread_radius: int = 300
## Speed at which a possibility spreads out
const spread_speed: float = 40

## Energy consumed to create a new possibility
const energy_to_create_possibility: int = 20

const particle_collision_radius: int = 45
const possibility_collision_radius: int = 1

## Maximum number of checks for a safe place to collapse to before giving up
const max_iterations: int = 30
## Distance between each step while ray marching
const step_size = 10


# Recording variables
var recording := false
var records: Dictionary[int, Array] = {}
var frame_num: int


func _ready() -> void:
	global_position = Vector2.ZERO
	

func start_recording() -> void:
	recording = true
	frame_num = 0
	Globals.DEBUG_FEATURES_ON = false
	Globals.player.start_recording(frame_num)
	print("STARTED RECORDING, DEBUG FEATURES DISABLED")


func stop_recording() -> void:
	recording = false
	for instance in instances:
		instance.stop_recording()
	
	print("ENDED RECORDING")
	
	var sorted_records: Dictionary[int, Array] = {}
	var sorted_keys = records.keys()
	sorted_keys.sort()
	for key in sorted_keys:
		sorted_records[key] = records[key]
	
	var file = FileAccess.open(temp_ghost_data_path, FileAccess.WRITE)
	if file:
		var data_string = Marshalls.variant_to_base64(sorted_records)
		file.store_string(data_string)
		file.close()
		print("Data saved to: ", temp_ghost_data_path)


func _physics_process(_delta: float) -> void:
	if Globals.DEBUG:
		
		# Toggle debug features
		if Input.is_action_just_pressed("toggle debug features (DEBUG)"):
			Globals.DEBUG_FEATURES_ON = not Globals.DEBUG_FEATURES_ON
			print("DEBUG FEATURES ", "ON" if Globals.DEBUG_FEATURES_ON else "OFF")
		
		# Toggle recording (DEBUG)
		if Input.is_action_just_pressed("toggle record (DEBUG)"):
			if recording:
				stop_recording()
			elif Globals.DEBUG_FEATURES_ON and instances[current].mode == Globals.Modes.PARTICLE:
				start_recording()
			else:
				print("Can't record, press 't' to turn on debug features")
		
	if recording:
		frame_num += 1


func create_instance(spawn_position: Vector2) -> Player:
	var instance: Player = player_scene.instantiate()
	
	instance.global_position = spawn_position
	
	# Adding to the instances list and the scene
	instances.append(instance)
	add_child(instance)
	
	if recording:
		instance.start_recording(frame_num)
	
	return instance


func create_particle(ability_config: Dictionary, spawn_position: Vector2) -> void:
	var player: Player = create_instance(spawn_position)
	
	if not player.is_node_ready():
		await player.ready
	
	player.mode = Globals.Modes.PARTICLE
	#set_to_particle(player)
	
	change_to_instance(instances.size() - 1)
	
	# Setting up abilities
	for ability_name in ability_config:
		var ability = player.get_node("%" + ability_name.capitalize() + "Ability")
		ability.active = ability_config.get(ability_name)


## Creates a new possibility if possible, and moves player control to it
func create_possibility() -> void:
	if Globals.energy < energy_to_create_possibility:
		return
	Globals.energy -= energy_to_create_possibility
	
	var new_possibility: Player = create_instance(instances[current].global_position)
	
	new_possibility.mode = Globals.Modes.WAVE
	#set_to_possibility(new_possibility)
	
	change_to_instance(instances.size() - 1)


###
# Moves player control to the previous/next possibility
# 
# Arguments:
# - direction : Direction to cycle through `instances` (-1 for left, 1 for right)
# 
# Return : None
var can_cycle := true
func cycle_possibility(direction: int) -> void:
	
	if not can_cycle:
		return
	can_cycle = false
	get_tree().create_timer(0.1).timeout.connect(func() -> void: can_cycle = true)
	
	# Only cycle if there are more than one instance
	if instances.size() <= 1:
		return
	
	# Calculating the next instance to switch to
	var next: int = (current + direction + instances.size()) % instances.size()
	change_to_instance(next)


###
# Changes an instance to wave mode
# 
# Arguments:
# - instance : The instance
# 
# Return : None
func set_to_possibility(instance: CharacterBody2D) -> void:
	if instance.mode != Globals.Modes.WAVE:
		return
		
	instance.collision_shape.radius = possibility_collision_radius
	instance.wave_shape.radius = 0
	
	if instance is not Ghost:
		Globals.hud.wave_countdown_label.visible = true
	
	instance.queue_redraw()
	

###
# Changes a possibility to particle mode
# Collapses (deletes) all other possibilities
# Sets player position to a calculated point
# 
# Arguments:
# - instance : The instance
# 
# Return : None
func set_to_particle(instance: CharacterBody2D) -> void:
	if instance.mode == Globals.Modes.WAVE:
		return
		
	if instance is not Ghost and instance.mode == Globals.Modes.PARTICLE:
		
		if instance != instances[current]:
			change_to_instance(instances.find(instance))
		
		# Activate all probability detectors
		for i in instances:
			for area in i.wave_area.get_overlapping_areas():
				if area is ProbabilityDetector:
					area.power()
		
		# Collapse (delete) all other possibilities
		kill_others()
		
		instance.global_position = get_new_position(instance)
	
	
	instance.collision_shape.radius = particle_collision_radius
	instance.wave_shape.radius = 0
	
	if instance is not Ghost:
		Globals.wave_mode_timer = Globals.wave_mode_duration
		Globals.hud.wave_countdown_label.visible = false
	
	instance.queue_redraw()


###
# Moves player control to another instance by changing `active` flag and moving camera across
# 
# Arguments:
# - next : The index into `instances` of the possibility to change to
# 
# Return : None
func change_to_instance(next: int) -> void:
		
	# Deactivate the current player instance, if it exists
	if not instances.is_empty():
		var current_instance: Player = instances[current]
		current_instance.active = false
		
	var next_instance: Player = instances[next]
	next_instance.active = true
	
	Globals.player = next_instance
	
	# Update the current index
	current = next
	
	# Move camera across (create if necessary)
	if not Globals.camera:
		Globals.camera = Camera2D.new()
		next_instance.add_child(Globals.camera)
	else:
		Globals.camera.reparent(next_instance)
		Globals.camera.position = Vector2.ZERO
	

## Finds the position the player particle should appear at
func get_new_position(player: Player) -> Vector2:
	
	var start: Vector2 = player.global_position
	
	var radius: float = player.wave_shape.radius
	
	if radius == 0:
		return start
	
	# Appear in view of probability detector if one is observing you
	for area in player.wave_area.get_overlapping_areas():
		if area is ProbabilityDetector and is_valid(start, area.global_position):
			return area.global_position
		
	# Randomly picks points within the player's wave area until a valid one is found
	# Sets the player's global position to this point
	var count: int = 0
	while count < max_iterations:
	
		var new_position: Vector2
		if Globals.DEBUG_FEATURES_ON:
			new_position = get_global_mouse_position()
		else:
			new_position = start + Globals.circle_sample(radius)
		
		if is_valid(start, new_position):
			return new_position
			
		count += 1
		if Globals.DEBUG_FEATURES_ON:
			break
		
	print("INFO: No safe place to reappear found, using current position")
	return start


###
# Returns whether a given teleportation from start to end is valid.
# Does this by checking if the end point would be inside a wall or if the player 
# would have tunnelled through anything untunnellable.
# 
# Arguments:
# - start : Possibility position before collapse
# - end : Particle position after collapse (if teleportation is valid)
# 
# Return : If the end position is valid or not
func is_valid(start: Vector2, end: Vector2) -> bool:
	return point_query(end) and ray_march(start, end)


func point_query(end: Vector2) -> bool:
	var world_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	
	var query := PhysicsPointQueryParameters2D.new()
	query.collide_with_areas = true
	query.collision_mask = 0b00000010  # Walls
	query.position = end
	
	var result = world_state.intersect_point(query)
	return result.size() == 0


func ray_march(start: Vector2, end: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	
	# Ray marching with step sizes to check along the line
	var direction = start.direction_to(end)
	var current_position = start
	
	while current_position.distance_squared_to(end) > step_size ** 2:
		# Cast a small ray at the current position to detect collisions
		var query := PhysicsRayQueryParameters2D.create(current_position, current_position + direction * step_size, 0b00000010)
		query.hit_from_inside = true
		
		var hit = space_state.intersect_ray(query)
		if hit:
			# Cannot tunnel through untunnelable tiles
			if hit.collider == Globals.wall_tiles:
				var cell: TileData = Globals.wall_tiles.get_cell_at_global_point(hit.position)
				if cell and cell.get_custom_data("untunnelable"):
					return false
			
			# Cannot tunnel through untunnelable objects
			elif is_untunnelable(hit.collider):
				return false
		
		# Move to the next position
		current_position += direction * step_size
	
	return true


func is_untunnelable(node: Node) -> bool:
	while node:
		if node.is_in_group("Untunnelable"):
			return true
		node = node.get_parent()
	return false



## Called on game over
func game_over(death_pos: Vector2, death_type: String = "default") -> void:
	Globals.camera.reparent(self)
	Globals.camera.global_position = death_pos
	Signals.emit_died(death_type)


###
# Kills (deletes) an instance
# If killing the current possibility, tries to move you to another first
# Preserves the camera
# 
# Arguments:
# - value : The index in `instances` of the instance to delete or the instance itself
# - death_type : The type of death (default or death_zone)
# 
# Return : None
func kill(value: Variant, death_type: String = "default") -> void:
	
	var index: int
	if value is Player:
		index = instances.find(value)
	else:
		index = value
	var instance: CharacterBody2D = instances[index]
	
	# Stop recording
	if instance.record:
		instance.stop_recording()
	
	# Handling trying to kill current instance
	if index == current:
		# Game over if killing the current instance
		if instances.size() == 1:
			game_over(instances[0].global_position, death_type)
		# Move to another possibility to avoid game over
		else:
			cycle_possibility(1 if randf() > 0.5 else -1)
	
	# If removing instance to the left of current in `instances`, account for shift
	if index < current:
		current -= 1
	
	# Kill instance
	instances.remove_at(index)
	instance.queue_free()


## Kills all uninhabited instances
func kill_others() -> void:
	# Indices must decend to avoid out of bounds error on last index
	for index in range(instances.size() - 1, -1, -1):
		if index != current:
			kill(index, "default")
	current = 0
	

## Kills all instances, ending the game
func kill_all() -> void:
	for index in range(instances.size() - 1, -1, -1):
		kill(index, "default")
