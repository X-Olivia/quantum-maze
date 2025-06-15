extends GutTest

# A player class that pretends to be a real player node
class MockPlayer extends CharacterBody2D:
	var killed := false
	
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


# Reference to the scripts
var Parry = preload("res://scripts/player/parry_ability.gd")
var Photon = preload("res://scripts/hazards/photon.gd")
var EnemyScene = preload("res://scenes/hazards/enemy.tscn")

## Set up functions

# Set up photon
func set_up_photon():
	var photon = Photon.new()
	
	# Set parameters of the photon
	photon.position = Vector2(-1, 0)
	photon.direction = Vector2.RIGHT
	photon.name = "Photon"
	
	return photon

# Set up enemy
func set_up_enemy():
	var enemyScene = EnemyScene.instantiate()
	
	enemyScene.name = "Enemy"
	
	return enemyScene

# Set up the parry_ability
func set_up_parry():
	# Set up hud
	var hud = MockHud.new()
	hud._ready()
	
	# Set up parent node(player)
	var player = MockPlayer.new()
	var parry = Parry.new()
	
	# Set the parent node
	player.add_child(parry)
	
	return parry




# Test that whether the set up function is working
func test_init():
	var photon = set_up_photon()
	assert_eq(photon.damage, 20)


# Test whether the energy consumption function works properly
func test_energy_consumption():
	var init_energy : int = Globals.energy
	var parry = set_up_parry()
	
	parry.blocking = true
	parry.was_blocking = true
	parry.active = true
	
	# Set the exist time of the shield
	var exist_time : float = 6.0
	var perfect_time : float = 0.2
	var delta : float = 0.0166666667
	
	# Test energy consumption within the perfect parry time
	parry.is_perfect_parry = true
	for i in range(int(perfect_time/delta)):
		parry._physics_process(delta)
	
	assert_eq(Globals.energy, init_energy, "Energy should not be consumed")
	
	# Reset timer
	parry._on_timer_timeout()
	
	# Test energy consumption with not in the perfect parry time
	parry.is_perfect_parry = false
	for i in range(int(exist_time/delta)):
		parry._physics_process(delta)
	
	assert_true(Globals.energy < init_energy, "Energy should decrease over time")
	assert_eq(floor(Globals.energy), int(100 - parry.energy_drain * exist_time), "Energy consuption amount should be 20")
	
	# Test energy ran out
	for i in range(int(exist_time/delta) * 2):
		parry._physics_process(delta)
		
	assert_eq(ceil(Globals.energy), 0, "Energy should be ran out")


# Test reflection and damage deduction on photon
func test_parry_photon():
	var photon = set_up_photon()
	var parry = set_up_parry()
	
	parry.is_perfect_parry = false
	parry._on_area_entered(photon)
	assert_eq(photon.damage, photon.base_damage * parry.damage_multiplier, "The damage should reduced")
	
	parry.is_perfect_parry = true
	parry._on_area_entered(photon)
	var expected_direction : Vector2 = Vector2.LEFT
	assert_eq(photon.direction, expected_direction, "The direction should reverse")
	
	parry._on_area_entered(photon)
	assert_eq(photon.direction, expected_direction, "The direction should not be changed")


# Test knock back on enemy
func test_parry_enemy():
	var enemy = set_up_enemy()
	var parry = set_up_parry()
	
	enemy.position = Vector2(-1, 0)
	var init_position : Vector2 = enemy.position
	
	parry.is_perfect_parry = false
	parry._on_body_entered(enemy)
	assert_eq(enemy.position, init_position, "The position should not be changed")
	
	var direction : Vector2 = Vector2.LEFT
	parry.is_perfect_parry = true
	parry._on_body_entered(enemy)
	assert_true(enemy.stunned, "The enemy should be stunned")
	
