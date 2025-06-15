extends Area2D
class_name TutorialTrigger


@export_multiline var tutorial_text: String = ""
@export var bounce_height: float = 7.0
@export var bounce_duration: float = 1.0

var tween: Tween

func _ready() -> void:
	tween = create_tween().set_loops()
	tween.tween_property(self, "position:y", 
		position.y - bounce_height, bounce_duration/2.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", 
		position.y + bounce_height, bounce_duration/2.0).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body):
	if body is Player:
		Globals.hud.update_tutorial_box(tutorial_text)

func _on_body_exited(body):
	if body is Player:
		Globals.hud.hide_tutorial_box()
