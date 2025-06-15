extends StaticBody2D

@onready var indicator = $ActiveIndicator

@export var linked_door: NodePath
var door_node: Node2D
var is_activated = false  # 激活状态
var wires = []  # 存储连接的wire
var current_beam_intensity = 0.0  # 当前接收到的光束强度

func _ready():
	# 将自己添加到Output组，使wire系统能识别
	add_to_group("Output")
	
	# 如果有链接的门，进行初始化
	if !linked_door.is_empty():
		door_node = get_node(linked_door)
		if door_node && door_node.is_in_group("Input"):
			door_node.on_connection()
	
	# 初始化为未激活状态
	reset_activation()

func receive_beam(_from_pos: Vector2, _collision_point: Vector2, intensity: float):
	current_beam_intensity = intensity
	
	# 只有当接收到足够强度的光束时才激活
	if current_beam_intensity > 0:
		if !is_activated:
			is_activated = true
			# 更新指示器颜色
			indicator.color = Color(0.8, 0.9, 1.0)  # 激活时显示绿色
			# 激活门和wire
			power_connected_elements()
	else:
		reset_activation()

func reset_activation():
	is_activated = false
	current_beam_intensity = 0.0
	indicator.color = Color(0.2, 0.2, 0.2, 1.0)  # 未激活时显示灰色
	
	# 可选：取消激活连接的元素
	if door_node && door_node.has_method("unpower"):
		door_node.unpower()
	
	for wire in wires:
		if wire.has_method("unpower"):
			wire.unpower()

# Wire连接功能
func connect_wire(wire, _connection_point):
	wires.append(wire)
	
	# 如果已激活，立即激活连接的wire
	if is_activated:
		wire.power()

# 激活所有连接的元素
func power_connected_elements():
	# 直接连接的门
	if door_node && door_node.has_method("power"):
		door_node.power()
	
	# 通过wire连接的元素
	for wire in wires:
		wire.power()

func _process(_delta):
	# 每帧检查是否需要重置
	# 如果一段时间没有收到光束信号，就重置状态
	if is_activated && current_beam_intensity <= 0:
		reset_activation()
	
	# 重置当前帧的光束强度，等待下一帧的更新
	current_beam_intensity = 0.0

func _exit_tree():
	# 节点移除时重置状态
	reset_activation()
