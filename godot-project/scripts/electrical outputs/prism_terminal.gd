extends Area2D

@export var colour := Color.WHITE

var wires: Array[Wire] = []

var prism: Area2D = null

var connected: bool = false

# Add a light effect node for the glow
var light_effect: PointLight2D = null


func _ready() -> void:
	# Create light effect node
	light_effect = PointLight2D.new()
	light_effect.texture = load("res://assets/images/objects/light.tres") # Use existing light texture
	light_effect.color = Color.WHITE
	light_effect.energy = 0.7 # Slightly reduced energy for a softer glow
	light_effect.texture_scale = 0.5 # Increased scale for a wider, softer glow
	light_effect.enabled = false
	add_child(light_effect)


func _physics_process(_delta: float) -> void:
	
	if prism == null:
		return

	var was_connected: bool = connected
	if not prism.is_picked_up:
		prism.global_position = global_position
		connected = true
		
		# Enable the glow effect on the prism
		if light_effect and light_effect.get_parent() != prism:
			remove_child(light_effect)
			prism.add_child(light_effect)
		if light_effect:
			light_effect.enabled = true
	else:
		connected = false
		# Disable the glow effect
		if light_effect:
			light_effect.enabled = false
	
	if connected != was_connected:
		if connected:
			for wire in wires:
				wire.power()
		else:
			for wire in wires:
				wire.unpower()
		

func _on_area_entered(area: Area2D) -> void:
	if area is Prism and area.colour == colour:
		prism = area


func _on_area_exited(area: Area2D) -> void:
	if area is Prism and area.colour == colour:
		prism = null
		# Make sure to disable the light effect when prism exits
		if light_effect:
			light_effect.enabled = false
