extends StaticBody2D

# Beam intensity and color configuration
const FULL_INTENSITY := 1.0
const SPLIT_INTENSITY := 0.5
const BEAM_COLOR := Color(0.8, 0.9, 1.0)  # Light blue beam
const BEAM_GLOW_COLOR := Color(0.8, 0.9, 1.0, 0.5)  # Semi-transparent glow color
const OUTER_GLOW_COLOR := Color(0.7, 0.85, 1.0, 0.25)  # Outer glow layer
const OUTER_GLOW_2_COLOR := Color(0.6, 0.8, 1.0, 0.05)  # Outermost glow layer

# Pulse effect configuration
const PULSE_SPEED := 2.0  # Pulse speed
const PULSE_INTENSITY_MIN := 0.03  # Minimum pulse intensity
const PULSE_INTENSITY_MAX := 0.15  # Maximum pulse intensity

# Node references
@onready var main_beam := $BeamLine
@onready var main_ray := $RayCast2D

@onready var left_beam := $LeftBeam
@onready var right_beam := $RightBeam
@onready var left_ray := $LeftRayCast
@onready var right_ray := $RightRayCast

@onready var left_beam2 := $LeftBeam2
@onready var right_beam2 := $RightBeam2
@onready var left_ray2 := $LeftRayCast2
@onready var right_ray2 := $RightRayCast2

@onready var output_beam := $OutputBeam
@onready var output_ray := $OutputRayCast

# Glow effect nodes
var beam_glows = {}  # First layer glow
var beam_outer_glows = {}  # Second layer glow
var beam_outer_glows_2 = {}  # Third layer glow

# State variables
var is_disturbed := false  # Whether received interference signal
var beam_endpoints := {}   # Store beam endpoints
var pulse_time := 0.0      # Pulse timer

# Store initial beam directions and lengths
var original_directions := {}
var original_lengths := {}

func _ready() -> void:
	# Initialize color and intensity for all beams
	for beam in [main_beam, left_beam, right_beam, left_beam2, right_beam2, output_beam]:
		beam.default_color = BEAM_COLOR
		beam.width = 7.0  
	
	# Create glow effects
	create_beam_glow_layers()
	
	# Save initial direction and length for all beams
	save_original_beam_data()
	
	# Ensure RayCasts align with Line2Ds
	align_raycasts_with_beams()
	
	# Set initial state
	update_beam_intensities()

func create_beam_glow_layers() -> void:
	# Create three glow layers for each beam
	var beams = [main_beam, left_beam, right_beam, left_beam2, right_beam2, output_beam]
	var glow_names = ["main", "left", "right", "left2", "right2", "output"]
	
	for i in range(beams.size()):
		var beam = beams[i]
		var base_name = glow_names[i]
		
		# First glow layer - slightly wider than beam
		create_beam_glow(beam, base_name + "_glow", BEAM_GLOW_COLOR, 2.0, -1, beam_glows)
		
		# Second glow layer - wider and more transparent
		create_beam_glow(beam, base_name + "_outer_glow", OUTER_GLOW_COLOR, 3.5, -2, beam_outer_glows)
		
		# Third glow layer - widest and most transparent, with pulse effect
		create_beam_glow(beam, base_name + "_outer_glow_2", OUTER_GLOW_2_COLOR, 5.0, -3, beam_outer_glows_2)

func create_beam_glow(beam: Line2D, glow_name: String, color: Color, width_multiplier: float, z_index_offset: int, glow_dict: Dictionary) -> void:
	# Create a new Line2D as glow effect
	var glow = Line2D.new()
	glow.name = glow_name
	glow.points = beam.points.duplicate()
	glow.default_color = color
	glow.width = beam.width * width_multiplier  # Glow width is multiplier of beam width
	# Ensure glow z_index relative to beam z_index
	glow.z_index = 3 + z_index_offset  # Base z_index is 3, plus offset
	glow.position = beam.position
	glow.rotation = beam.rotation
	
	# Add glow to the same parent node
	beam.get_parent().add_child(glow)
	glow_dict[beam.name] = glow

