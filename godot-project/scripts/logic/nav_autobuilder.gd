extends NavigationRegion2D

const AGENT_RADIUS: float = 48


## ONLY SET TO TRUE FOR TINY LEVELS! CAUSES UNPLAYABLE LAG FOR BIG LEVELS
@export var dynamic := false


func _ready() -> void:
	global_position = Vector2.ZERO
	
	calculate_navigation()
	
	if dynamic:
		push_warning("Updating navigation dynamically! A very bad idea for large levels")
		Signals.navigation_needs_update.connect(Callable(self, "calculate_navigation"))


### 
# Calculates navigation polygon from the floor tiles for the whole level
# Incredibily slow so called only once when the level is loaded
func calculate_navigation() -> void:
	
	navigation_polygon = NavigationPolygon.new()
	navigation_polygon.parsed_collision_mask = 0b00000010  # Walls
	
	var geometry_data := NavigationMeshSourceGeometryData2D.new()
	NavigationServer2D.parse_source_geometry_data(navigation_polygon, geometry_data, Globals.floor_tiles)
	
	navigation_polygon.agent_radius = 0
	NavigationServer2D.bake_from_source_geometry_data(navigation_polygon, geometry_data)
	
	var vertex_data = navigation_polygon.get_vertices()
	for i in range(navigation_polygon.get_polygon_count()):
		var poly_indices = navigation_polygon.get_polygon(i)
		var poly_points = []
		for index in poly_indices:
			poly_points.append(vertex_data[index])
		navigation_polygon.add_outline(poly_points)
	
	navigation_polygon.agent_radius = AGENT_RADIUS
	bake_navigation_polygon()
		
	queue_redraw()


func get_level(node: Node) -> LevelManager:
	while node:
		if node is LevelManager:
			return node as LevelManager
		node = node.get_parent()
	return null
