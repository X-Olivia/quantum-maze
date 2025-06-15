extends Area2D
class_name GhostTrigger


@export var ghost_name_id: String
@export var one_time := true
@export var always_physical := false
@export var invisible := false

@onready var manager: PlayerManager = get_parent().get_parent()

const ghost_scene: PackedScene = preload("res://scenes/player/ghost.tscn")

var has_triggered := false


func spawn_ghost() -> void:
	var data_str = Globals.level.data.ghost_data.get(ghost_name_id)
	if data_str:
		# Loading recording data
		var data: Dictionary[int, Array] = Marshalls.base64_to_variant(data_str)
		for value: Array in data.values():
			value.reverse()
				
		# Creating initial Ghost
		var ghost: Ghost = ghost_scene.instantiate()
		ghost.setup(data, 0, ghost_scene, always_physical, invisible)
		manager.call_deferred("add_child", ghost)
	else:
		push_warning("GHOST SPAWN FAILURE: Data not found for ghost '" + ghost_name_id + "'")
	

var player: Player = null
func _on_body_entered(body):
	if body is Player and body is not Ghost and not has_triggered:
		player = body
		has_triggered = true
		spawn_ghost()


func _on_body_exited(body: Node2D) -> void:
	if player and body == player and not one_time:
		has_triggered = false
