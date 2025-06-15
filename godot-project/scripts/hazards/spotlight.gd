extends Area2D


func _physics_process(_delta: float) -> void:
	for area in get_overlapping_areas():
		var parent = area.get_parent()
		if parent is Player and area == parent.find_child("WaveArea"):
			parent.mode = Globals.Modes.PARTICLE
