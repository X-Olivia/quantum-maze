extends Node2D
class_name EntanglementMachine

var connections: Array[Entanglement] = []

var collapsed: bool = false

var memory: int = -1:
	set(new_memory):
		memory = new_memory
		%Screen.animation = '?' if memory == -1 else str(memory)
		if memory != -1:
			$CertaintyTimer.start()

var is_certain: bool = false
	

func revert() -> void:
	collapsed = false
	set_physics_process(true)
	
	memory = -1
	is_certain = false
	%Button.scale.y = 1


func update(_source: Node2D, value: int) -> void:
	memory = value
	

func collapse() -> void:
	collapsed = true
	set_physics_process(false)
	
	if memory == -1:
		memory = randi_range(0, 1)
	
	%Button.scale.y = 0.5
	
	for connection in connections.duplicate():
		connection.update(self, memory)


func _physics_process(_delta: float) -> void:
	if not collapsed:
		for body in %Button.get_overlapping_bodies():
			if body is Player and body.mode == Globals.Modes.PARTICLE:
				collapse()


func _on_certainty_timer_timeout() -> void:
	is_certain = true
