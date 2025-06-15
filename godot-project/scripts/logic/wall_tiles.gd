extends TileMapLayer


func _ready() -> void:
	Globals.wall_tiles = self


###
# Erases a wall tile if it's breakable
# 
# Arguments
# - value : The RID of the tile or it's tilemap position
# 
# Return : Whether the tile was broken
func break_tile(value: Variant) -> bool:
	
	var tile_pos: Vector2i
	if value is RID:
		tile_pos = get_coords_for_body_rid(value)
	elif value is Vector2i:
		tile_pos = value
	else:
		return false
	
	var cell = get_cell_tile_data(tile_pos)
	
	if cell:
		var breakable: bool = cell.get_custom_data("breakable")
		if breakable:
			erase_cell(tile_pos)
			return true
	
	return false


func damage(value: Variant) -> Dictionary:
	var broke = false
	if value is Dictionary and value.has("collider"):
		broke = break_tile(value.collider)
	return {"stop": not broke, "revert": broke}


func get_cell_at_global_point(global_pos: Vector2) -> TileData:
	var tile_pos: Vector2i = local_to_map(to_local(global_pos))
	return get_cell_tile_data(tile_pos)
