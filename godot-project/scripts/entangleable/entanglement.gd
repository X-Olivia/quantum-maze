extends Node2D
class_name Entanglement


@export var a: Node2D = null
@export var b: Node2D = null

@export var invert: bool = false
var natural: bool = true

var a_last_pos: Vector2
var b_last_pos: Vector2


func _ready() -> void:
	if a and b:
		a_last_pos = a.global_position
		b_last_pos = b.global_position
		
		a.connections.append(self)
		b.connections.append(self)
		
		queue_redraw()


func destroy() -> void:
	if not natural:
		a.connections.erase(self)
		b.connections.erase(self)
		queue_free()


func revert() -> void:
	if natural:
		visible = true
		set_physics_process(true)
	else:
		destroy()


func update(source: Node2D, memory: int) -> void:
	if not visible:
		return
	visible = false
	set_physics_process(false)
	
	if invert:
		memory = 1 if memory == 0 else 0
	
	if source == a:
		b.update(source, memory)
	elif source == b:
		a.update(source, memory)
		
	destroy()
		

func _physics_process(_delta: float) -> void:
	if a.global_position != a_last_pos or b.global_position != b_last_pos:
		a_last_pos = a.global_position
		b_last_pos = b.global_position
		queue_redraw()


func _draw() -> void:
	var colour: Color = Color.BLACK if invert else Color.WHITE
	draw_line(to_local(a.global_position), to_local(b.global_position), colour, 10)
