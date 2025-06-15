extends Area2D
class_name Photon

@export var speed : float = 1000
@export var lifetime: float = 15

@export var base_damage: float = 20
var damage: float = base_damage

var can_damage := true

@onready var direction : Vector2 = Vector2.RIGHT.rotated(global_rotation)

## Whether the photon has been deflected or not
var parried := false


func _ready() -> void:
	get_tree().create_timer(30).timeout.connect(func(): queue_free())


func set_direction(photonDirection):
	direction = photonDirection
	rotation_degrees = rad_to_deg(global_position.angle_to_point(global_position+direction))


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_body_shape_entered(body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if can_damage and body.has_method("damage"):
		body.call_deferred("damage", {"callee": self, "collider": body_rid, "damage": damage})
	queue_free()
