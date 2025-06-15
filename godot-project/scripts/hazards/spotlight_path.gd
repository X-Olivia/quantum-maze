extends Path2D
class_name Spotlight

@export var speed: float = 500.0  # Speed of movement
@export var moving: bool = true
@export var loop: bool = false

@onready var path_follow: PathFollow2D = $PathFollow2D

var direction: int = 1  # 1 = forward, -1 = backward


func _ready() -> void:
	path_follow.loop = loop


func _physics_process(delta):
	if not moving:
		return
		
	path_follow.progress += speed * delta * direction # Move along the path

	# Reverse direction when reaching the end
	if path_follow.progress_ratio >= 1.0:
		direction = -1
	elif path_follow.progress_ratio <= 0.0:
		direction = 1
