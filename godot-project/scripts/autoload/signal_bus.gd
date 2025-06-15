extends Node

signal entanglement_created(data: Dictionary)
signal navigation_needs_update
signal died(death_type: String)
signal level_loaded(level_id: String)
signal level_unloaded


func emit_create(data: Dictionary) -> void:
	entanglement_created.emit(data)


func update_navigation():
	navigation_needs_update.emit()


func emit_died(death_type: String = "default"):
	died.emit(death_type)


func emit_level_loaded(level_id: String):
	level_loaded.emit(level_id)


func emit_level_unloaded():
	level_unloaded.emit()
