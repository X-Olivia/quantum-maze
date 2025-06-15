extends Node2D


func get_puzzle(node: Node) -> Node:
	while node:
		if node.is_in_group("Puzzle"):
			return node
		node = node.get_parent()
	return null


func recursive_revert(parent: Node, DFS: bool) -> void:
	if not parent:
		return
	for node in parent.get_children():
		if node.has_method("revert"):
			node.revert()
		if node.is_in_group("Puzzle") or (DFS and node.get_child_count() > 0):
			recursive_revert(node, true)
	

func reset() -> void:
	recursive_revert(Globals.level, false)
	$Timer.start()
	%Button.scale.y = 0.5


func _physics_process(_delta: float) -> void:
	if $Timer.is_stopped():
		for body in %Button.get_overlapping_bodies():
			if body is Player and body.mode == Globals.Modes.PARTICLE:
				reset()


func _on_timer_timeout() -> void:
	%Button.scale.y = 1
