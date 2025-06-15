extends Area2D


@export_enum("Dash", "Parry", "Shoot", "Entanglement") var ability: String
@export_file("*.png", "*.jpg") var image: String = ""


func _ready() -> void:
	if image:
		$Sprite2D.texture = image


func _on_body_entered(body: Node2D) -> void:
	if body is Player and body.mode == Globals.Modes.PARTICLE:
		body.get_node("%" + ability + "Ability").active = true
		Globals.level.temp_ability_config[ability.to_lower()] = true
		queue_free()
