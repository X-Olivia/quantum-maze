extends StaticBody2D

var connections: Array[Entanglement] = []

var collapsed: bool = false


func revert() -> void:
	collapsed = false
	$Eye.animation = "narrow"
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	var detected_certain = false
	for connection in connections:
		var other = connection.a if connection.b == self else connection.b
		if not other.collapsed and "is_certain" in other and other.is_certain:
			detected_certain = true
			break
	$Eye.animation = "wide" if detected_certain else "narrow"


func update(source: Node2D, value: int) -> void:
	if "is_certain" in source and source.is_certain:
		collapsed = true
		set_physics_process(false)
		$Eye.animation = "closed"
		for connection in connections.duplicate():
			connection.update(self, value)