func save_original_beam_data() -> void:
	# Save main beam data
	original_directions["main"] = (main_beam.points[1] - main_beam.points[0]).normalized()
	original_lengths["main"] = (main_beam.points[1] - main_beam.points[0]).length()
	
	# Save first splitter data
	original_directions["left"] = (left_beam.points[1] - left_beam.points[0]).normalized()
	original_lengths["left"] = (left_beam.points[1] - left_beam.points[0]).length()
	original_directions["right"] = (right_beam.points[1] - right_beam.points[0]).normalized()
	original_lengths["right"] = (right_beam.points[1] - right_beam.points[0]).length()
	
	# Save second splitter data
	original_directions["left2"] = (left_beam2.points[1] - left_beam2.points[0]).normalized()
	original_lengths["left2"] = (left_beam2.points[1] - left_beam2.points[0]).length()
	original_directions["right2"] = (right_beam2.points[1] - right_beam2.points[0]).normalized()
	original_lengths["right2"] = (right_beam2.points[1] - right_beam2.points[0]).length()
	
	# Save output beam data
	original_directions["output"] = (output_beam.points[1] - output_beam.points[0]).normalized()
	original_lengths["output"] = (output_beam.points[1] - output_beam.points[0]).length()

func align_raycasts_with_beams() -> void:
	# Adjust RayCast target_position to match corresponding Line2D
	main_ray.target_position = main_beam.points[1] - Vector2(0, 5)  # Consider position offset
	
	# First splitter rays
	left_ray.target_position = left_beam.points[1].rotated(left_beam.rotation)
	right_ray.target_position = right_beam.points[1].rotated(right_beam.rotation)
	
	# Second splitter rays - extend detection distance significantly 
	var left2_dir = left_beam2.points[1].rotated(left_beam2.rotation).normalized() * 2000
	var right2_dir = right_beam2.points[1].rotated(right_beam2.rotation).normalized() * 2000
	left_ray2.target_position = left2_dir
	right_ray2.target_position = right2_dir
	
	# Output beam ray
	output_ray.target_position = output_beam.points[1]

func _physics_process(delta: float) -> void:
	# Update pulse timer
	pulse_time += delta
	
	# Update beams
	update_main_beam()
	update_first_split()
	check_disturbance()
	update_second_split()
	update_output_beam()
	
	# Update pulse effect
	update_pulse_effect()

func update_pulse_effect() -> void:
	# Calculate pulse intensity - oscillate between min and max values
	var pulse_factor = (sin(pulse_time * PULSE_SPEED) + 1.0) / 2.0  # Value between 0-1
	var intensity = lerp(PULSE_INTENSITY_MIN, PULSE_INTENSITY_MAX, pulse_factor)
	
	# Update transparency for all outermost glow layers
	for beam_name in beam_outer_glows_2:
		var glow = beam_outer_glows_2[beam_name]
		if glow and glow.visible:
			var base_color = OUTER_GLOW_2_COLOR
			glow.default_color = Color(base_color.r, base_color.g, base_color.b, intensity)

func update_main_beam() -> void:
	if main_ray.is_colliding():
		var collider = main_ray.get_collider()
		var collision_point = main_ray.get_collision_point()
		
		# Only adjust beam length if collider is not an observer
		if not collider.is_in_group("observers"):
			# Calculate distance from beam start to collision point
			var distance = main_beam.global_position.distance_to(collision_point)
			
			# Keep beam direction unchanged, only adjust length
			var direction = original_directions["main"]
			main_beam.points[1] = direction * min(distance, original_lengths["main"])
		else:
			# For observers, maintain full length
			main_beam.points[1] = original_directions["main"] * original_lengths["main"]
		
		check_and_notify_receiver(collider, main_ray.global_position, collision_point, FULL_INTENSITY)
	else:
		# Use original length when no collision
		main_beam.points[1] = original_directions["main"] * original_lengths["main"]
	
	# Update glow effects
	update_glow_layers(main_beam)
	
	beam_endpoints["main"] = main_beam.points[1]

