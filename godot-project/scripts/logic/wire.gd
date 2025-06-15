extends Path2D
class_name Wire

## The input node the wire connects to (eg: Door)
var input: Node2D = null

## Whether the wire currently has power
var powered: bool = false

@export var colour := Color.WHITE

# Display constants
const width: int = 8
const powered_colour: String = "#cce7fe"  # pale blue, pale yellow = "#ffff8f"
const unpowered_colour: String = "#262626"


###
# Sets up the wire by finding its connections
# Uses physics queries to assign and handle input and output nodes
# Sets the wire's colour
func _ready() -> void:
	
	modulate = colour
	
	var start: Vector2 = to_global(curve.get_point_position(0))
	var end: Vector2 = to_global(curve.get_point_position(curve.get_point_count() - 1))
	
	var node1: Node2D = get_connection(start)
	var node2: Node2D = get_connection(end)
	
	if not node1 and not node2:
		return
	
	var is_input_1: bool = node1 and node1.is_in_group("Input")
	var is_input_2: bool = node2 and node2.is_in_group("Input")

	var output: Node2D
	input = node1 if is_input_1 else (node2 if is_input_2 else null)
	output = node2 if is_input_1 else (node1 if is_input_2 else null)
		
	# Alert input nodes on connection (eg: Door)
	if input and input.has_method("on_connection"):
		input.on_connection()
	
	# Storing wire in output node connections array
	# If output node has multiple sets of wires (eg: Switch)
	# call its connect_wire function to pick instead.
	if output:
		if output.has_method("connect_wire"):
			var output_point: Vector2 = start if node1 == output else end
			output.connect_wire(self, output_point)
		elif "wires" in output:
			output.wires.append(self)


###
# Runs a physics query to find the input or output node at a point
# 
# Arguments
# - point : The point being queried (in global coordinates)
# 
# Return : A dictionary with the node and its type, "Input", "Output" or ""
func get_connection(point: Vector2) -> Node2D:
	var space_state = get_world_2d().direct_space_state

	var query = PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result = space_state.intersect_point(query)

	for hit in result:
		var node = input_or_output(hit.collider)
		if node:
			return node
	return null


###
# Tracks a node up the scene tree it see if it is in the global group "Input" or "Output", 
# or any of its parents are
# 
# Arguments
# - node : The node to check
#
# Return : The input or output node, or null if none is found
func input_or_output(node: Node) -> Node2D:
	while node:
		if node.is_in_group("Input") or node.is_in_group("Output"):
			return node
		node = node.get_parent()
	return null


## Draws the wire the right colour depending on if it's powered
func _draw() -> void:
	var col := Color(powered_colour if powered else unpowered_colour)
	draw_polyline(curve.get_baked_points(), col, width)


## Powers the wire's input node
func power() -> void:
	powered = true
	queue_redraw()
	if input:
		input.power()


## Unpowers the wire's input node
func unpower() -> void:
	powered = false
	queue_redraw()
	if input:
		input.unpower()
