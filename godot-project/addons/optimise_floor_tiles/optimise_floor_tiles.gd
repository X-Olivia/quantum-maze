@tool
extends EditorPlugin


var button: Button


func _enter_tree() -> void:
	button = Button.new()
	button.text = "Optimise Floor Tiles"
	button.pressed.connect(Callable(self, "on_button_pressed"))
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, button)


###
# Deletes floor tiles that are covered by a non-transparent wall tile.
# Does NOT delete floor tiles that are hazardous and contain no other custom data.
# This preserves navigation blocking tiles.
func on_button_pressed() -> void:
	var level = get_editor_interface().get_edited_scene_root()
	if level and level is LevelManager:
		
		var floor: TileMapLayer = level.get_node("FloorTiles")
		var walls: TileMapLayer = level.get_node("WallTiles")
		
		for coord in walls.get_used_cells():
			var wall_tile: TileData = walls.get_cell_tile_data(coord)
			if wall_tile and not wall_tile.get_custom_data("transparent"):
				var floor_tile: TileData = floor.get_cell_tile_data(coord)
				if floor_tile:# and not floor_tile.get_custom_data("nav blocking"):
					floor.erase_cell(coord)
						
		print("OPTIMISED FLOOR TILES")


func _exit_tree() -> void:
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, button)