func update_first_split() -> void:
	# Check if main beam is blocked
	if main_ray.is_colliding():
		var main_collider = main_ray.get_collider()
		if main_collider.is_in_group("obstacles"):
			# Main beam blocked, don't update first splitter beams
			hide_all_subsequent_beams()
			return
	
	# Update left beam
	if left_ray.is_colliding():
		var collider = left_ray.get_collider()
		var collision_point = left_ray.get_collision_point()
		
		# Only adjust beam length if collider is not an observer
		if not collider.is_in_group("observers"):
			var local_collision = left_beam.global_transform.affine_inverse() * collision_point
			var distance = local_collision.length()
			
			# Keep direction unchanged, only adjust length
			var scaled_dir = original_directions["left"] * min(distance, original_lengths["left"])
			left_beam.points[1] = scaled_dir
		else:
			# For observers, maintain full length
			left_beam.points[1] = original_directions["left"] * original_lengths["left"]
		
		if collider:
			check_and_notify_receiver(collider, left_ray.global_position, collision_point, SPLIT_INTENSITY)
	else:
		# Use original length when no collision
		left_beam.points[1] = original_directions["left"] * original_lengths["left"]
	
	# Update glow effects
	update_glow_layers(left_beam)
	
	beam_endpoints["left"] = left_beam.points[1]
	
	# Update right beam
	if right_ray.is_colliding():
		var collider = right_ray.get_collider()
		var collision_point = right_ray.get_collision_point()
				
		# Only adjust beam length if collider is not an observer
		if not collider.is_in_group("observers"):
			var local_collision = right_beam.global_transform.affine_inverse() * collision_point
			var distance = local_collision.length()
			
			# Keep direction unchanged, only adjust length
			var scaled_dir = original_directions["right"] * min(distance, original_lengths["right"])
			right_beam.points[1] = scaled_dir
		else:
			# For observers, maintain full length
			right_beam.points[1] = original_directions["right"] * original_lengths["right"]
		
		if collider:
			check_and_notify_receiver(collider, right_ray.global_position, collision_point, SPLIT_INTENSITY)
	else:
		# Use original length when no collision
		right_beam.points[1] = original_directions["right"] * original_lengths["right"]
	
	# Update glow effects
	update_glow_layers(right_beam)
	
	beam_endpoints["right"] = right_beam.points[1]

func check_disturbance() -> void:
	var old_state := is_disturbed
	is_disturbed = false
	
	# Check if main beam is blocked
	if main_ray.is_colliding():
		var main_collider = main_ray.get_collider()
		if main_collider.is_in_group("obstacles"):
			# Main beam blocked, all subsequent beams should disappear
			hide_all_subsequent_beams()
			return
	
	# Check both beams of first splitter
	var left_blocked = false
	var right_blocked = false
	
	for ray in [left_ray, right_ray]:
		if ray.is_colliding():
			var collider = ray.get_collider()
			if collider.is_in_group("obstacles"):
				if ray == left_ray:
					left_blocked = true
				else:
					right_blocked = true
			elif collider.is_in_group("observers"):
				# Check if the observer or its parent is powered
				var observer = collider
				# If this is the Area2D, get its parent which is the actual Observer
				if not observer.has_method("power") and observer.get_parent() and observer.get_parent().get_parent():
					observer = observer.get_parent().get_parent()  # Get to the Observer node
				
				# Only trigger disturbance if the observer is powered
				if observer.has_method("power") and "is_powered" in observer and observer.is_powered:
					is_disturbed = true

	
	# If both beams are blocked
	if left_blocked and right_blocked:
		hide_all_subsequent_beams()
		return
		
	# Update beam intensities when state changes
	if old_state != is_disturbed:
		update_beam_intensities()

