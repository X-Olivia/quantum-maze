extends StaticBody2D

# Preload the button image so we can update image on pressed
var not_powered_image = preload("res://assets/images/electrical outputs/solar_panel_off.png")
var powered_image = preload("res://assets/images/electrical outputs/solar_panel_on.png")

var wires: Array[Wire] = []

var powered: bool = false
var photon_power: bool = false

## Detect if solar panel is hit by a photon
func damage(value: Variant) -> void:
	if value is Dictionary and value.has("callee") and value.callee is Photon:
		if $Timer.is_stopped():
			photon_power = true
			$Timer.start()


## Photon energy runs out
func _on_timer_timeout() -> void:
	photon_power = false


## Detect player shield overlapping to power the solar panel from photons or the shield
func _physics_process(_delta: float) -> void:
	
	var shield_power: bool = false
	for area in $Area2D.get_overlapping_areas():
		if area is ParryAbility and area.can_power and area.blocking:
			shield_power = true
			break
	
	var was_powered: bool = powered
	powered = photon_power or shield_power
	
	# Unpowering solar panel
	if was_powered and not powered:
		$Image.texture = not_powered_image
		for wire in wires:
			wire.unpower()
	# Powering solar panel
	elif not was_powered and powered:
		$Image.texture = powered_image
		for wire in wires:
			wire.power()
