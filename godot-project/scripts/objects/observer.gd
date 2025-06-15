extends Node2D

# Light configuration
const NORMAL_ENERGY := 0.5
const ACTIVE_ENERGY := 0.9
const TRANSITION_SPEED := 2.0

# Node references
@onready var point_light := $PointLight2D
@onready var detection_area := $PointLight2D/Area2D
@onready var detection_polygon := $PointLight2D/Area2D/CollisionPolygon2D

var target_energy := NORMAL_ENERGY
var current_energy := NORMAL_ENERGY
var is_detecting := false
var is_powered := false  # Whether the observer is powered
var wires = []  # Store connected wires

func _ready() -> void:
	# Add to observers group for beam interaction
	add_to_group("observers")
	
	# Also add the Area2D to the observers group so it can be directly detected
	detection_area.add_to_group("observers")
	
	# Initialize light
	point_light.energy = NORMAL_ENERGY
	
	# Make sure the is_powered state is false by default
	is_powered = false
	
	# Initially disable detection area (forcefully set to false)
	set_detection_enabled(false)
	
	# Set initial light energy to the unpowered state
	target_energy = NORMAL_ENERGY * 0.7
	current_energy = target_energy
	point_light.energy = current_energy
	

func _physics_process(delta: float) -> void:
	# Smoothly transition light energy
	if current_energy != target_energy:
		current_energy = lerp(current_energy, target_energy, delta * TRANSITION_SPEED)
		point_light.energy = current_energy

func _on_area_2d_area_entered(area: Area2D) -> void:
	if is_powered and area.get_parent().is_in_group("beams"):
		is_detecting = true
		target_energy = ACTIVE_ENERGY

func _on_area_2d_area_exited(area: Area2D) -> void:
	if is_powered and area.get_parent().is_in_group("beams"):
		is_detecting = false
		target_energy = NORMAL_ENERGY

# Called when the observer receives power from a button/switch
func power() -> void:
	is_powered = true
	set_detection_enabled(true)
	
	# Optional: Increase light intensity to show it's powered
	target_energy = NORMAL_ENERGY * 1.2
	

# Called when the observer is unpowered
func unpower() -> void:
	is_powered = false
	set_detection_enabled(false)
	
	# Reset light to dimmer state
	target_energy = NORMAL_ENERGY * 0.7
	is_detecting = false
	

# Called when this observer needs to handle signals from the door
func on_connection() -> void:
	# This function is required by the Input group protocol
	pass

# Wire connection functionality
func connect_wire(wire, _connection_point) -> void:
	wires.append(wire)
	
	# If already powered, power the connected wire
	if is_powered:
		wire.power()

# Enable/disable detection area
func set_detection_enabled(enabled: bool) -> void:
	# Enable/disable collision detection
	detection_area.monitoring = enabled
	detection_area.monitorable = enabled
	
	# Make the detection area completely invisible when disabled
	detection_area.visible = enabled
	
	# Disable collision by setting collision layer to 0 when not enabled
	detection_area.collision_layer = 2 if enabled else 0
	
	# Also disable the polygon's visibility
	if detection_polygon:
		detection_polygon.visible = enabled
	
	# Control light visibility and energy
	if enabled:
		point_light.energy = NORMAL_ENERGY * 1.2  # Brighter when enabled
		point_light.visible = true
	else:
		point_light.energy = NORMAL_ENERGY * 0.0  # Much dimmer when disabled
		point_light.visible = false
	
	# Forcefully disable the Area2D if not enabled
	if not enabled:
		detection_area.set_process(false)
		detection_area.set_physics_process(false)
	else:
		detection_area.set_process(true)
		detection_area.set_physics_process(true)
	