func hide_all_subsequent_beams() -> void:
	# Hide first splitter beams
	left_beam.visible = false
	right_beam.visible = false
	# Hide second splitter beams
	left_beam2.visible = false
	right_beam2.visible = false
	# Hide output beam
	output_beam.visible = false
	
	# Disable all related RayCast2Ds
	left_ray.enabled = false
	right_ray.enabled = false
	left_ray2.enabled = false
	right_ray2.enabled = false
	output_ray.enabled = false
	
	# Hide all related glow effects
	update_glow_visibility(left_beam, false)
	update_glow_visibility(right_beam, false)
	update_glow_visibility(left_beam2, false)
	update_glow_visibility(right_beam2, false)
	update_glow_visibility(output_beam, false)
	
	# Ensure RayCast2Ds are re-enabled next frame
	call_deferred("enable_raycasts")

func enable_raycasts() -> void:
	left_ray.enabled = true
	right_ray.enabled = true
	left_ray2.enabled = true
	right_ray2.enabled = true
	output_ray.enabled = true

func update_second_split() -> void:
	# Update left beam (upper path)
	if is_disturbed and left_ray2.is_colliding():
		var collider = left_ray2.get_collider()
		var collision_point = left_ray2.get_collision_point()
		
		# Only adjust beam length if collider is not an observer
		if not collider.is_in_group("observers"):
			var local_collision = left_beam2.global_transform.affine_inverse() * collision_point
			var distance = local_collision.length()
			
			# Keep direction unchanged, adjust length without original length limit
			var scaled_dir = original_directions["left2"] * distance
			left_beam2.points[1] = scaled_dir
		else:
			# For observers, maintain full length
			left_beam2.points[1] = original_directions["left2"] * original_lengths["left2"]
		
		check_and_notify_receiver(collider, left_ray2.global_position, collision_point, SPLIT_INTENSITY)
	else:
		# For no collision, extend to maximum detection distance
		left_beam2.points[1] = original_directions["left2"] * 2000
	
	# Update right beam (lower path)
	if right_ray2.is_colliding():
		var collider = right_ray2.get_collider()
		var collision_point = right_ray2.get_collision_point()
		
		# Only adjust beam length if collider is not an observer
		if not collider.is_in_group("observers"):
			var local_collision = right_beam2.global_transform.affine_inverse() * collision_point
			var distance = local_collision.length()
			
			# Keep direction unchanged, adjust length without original length limit
			var scaled_dir = original_directions["right2"] * distance
			right_beam2.points[1] = scaled_dir
		else:
			# For observers, maintain full length
			right_beam2.points[1] = original_directions["right2"] * original_lengths["right2"]
		
		check_and_notify_receiver(collider, right_ray2.global_position, collision_point, SPLIT_INTENSITY)
	else:
		# For no collision, extend to maximum detection distance
		right_beam2.points[1] = original_directions["right2"] * 2000
	
	# Show/hide upper path beam based on disturbance state
	left_beam2.visible = is_disturbed
	update_glow_visibility(left_beam2, is_disturbed)
	
	# Update glow effects
	update_glow_layers(left_beam2)
	update_glow_layers(right_beam2)
	
	beam_endpoints["left2"] = left_beam2.points[1] if is_disturbed else Vector2.ZERO
	beam_endpoints["right2"] = right_beam2.points[1]

func update_output_beam() -> void:
	if output_ray.is_colliding():
		var collider = output_ray.get_collider()
		var collision_point = output_ray.get_collision_point()
		
		# Only adjust beam length if collider is not an observer
		if not collider.is_in_group("observers"):
			var local_collision = output_beam.global_transform.affine_inverse() * collision_point
			var distance = local_collision.length()
			
			# Keep direction unchanged, only adjust length
			var scaled_dir = original_directions["output"] * min(distance, original_lengths["output"])
			output_beam.points[1] = scaled_dir
		else:
			# For observers, maintain full length
			output_beam.points[1] = original_directions["output"] * original_lengths["output"]
		
		check_and_notify_receiver(collider, output_ray.global_position, collision_point, FULL_INTENSITY)
	else:
		# Use original length when no collision
		output_beam.points[1] = original_directions["output"] * original_lengths["output"]
	
	# Update glow effects
	update_glow_layers(output_beam)
	
	beam_endpoints["output"] = output_beam.points[1]

