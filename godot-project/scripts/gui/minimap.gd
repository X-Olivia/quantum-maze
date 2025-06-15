extends MarginContainer
class_name Minimap

@onready var viewport: SubViewport = $CircleClip/ContentContainer/MinimapViewport/SubViewport
@onready var viewport_container: SubViewportContainer = $CircleClip/ContentContainer/MinimapViewport
@onready var minimap_camera: Camera2D = $CircleClip/ContentContainer/MinimapViewport/SubViewport/MinimapCamera
@onready var player_marker: Panel = $PlayerMarker

var player: Player = null
var level: LevelManager = null
const MINIMAP_ZOOM_SCALE = 0.075

func _ready() -> void:
	set_process(true)
	
	viewport.world_2d = get_tree().root.world_2d
	viewport_container.stretch = true  
	
	minimap_camera.enabled = true
	minimap_camera.zoom = Vector2(MINIMAP_ZOOM_SCALE, MINIMAP_ZOOM_SCALE)
	
	initialize()
	
func initialize() -> void:
	player = Globals.player
	level = Globals.level
	
	if player and level:
		
		# Set up mini-map camera
		if Globals.camera:		
			viewport.size = Vector2(400, 400)
			
		player_marker.visible = false

func _process(_delta: float) -> void:
	if Globals.player != null:
		player = Globals.player
	
	if player and minimap_camera:
		minimap_camera.global_position = player.global_position
		
		if not minimap_camera.enabled:
			minimap_camera.enabled = true
