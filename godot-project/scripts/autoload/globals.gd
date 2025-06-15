extends Node

# Debug variables
var DEBUG := true
var DEBUG_FEATURES_ON := false

## Mode an instance is in
enum Modes {PARTICLE, WAVE, UNSET}

## Reference to HUD
var hud: HUD

## Reference to the current level
var level: LevelManager

## Reference to the player (the currently active instance)
var player: Player

## Reference to the game manager
var game_manager

## 目标过渡信息
var goal_transition_info: Dictionary

## 玩家是否应该停止移动（在触发goal后）
var player_frozen: bool = false

# References to the tilemap layers
var wall_tiles: TileMapLayer
var floor_tiles: TileMapLayer

## Reference to the camera
var camera: Camera2D:
	set(node):
		camera = node
		camera.zoom = Vector2(CAMERA_ZOOM, CAMERA_ZOOM)


## Zoom level of the camera
const CAMERA_ZOOM: float = 0.6

## Maximum energy the player has
@export var max_energy: float = 100

## The player's current energy
var energy: float = max_energy:
	set(new_energy):
		energy = clampf(new_energy, 0.0, max_energy)
		hud.update_energy_bar(new_energy)


## Time player can be in wave mode, in seconds
@export var wave_mode_duration: float = 60

## How long the player has in wave mode
var wave_mode_timer: float = wave_mode_duration:
	set(new_time):
		wave_mode_timer = clampf(new_time, 0.0, wave_mode_duration)
		hud.update_wave_countdown(new_time)
		if level and wave_mode_timer == 0.0:
			level.get_node("PlayerManager").kill_all()


func circle_sample(radius: float) -> Vector2:
	var angle = randf_range(0.0, TAU)  # TAU = 2π
	var r = radius * sqrt(randf())     # sqrt to ensure uniform distribution
	return Vector2.RIGHT.rotated(angle) * r	


# Camera shaking
var shake_strength = 0.0
var shake_decay = 5.0
var shake_rotation = 0.02  # Max rotation in radians


func start_camera_shake(strength: float, decay: float = 5.0, rotation: float = 0.02):
	set_process(true)
	shake_strength = strength
	shake_decay = decay
	shake_rotation = rotation


func end_camera_shake(camera_valid: bool):
	set_process(false)
	shake_strength = 0
	# Reset offset and rotation when shake ends
	if camera_valid:
		camera.offset = Vector2.ZERO
		camera.rotation = 0


func camera_shake_handling(delta: float) -> void:
	if shake_strength > 0:
		# Generate random offsets
		var offset_x = randf_range(-shake_strength, shake_strength)
		var offset_y = randf_range(-shake_strength, shake_strength)
		
		var camera_valid := is_instance_valid(camera)
		
		# Apply random offsets and rotation
		if camera_valid:
			camera.offset = Vector2(offset_x, offset_y)
			camera.rotation = randf_range(-shake_rotation, shake_rotation)

		# Decrease shake strength over time
		shake_strength -= shake_decay * delta
		if not camera_valid or shake_strength < 0:
			end_camera_shake(camera_valid)


func _ready() -> void:
	set_process(false)
	if not OS.is_debug_build():
		DEBUG = false
	if DEBUG:
		push_warning("DEBUG MODE ACTIVE (music starting muted)")
	set_process(true)
	

func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


## Toggle fullscreen with Ctrl f
func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F and event.ctrl_pressed:
			toggle_fullscreen()


func _process(delta):
	camera_shake_handling(delta)