func update_glow_layers(beam: Line2D) -> void:
	# Update all glow layers
	update_single_glow(beam, beam_glows)
	update_single_glow(beam, beam_outer_glows)
	update_single_glow(beam, beam_outer_glows_2)

func update_single_glow(beam: Line2D, glow_dict: Dictionary) -> void:
	if glow_dict.has(beam.name):
		var glow = glow_dict[beam.name]
		glow.points = beam.points.duplicate()
		glow.visible = beam.visible

func update_glow_visibility(beam: Line2D, vis: bool) -> void:
	# Update visibility for all glow layers associated with the specified beam
	if beam_glows.has(beam.name):
		beam_glows[beam.name].visible = vis
	if beam_outer_glows.has(beam.name):
		beam_outer_glows[beam.name].visible = vis
	if beam_outer_glows_2.has(beam.name):
		beam_outer_glows_2[beam.name].visible = vis

func check_and_notify_receiver(collider: Node, from_pos: Vector2, collision_point: Vector2, intensity: float) -> void:
	if collider and collider.is_in_group("Output") and collider.has_method("receive_beam"):
		collider.receive_beam(from_pos, collision_point, intensity)

func update_beam_intensities() -> void:
	# Main beam maintains full intensity
	main_beam.default_color.a = FULL_INTENSITY
	update_glow_alpha(main_beam, FULL_INTENSITY)
	
	# First splitter beams also use full intensity to appear brighter
	left_beam.default_color.a = FULL_INTENSITY / 2
	right_beam.default_color.a = FULL_INTENSITY / 2
	update_glow_alpha(left_beam, FULL_INTENSITY)
	update_glow_alpha(right_beam, FULL_INTENSITY)
	
	# Second splitter beam intensities
	if is_disturbed:
		# Disturbed state: both beams at half intensity
		left_beam2.default_color.a = SPLIT_INTENSITY
		right_beam2.default_color.a = SPLIT_INTENSITY
		output_beam.default_color.a = SPLIT_INTENSITY
		update_glow_alpha(left_beam2, SPLIT_INTENSITY)
		update_glow_alpha(right_beam2, SPLIT_INTENSITY)
		update_glow_alpha(output_beam, SPLIT_INTENSITY)
	else:
		# Normal state: only lower path beam at full intensity
		right_beam2.default_color.a = FULL_INTENSITY
		output_beam.default_color.a = FULL_INTENSITY
		update_glow_alpha(right_beam2, FULL_INTENSITY)
		update_glow_alpha(output_beam, FULL_INTENSITY)

func update_glow_alpha(beam: Line2D, intensity: float) -> void:
	# Update transparency for all glow layers
	if beam_glows.has(beam.name):
		beam_glows[beam.name].default_color.a = BEAM_GLOW_COLOR.a * intensity
	
	if beam_outer_glows.has(beam.name):
		beam_outer_glows[beam.name].default_color.a = OUTER_GLOW_COLOR.a * intensity
	
	# Outermost glow controlled by pulse effect, only set base transparency here
	if beam_outer_glows_2.has(beam.name):
		# Preserve pulse effect but adjust base intensity
		var base_alpha = OUTER_GLOW_2_COLOR.a * intensity
		var current_alpha = beam_outer_glows_2[beam.name].default_color.a
		var ratio = current_alpha / OUTER_GLOW_2_COLOR.a  # Current pulse ratio
		beam_outer_glows_2[beam.name].default_color.a = base_alpha * ratio
