extends Player
class_name Ghost

"""
What the Ghost can do:

CAN (is recorded)
- Interact with physics (when is_physical)
- Use all abilities (including creating entanglements)
- Create multiple possibilities, and collapse

CANNOT (is not recorded)
- Pick up prisms
- Destroy breakable tiles by dashing
- Press heavy buttons by dashing
- Activate probability detectors when collapsing
"""

"""
Information about Ghost data storage:

data[int n] = frames: 
	Frame data for recorded instance starting `n` physics frames after the first instance in the
	recording. `n` is also a unique key/id for the instance.
	data[0] always corresponds to the starting Player instance.

frames[int i] = frame:
	Array of actions that occured to that instance in the `i`th frame after `n`
	(the (i+n)th physics frame of the recording).

frame[int j] = action = [String action_name, Variant value]:
	The individual action being recorded that happened to the Player. Has a name and a value (which)
	may not be used). Actions can have the following type

Action types (name, value):
	("POS", Vector2 global_pos):
		Record global position, called every physics frame unless paused.
	("PAUSE", int current_frame):
		When the instance has been paused (no longer logging POS).
		Other actions are ignored until RESUME.
	("RESUME", int current_frame):
		When the instance has been resumed (becomes active or moves).
		Difference in pause/resume frames used for timing during playback.
	("MODE", Globals.Modes new_mode):
		When the player changes mode (to new_mode).
"""

### Dictionary that stores all information about a player recording, to be reconstructed.
var data: Dictionary[int, Array]

## The frame data for this Ghost instance
var frames: Array
## The current frame in the recording (synced across all Ghost instances)
var current_frame: int

## The frame that an instance is paused (current_frame at PAUSE)
var pause_frame: int
## The number of frames until being resumed (current_frame at RESUME - pause_frame)
var pause_frames_left: int


var ghost_scene: PackedScene

## Whether actions have consequences at the moment
var is_physical := false:
	# Toggle Player physics layer
	set(new_value):
		if new_value != is_physical:
			collision_layer ^= (1 << 0)
		is_physical = new_value
		
var always_physical := false


func setup(ghost_data: Dictionary[int, Array], start_frame: int, scene: PackedScene, physical: bool, invisible: bool) -> void:
		
	ghost_scene = scene
	is_physical = physical
	always_physical = physical
	current_frame = start_frame
	
	if invisible:
		visibility_layer = 0
	
	await ready
	
	if start_frame == 0:
		mode = Globals.Modes.PARTICLE
	
	for child in get_children():
		if "active" in child:
			child.active = true
		
	data = ghost_data
	assert(ghost_data.has(start_frame))
	frames = ghost_data.get(start_frame)
	
	queue_redraw()


func _physics_process(delta: float) -> void:
	
	#previous_velocity = velocity
	
	if data:
		act()
		
	#TODO
	#if move_and_slide():
		#if %DashAbility.collided(get_last_slide_collision()):
			#pass
			#velocity = previous_velocity
			
	# Spreading out wave function
	if mode == Globals.Modes.WAVE:
		super.spread_out_wave(delta)


###
# Perform all recorded actions in the current frame.
# Called every physics frame.
func act() -> void:
	if pause_frames_left > 0:  # Delay frame processing when paused
		pause_frames_left -= 1
	else:
	
		# Get most recent frame data
		var frame = frames.pop_back()
		if frame:
			# Performing actions
			for action in frame:
				match action[0]:
					"POS":
						global_position = action[1]
						visible = true
					"PAUSE":
						assert(current_frame == action[1], "Ghost recording playback desync!")
						pause_frame = current_frame
					"RESUME":
						pause_frames_left = action[1] - pause_frame - 1
					"MODE":
						mode = action[1] as Globals.Modes
					"PHYSICAL":
						is_physical = not is_physical
					"DASH":
						%DashAbility.start_dashing()
					"PARRY_START":
						%ParryAbility.start_parry()
					"PARRY_END":
						%ParryAbility.end_parry()
					"SHOOT":
						%ShootAbility.create_photon(action[1])
					"ENTANGLEMENT":
						if is_physical:
							var e: Dictionary = action[1]
							var a = get_node_by_uuid(e.a_uuid)
							var b = get_node_by_uuid(e.b_uuid)
							if a and b:
								Signals.emit_create({"a": a, "b": b, "invert": e.invert, "natural": false})
		else:
			kill()

	current_frame += 1
	
	# Creating a possibility when split occurs
	if data.has(current_frame):
		var ghost: Ghost = ghost_scene.instantiate()
		ghost.setup(data, current_frame, ghost_scene, always_physical, visibility_layer == 0)  # Keep sub-instances in sync
		manager.call_deferred("add_child", ghost)


func get_node_by_uuid(uuid: String) -> Node:
	for node in get_tree().get_nodes_in_group("Entangleable"):
		if node.has_meta("uuid") and node.get_meta("uuid") == uuid:
			return node
	return null
	

func kill(_death_type: String = "default") -> void:
	queue_free()
