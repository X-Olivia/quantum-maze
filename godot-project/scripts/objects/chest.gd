extends StaticBody2D
class_name Chest


@onready var energy_item_scene = preload("res://scenes/objects/energy_item.tscn")

## The number of energy items/photons to 
@export var energy_item_num: int = 0
@export_range(0.0, 1.0) var big_probability: float = 0.1

## Spread cone width (in degrees)
const angle = 45
## Minimum speed items can be ejected
const min_mag = 150
## Maximum speed items can be ejected
const max_mag = 230
## Deceleration on ejected items
const deceleration = 100

## If the chest has been opened
var opened: bool = false

## Dictionary of item nodes with their current velocities. Entries are deleted when items are stationary.
var velocities: Dictionary = {}


func _ready() -> void:
	set_physics_process(false)
	
	for item in get_children():
		if item not in [$CollisionShape2D, $Body, $Lid, $EnemySpawnpoint]:
			velocities[item] = {"mag": 0, "dir": Vector2.ZERO}
			item.global_rotation = 0.0
			item.global_position = $EnemySpawnpoint.global_position if item is Enemy else global_position
			toggle(item, false)


func toggle(item: Node2D, state: bool) -> void:
	item.visible = state
	
	if item is Enemy:
		item.get_node("CollisionShape2D").disabled = not state
		
	item.set_process(state)
	item.set_physics_process(state)


func eject(item: Node2D) -> void:
	var data = velocities.get(item)
	if data:
		toggle(item, true)
		if item is not Enemy:
			data.mag = randf_range(min_mag, max_mag)
			data.dir = Vector2.RIGHT.rotated(global_rotation + randf_range(-1, 1) * deg_to_rad(angle))
	

func damage(_value: Variant) -> void:
	if opened:
		return
	opened = true
	
	var tween = create_tween()
	tween.tween_property($Lid, "scale:x", 0.5, 0.5).set_ease(Tween.EASE_OUT)
	tween.finished.connect(open)
	
	
func open() -> void:
	for i in range(energy_item_num):
		var energy_item = energy_item_scene.instantiate()
		if randf() <= big_probability:
			energy_item.small = false
		velocities[energy_item] = {"mag": 0, "dir": Vector2.ZERO}
		add_child(energy_item)
		
	for child in get_children():
		eject(child)
		
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	for item in velocities.keys():
		
		var end: bool = not is_instance_valid(item) or (item is Prism and item.is_picked_up)
		
		if not end:
			var vel = velocities.get(item)
			item.global_position += vel.mag * vel.dir * delta
			vel.mag -= deceleration * delta
			if vel.mag <= 0:
				end = true
		
		if end:
			velocities.erase(item)
				
	if velocities.is_empty():
		set_physics_process(false)
	
