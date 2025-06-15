extends StaticBody2D

var is_up: bool = true
var up_wires: Array[Wire] = []
var down_wires: Array[Wire] = []

const tween_duration: float = 0.5
const max_rotation: float = 40

@onready var start_rotation: float = rotation_degrees
@onready var invert: float = 1 if sign(scale.x) == sign(scale.y) else -1


var tweening := false
func rotate_switch() -> void:
	if tweening:
		return
	tweening = true
	
	var switch_rotation = start_rotation + (invert * max_rotation if is_up else 0.0)
	var area_rotation = invert * 180.0 - max_rotation if is_up else 0.0
	
	var tween: Tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, "rotation_degrees", switch_rotation, tween_duration).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Area2D, "rotation_degrees", area_rotation, tween_duration).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(Callable(self, "toggle_power"))


func toggle_power() -> void:
	tweening = false
	is_up = not is_up
	
	for wire in up_wires:
		if is_up:
			wire.power()
		else:
			wire.unpower()
	for wire in down_wires:
		if is_up:
			wire.unpower()
		else:
			wire.power()
	
	Signals.update_navigation()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not (body is Player and body.mode == Globals.Modes.PARTICLE):
		return
	
	# Make sure player is moving into the switch (trying to push it)
	#var push_dir = Vector2.DOWN if is_up else Vector2.UP
	#var vel = body.previous_velocity.normalized().rotated(global_rotation)
	#var y = vel.y * scale.y
		#
	#if sign(y) == invert * (1 if is_up else -1):
	rotate_switch()


func connect_wire(wire: Wire, connection_point: Vector2) -> void:
	if to_local(connection_point).y < 0:
		up_wires.append(wire)
		wire.power()
	else:
		down_wires.append(wire)
