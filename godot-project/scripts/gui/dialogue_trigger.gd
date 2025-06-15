extends Area2D
class_name DialogueTrigger

@export_multiline var pages: Array[String] = []
var one_time_only := true
var has_triggered := false


func _on_body_entered(body):
	if one_time_only and has_triggered:
		return
		
	if body is Player:
		has_triggered = true
		Globals.hud.update_dialogue_box(pages)
