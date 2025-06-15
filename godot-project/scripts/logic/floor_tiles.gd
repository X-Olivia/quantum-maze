extends TileMapLayer


func _ready() -> void:
	Globals.floor_tiles = self
	

## Returns whether the tile at a given global point has a given name
func is_name(global_coords: Vector2, tile_name: String) -> bool:
	var tile_coords = local_to_map(to_local(global_coords))
	var tile_data = get_cell_tile_data(tile_coords)
	if tile_data:
		return tile_data.get_custom_data("name") == tile_name
	return false
