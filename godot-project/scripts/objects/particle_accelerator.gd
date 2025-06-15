extends Node2D
class_name Accelerator


@onready var left: Vector2 = $LeftMarker.global_position
@onready var right: Vector2 = $RightMarker.global_position

@export var active := true


func _on_effect_area_body_entered(body: Node2D) -> void:
	if not active or body is not Player:
		return
		
	var dash_ability = body.get_node("%DashAbility")
	
	if dash_ability and $Timer.is_stopped():
		$Timer.start()
		
		var direction: Vector2
		if body.global_position.distance_squared_to(right) < body.global_position.distance_squared_to(left):
			body.global_position = right
			direction = right.direction_to(left)
		else:
			body.global_position = left
			direction = left.direction_to(right)
		
		dash_ability.dash(direction)
