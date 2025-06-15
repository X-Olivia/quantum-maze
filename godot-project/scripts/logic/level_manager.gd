@tool
extends Node
class_name LevelManager

var entanglement_scene: PackedScene = preload("res://scenes/entangleable/entanglement.tscn")

var game: GameManager

var greyscale_shader: Shader = preload("res://assets/shaders/greyscale.gdshader")

var id: String
var data: Dictionary

var temp_ability_config: Dictionary

var is_completed: bool = false

var timer: float = 0.0

@onready var respawn_position: Vector2 = %PlayerSpawner.global_position

# Energy random fluctuation variables
var energy_fluctuation_timer: float = 0.0
const energy_fluctuation_interval: float = 1.0  
const energy_fluctuation_chance: float = 0.3    
const energy_fluctuation_magnitude: float = 0.03 
	

func _ready() -> void:
	if Engine.is_editor_hint():
		if not write_uuids(self):
			print("No UUIDs needed to be created for ", name, ".")
		
		var editor_interface = Engine.get_singleton("EditorInterface")
		if editor_interface:
			editor_interface.save_scene()
	else:
		game = get_parent()
		Signals.entanglement_created.connect(find_or_create_entanglement)


###
# Adds persistant UUIDs to Entangleable nodes in the level without a UUID,
# allowing them to still be identifiable after being moved or renamed.
# This is so Ghost recordings can find them when creating entanglements.
func write_uuids(parent: Node) -> bool:
	var change_made := false
	for node in parent.get_children():
		if node.is_in_group("Entangleable") and not node.has_meta("uuid"):
			change_made = true
			node.set_meta("uuid", new_uuid())
			print("Created UUID for ", node, ".")
		change_made = change_made or write_uuids(node)
	return change_made


## Generates a random 32 character hex value UUID that is (practically) guaranteed to be unique.
func new_uuid() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	
	var uuid: Array = []
	for i in range(32):
		var val: int = rng.randi_range(0, 15)
		uuid.append(str(val) if val < 10 else char(87 + val)) 
	
	return "".join(uuid)


func _physics_process(delta: float) -> void:
	if game and not game.paused:
		timer += delta
		
	# Energy fluctuation
	if not Engine.is_editor_hint():
		energy_fluctuation_timer += delta
		
		if energy_fluctuation_timer >= energy_fluctuation_interval:
			energy_fluctuation_timer = 0.0
			
			if randf() <= energy_fluctuation_chance:
				var fluctuation_percent = randf_range(-energy_fluctuation_magnitude, energy_fluctuation_magnitude)
				var fluctuation_amount = Globals.max_energy * fluctuation_percent
				Globals.energy += fluctuation_amount


func setup(level_id: String, level_data: Dictionary) -> void:
	id = level_id
	data = level_data
	temp_ability_config = data.ability_config.duplicate()
	
	Globals.energy = Globals.max_energy
	%PlayerManager.create_particle(temp_ability_config, respawn_position)
	
	for collectable: Collectable in get_tree().get_nodes_in_group("Collectable"):
		if level_data.collectables[collectable.id]:
			collectable.find_child("Sprite").material.shader = greyscale_shader


func activated_checkpoint(checkpoint_position: Vector2) -> void:
	respawn_position = checkpoint_position


func revert_to_checkpoint() -> void:
	Globals.wave_mode_timer = Globals.wave_mode_duration
	Globals.energy = Globals.max_energy
	
	%PlayerManager.kill_all()
	
	var initial_position = respawn_position if respawn_position else %PlayerSpawner.global_position
	
	%PlayerManager.create_particle(temp_ability_config, initial_position)
	
	for node in get_tree().get_nodes_in_group("Revertible"):
		if node.has_method("revert"):
			node.revert()


func got_collectable(collectable_id: int) -> void:
	data.collectables[collectable_id] = true


func find_or_create_entanglement(cdata: Dictionary) -> Dictionary:
	
	var a: Node2D = cdata.a
	var b: Node2D = cdata.b

	if not Engine.is_editor_hint():
		if a.collapsed or b.collapsed:
			return {"new": false, "connection": null}
	
	# Finding existing connection if one exists
	var old_connection: Entanglement = search_for_entanglement([a, b], self, false)
	if old_connection:
		return {"new": false, "connection": old_connection}
	elif cdata.has("delete_mode") and cdata.delete_mode:
		return {"new": false, "connection": null}
		
	# Creating a new connection
	var connection: Entanglement = entanglement_scene.instantiate()
	connection.a = a
	connection.b = b
	connection.global_position = (a.global_position + b.global_position) / 2
	connection.invert = cdata.invert
	
	if not Engine.is_editor_hint():
		connection.natural = cdata.natural
		
	add_child(connection)
	connection.set_owner(self)
	
	return {"new": true, "connection": connection}


func search_for_entanglement(target_nodes: Array, parent: Node, DFS: bool) -> Entanglement:
	for node in parent.get_children():
		if node is Entanglement and node.a in target_nodes and node.b in target_nodes:
			return node
		elif node.is_in_group("Puzzle") or (DFS and node.get_child_count() > 0):
			var c = search_for_entanglement(target_nodes, node, true)
			if c: return c
	return null
