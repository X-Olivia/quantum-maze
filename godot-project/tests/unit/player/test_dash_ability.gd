extends GutTest

# A player class that pretends to be a real player node
class MockPlayer extends CharacterBody2D:
	var killed := false
	var mode: Globals.Modes = Globals.Modes.PARTICLE
	
	func _init():
		add_to_group("Player")
		# setup collision shape for proper collision detection
		var shape = CollisionShape2D.new()
		shape.shape = CircleShape2D.new()
		shape.shape.radius = 32
		add_child(shape)
		
			

# A hun class that pretends to be a hud
class MockHud extends CanvasLayer:
	var energy_bar: ProgressBar

	func _ready() -> void:
		Globals.hud = self
		energy_bar = $EnergyBar
		
	func update_energy_bar(new_energy) -> void:
		pass
		
class MockWall extends TileMapLayer:
	var breakable: bool = false
	func break_tile(value: Variant):
		return breakable
	

# Preload scripts
var Dash = preload("res://scripts/player/dash_ability.gd")
var Player = preload("res://scripts/player/player.gd")

func set_up_dash():
	# Set up hud
	var hud = MockHud.new()
	hud._ready()
	
	var camera: Camera2D = Camera2D.new()
	Globals.camera = camera
	
	# Prepare child node of dash_ability
	var DashTimer: Timer = Timer.new()
	var DashCooldown: Timer = Timer.new()
	var SafetyTimer: Timer = Timer.new()
	
	var FlamingTrail: GPUParticles2D = GPUParticles2D.new()
	var DashBurst: GPUParticles2D = GPUParticles2D.new()
	
	var dash = Dash.new()
	
	DashTimer.name = "DashTimer"
	DashCooldown.name = "DashCooldown"
	SafetyTimer.name = "SafetyTimer"
	
	FlamingTrail.name = "FlamingTrail"
	DashBurst.name = "DashBurst"
	
	var animation: AnimatedSprite2D = AnimatedSprite2D.new()
	animation.name = "AnimatedSprite2D"
	
	
	var player = Player.new()
	dash.parent = player
	
	player.add_child(animation)
	
	dash.add_child(DashTimer)
	dash.add_child(DashCooldown)
	dash.add_child(SafetyTimer)
	
	dash.add_child(FlamingTrail)
	dash.add_child(DashBurst)
	
	return dash


func test_start_dash():
	var dash = set_up_dash()
	Globals.energy = 100
	
	var direction : Vector2 = Vector2.ZERO

	dash.parent.mode = Globals.Modes.PARTICLE
	
	dash.active = true
	dash.dashing = false
	dash.can_dash = true
	
	dash.dash(direction)
	# Test in case that player in particle mode
	assert_true(dash.dashing, "player should be dashing")
	assert_false(dash.can_dash, "player could not 'dash' while dashing")
	assert_eq(dash.parent.velocity, direction * dash.dash_speed, "dash direction should be Vector2.ZERO")
	assert_eq(Globals.energy, 100 - dash.energy_to_dash, "energy should be consumed")
	
	dash.parent.mode = Globals.Modes.WAVE
	
	dash.active = true
	dash.dashing = false
	dash.can_dash = true
	
	dash.dash(direction)
	# Test in case that player in wave mode
	assert_false(dash.dashing, "player should not be dashing in wave mode")
	assert_true(dash.can_dash, "player could dash after becoming particle again")
	
	dash.parent.mode = Globals.Modes.PARTICLE
	Globals.energy = 0
	
	dash.active = true
	dash.dashing = false
	dash.can_dash = true
	
	dash.dash(direction)
	# Test the situation that energy ran out
	assert_false(dash.dashing, "player should not be dashing whith no enough energy")
	assert_true(dash.can_dash, "player could dash if there is enough energy")
	
	
	Globals.energy = 100
	
	dash.active = true
	dash.dashing = false
	dash.can_dash = true
	
	direction = Vector2.LEFT
	
	dash.dash(direction)
	# Test energy comsumption in accelerator mode
	assert_true(dash.dashing, "player should be dashing")
	assert_false(dash.can_dash, "player could not 'dash' while dashing")
	dash._physics_process(0.016666667)
	assert_eq(dash.parent.velocity, Vector2.LEFT * dash.dash_speed, "dash direction should be Vector2.ZERO")
	assert_eq(Globals.energy, 100, "energy should not be consumed")
	

func test_stop_dash():
	var dash = set_up_dash()
	Globals.energy = 100
	
	dash.parent.mode = Globals.Modes.PARTICLE
	
	var direction : Vector2 = Vector2.ZERO
	
	dash.active = true
	dash.dashing = false
	dash.can_dash = true
	
	dash.dash(direction)
	dash.stop_dashing()
	
	assert_false(dash.dashing, "player should stopped")
	assert_false(dash.can_dash, "there should be a cool down time after dashing")
	assert_eq(dash.parent.velocity, Vector2.ZERO, "parent direction should be Vector2.ZERO")
	
	direction = Vector2.LEFT
	
	dash.active = true
	dash.dashing = false
	dash.can_dash = true
	
	dash.dash(direction)
	dash.stop_dashing()
	
	assert_false(dash.dashing, "player should stopped")
	assert_true(dash.can_dash, "there should not be a cool down time after dashing by accelerator")
	assert_eq(dash.parent.velocity, Vector2.ZERO, "parent direction should be Vector2.ZERO")
	
	

func test_timer_timeout():
	var dash = set_up_dash()
	Globals.energy = 100
	
	dash.parent.mode = Globals.Modes.PARTICLE
	
	var direction : Vector2 = Vector2.ZERO
	
	dash.active = true
	dash.dashing = false
	dash.can_dash = true
	
	dash.dash(direction)
	assert_false(dash.can_dash)
	dash._on_dash_cooldown_timeout()
	assert_true(dash.can_dash)
	
	
	dash.active = true
	dash.dashing = false
	dash.can_dash = true
	
	dash.dash(direction)
	dash._on_dash_timer_timeout()
	
	assert_false(dash.dashing, "player should stopped")
	assert_false(dash.can_dash, "there should be a cool down time after dashing")
	assert_eq(dash.parent.velocity, Vector2.ZERO, "parent direction should be Vector2.ZERO")
	
	
	dash.active = true
	dash.dashing = false
	dash.can_dash = true
	
	dash.dash(direction)
	dash._on_safety_timer_timeout()
	
	assert_false(dash.dashing, "player should stopped")
	assert_false(dash.can_dash, "there should be a cool down time after dashing")
	assert_eq(dash.parent.velocity, Vector2.ZERO, "parent direction should be Vector2.ZERO")

func test_collided():
	var dash = set_up_dash()
	Globals.energy = 100
	
	dash.parent.mode = Globals.Modes.PARTICLE
	
	dash.dashing = false
	
	var wall = MockWall.new()
	wall.position = Vector2(-10, 0)
	wall.breakable = false
	Globals.wall_tiles = wall
	
	var velocity = Vector2(-1, 0)
	for i in range(12):
		dash.parent.position += velocity
		var collided: bool = dash.parent.move_and_slide()
	
	assert_false(dash.collided(dash.parent.get_last_slide_collision()))
	
	dash.dashing = false
	
	dash.parent.position = Vector2(0, 0)
	
	wall.breakable = true
	Globals.wall_tiles = wall
	
	for i in range(12):
		dash.parent.position += velocity
		var collided: bool = dash.parent.move_and_slide()
	
	assert_false(dash.collided(dash.parent.get_last_slide_collision()))
