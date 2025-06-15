extends Area2D
class_name ProbabilityDetector

var wires: Array[Wire] = []


func power() -> void:
	if $Timer.is_stopped():
		for wire in wires:
			wire.power()
		$Timer.start()


func _on_timer_timeout() -> void:
	for wire in wires:
		wire.unpower()
