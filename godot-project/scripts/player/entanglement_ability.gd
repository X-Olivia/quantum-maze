extends Area2D

@export var active: bool = false

@onready var player: CharacterBody2D = get_parent()


var a: Node2D = null:
	set(new_a):
		if a != new_a:
			if new_a:
				new_a.modulate = Color(strong, strong, strong)
			elif a:
				a.modulate = Color.WHITE
		a = new_a
			
var b: Node2D = null:
	set(new_b):
		if b != new_b:
			if new_b:
				new_b.modulate = Color(strong, strong, strong)
			elif b:
				b.modulate = Color.WHITE
		b = new_b

var can_create: bool = true

const weak = 1.2
const strong = 1.6

var nodes_in_range = []
var valid: bool = false


func _process(_delta: float) -> void:
	
	var was_valid: bool = valid
	valid = active and player.active and player.mode == Globals.Modes.WAVE and can_create
	
	monitorable = valid
	monitoring = valid
	visible = valid
	
	if not valid:
		if was_valid:
			for node in nodes_in_range:
				node.modulate = Color.WHITE
		return
	
	highlight_nodes()
		
	global_position = get_global_mouse_position()
	
	var lclicked: bool = Input.is_action_just_pressed("lclick")
	var rclicked: bool = Input.is_action_just_pressed("rclick")
	
	if not lclicked and not rclicked:
		return
	
	var selection = select()
	
	if not selection:
		return
	
	if selection == a:
		a = null
	elif selection == b:
		b = null
	elif not a:
		a = selection
	elif not b:
		b = selection
	
	# Send an entanglement request for a and b
	if a and b:
		var invert: bool = rclicked
		
		if player.manager.recording and a.has_meta("uuid") and b.has_meta("uuid"):
			player.record.add("ENTANGLEMENT", {"a_uuid": a.get_meta("uuid"), "b_uuid": b.get_meta("uuid"), "invert": invert, "natural": false})
		
		Signals.emit_create({"a": a, "b": b, "invert": invert, "natural": false})
		can_create = Globals.DEBUG
		a = null
		b = null


func highlight_nodes() -> void:
	
	var new_nodes_in_range = get_entangleables_in_range(player.wave_area)
	
	# Create dictionaries from arrays
	var old_set = {}
	for node in nodes_in_range:
		old_set[node] = true
	var new_set = {}
	for node in new_nodes_in_range:
		new_set[node] = true

	# Build union of sets
	var union_nodes = {}
	for node in nodes_in_range:
		union_nodes[node] = true
	for node in new_nodes_in_range:
		union_nodes[node] = true

	for node in union_nodes.keys():
		if node == a or node == b:
			continue
		elif old_set.has(node) and not new_set.has(node):
			node.modulate = Color.WHITE
		else:
			node.modulate = Color(weak, weak, weak)
			
	nodes_in_range = new_nodes_in_range


func get_entangleables_in_range(area: Area2D) -> Array:
	var nodes = []
	for piece in area.get_overlapping_areas() + area.get_overlapping_bodies():
		var node = get_entangleable(piece)
		if node:
			nodes.append(node)
	return nodes


func get_entangleable(node: Node) -> Node2D:
	while node:
		if node.is_in_group("Entangleable") and not node.collapsed:
			return node
		node = node.get_parent()
	return null

	
func select() -> Node2D:
	var nodes = get_entangleables_in_range(self)
	if not nodes.is_empty():
		var node = nodes[0]
		if Globals.DEBUG or node in nodes_in_range:
			return node
	return null
