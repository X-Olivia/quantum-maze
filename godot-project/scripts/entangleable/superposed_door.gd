extends StaticBody2D


var connections: Array[Entanglement] = []

var collapsed: bool = false


func revert() -> void:
	collapsed = false
	%Sprite.modulate = Color.hex(0xffffff7f)
	$CollisionShape2D.disabled = false


func update(_source: Node2D, value: int) -> void:
	collapsed = true
	
	if value == 1:
		$CollisionShape2D.disabled = true
		%Sprite.modulate = Color.TRANSPARENT
	elif value == 0:
		%Sprite.modulate = Color.WHITE
	
	for connection in connections.duplicate():
		connection.update(self, value)
