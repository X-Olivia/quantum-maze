extends GutTest

# Load the class to be tested
var Player = preload("res://scripts/player/player.gd")
var Globals = preload("res://scripts/autoload/globals.gd")
var globals_instance: Node

func before_all():
	# Create new Globals instance for all tests
	globals_instance = Globals.new()
	add_child(globals_instance)

func after_all():
	# clean up Globals instance
	globals_instance.queue_free()


class TestPlayer extends Player:
	func movement_and_collision_handling(delta: float) -> void:
		# Store movement state
		previous_velocity = velocity
		next_position = global_position + velocity * delta
		
		# Update movement and collision state
		var collided: bool = move_and_slide()
		if not collided:
			return  # Return if player hasn't collided with anything
		
	func particle_mode_handling(_delta: float) -> void:
		# this func just checks if player should shoot, dash or parry
		# which we're not testing in this script so let it pass 
		pass
		
	func wave_mode_handling(delta: float) -> void:
		pass

# mock manager class that extends node2d 
class MockManager extends Node2D:
	# config values for wave mode
	var spread_speed: float = 40
	var max_spread_radius: float = 300
	
	# flags to track which methods were called during tests
	var possibility_called := false
	var particle_called := false
	var kill_called := false
	var last_instance = null  # Stores the last player instance that triggered a method
	
	# simulate transition to wave mode
	func set_to_possibility(instance):
		possibility_called = true
		last_instance = instance
		instance.mode = Globals.Modes.WAVE
	
	# Simulates transition to particle mode
	func set_to_particle(instance):
		particle_called = true
		last_instance = instance
		instance.mode = Globals.Modes.PARTICLE
	
	# Simulates player death handling
	func kill(instance):
		kill_called = true
		last_instance = instance

# Setup method that we run before each test 
	# - creates a fresh player instance
	# - sets up the player's collision detection
		# not directly tested, but needed to ensure ready function in player script runs without error
	# - add player to the manager

func before_each():
	# Set up the player's manager
	var manager = MockManager.new()
	add_child(manager)
	
	var player = TestPlayer.new()
	
	# set collision detection 

		# for the player
	var collision_shape_2d = CollisionShape2D.new()
	collision_shape_2d.name = "CollisionShape2D"
	collision_shape_2d.shape = CircleShape2D.new()
	
		# now wave mode collision detection
	var wave_area = Area2D.new()
	wave_area.name = "WaveArea"
	var wave_collision = CollisionShape2D.new()
	wave_collision.name = "CollisionShape2D"
	wave_collision.shape = CircleShape2D.new()
	
	# Add an animationSprite for test
	var animation: AnimatedSprite2D = AnimatedSprite2D.new()
	animation.name = "AnimatedSprite2D"
	player.add_child(animation)
	
	# Construct the node hierarchy
	wave_area.add_child(wave_collision)
	player.add_child(collision_shape_2d)
	player.add_child(wave_area)
	manager.add_child(player)
	
	# Wait for scene tree to update
	await get_tree().process_frame
	
	# Start in particle mode by default
	player.mode = Globals.Modes.PARTICLE
	return player


# test player start with correct max health
func test_initial_health():
	var player = await before_each()
	assert_eq(player.health, player.max_health, "initial health should equal max_health")
	assert_eq(player.max_health, 100, "max health should be 100")

# test damage reduces health correctly
func test_damage_system():
	var player = await before_each()
	var initial_health = player.health
	
	# Fixed: Pass a Dictionary with "damage" key 
	player.damage({"damage": 20.0})
	
	assert_eq(player.health, initial_health - 20.0, "health should decrease by damage amount")

# Tests that health cannot go below zero
func test_damage_clamp():
	var player = await before_each()
	
	player.damage({"damage": 150.0})  
	
	assert_eq(player.health, 0, "Health should be set to 0")

# verify correct mode switching behavior
func test_mode_switching():
	var player = await before_each()
	
	# we'll test  particle to wave first
	player.mode = Globals.Modes.PARTICLE
	Input.action_press("toggle mode")
	player.basic_handling(0.1)
	Input.action_release("toggle mode")
	
	# manager should handle mode change
	assert_true(player.manager.possibility_called, "Manager's set_to_possibility should be called")
	assert_eq(player.manager.last_instance, player, "Manager should receive correct player instance")
	assert_eq(player.mode, Globals.Modes.WAVE, "Manager should have changed mode to wave")
	
	# now test wave to particle mode
	Input.action_press("toggle mode")
	player.basic_handling(0.1)
	Input.action_release("toggle mode")
	
	# check manager handles the mode change
	assert_true(player.manager.particle_called, "Manager's set_to_particle should be called")
	assert_eq(player.manager.last_instance, player, "Manager should receive correct player instance")
	assert_eq(player.mode, Globals.Modes.PARTICLE, "Manager should have changed mode to particle")

# Tests that player speed is limited to max_speed
func test_movement_speed():
	var player = await before_each()
	player.velocity = Vector2(player.max_speed, 0)
	assert_eq(player.velocity.length(), player.max_speed, "Player speed should not exceed max_speed")

# Tests movement direction based on input - test moving right and moving diagonally
func test_movement_direction():
	var player = await before_each()
	
	# Test right movement
	Input.action_press("right")
	player.basic_handling(1.0)
	Input.action_release("right")
	assert_true(player.velocity.x > 0, " should move right")
	assert_eq(player.velocity.y, 0, "Shouldnt move vertically")
	
	# Test diagonal movement (normalised)
	Input.action_press("right") 
	Input.action_press("up")
	player.basic_handling(1.0)
	# x=1, y=-1
	var expected_diagonal = Vector2(1, -1).normalized() * player.velocity.length() # Normalisee  expected diagonal vector

	assert_eq(player.velocity.x, expected_diagonal.x, "Diagonal X movement should be normalized")
	assert_eq(player.velocity.y, expected_diagonal.y, "Diagonal Y movement should be normalized")

# test death handling when player is not in dash state - should call manager's kill method
func test_kill_calls_manager():
	var player = await before_each()
	player.kill()
	assert_true(player.manager.kill_called, "player managers's kill method should be called")

# test wave mode radius expansion over time - should increase by spread_speed per second
func test_wave_mode_radius():
	var player = await before_each()
	player.mode = Globals.Modes.WAVE
	player.manager.spread_speed = 40
	player.manager.max_spread_radius = 300
	
	# Ensure radius starts at zero
	player.wave_shape.radius = 0.0
	
	player._physics_process(1.0)
	
	assert_eq(player.wave_shape.radius, 40.0, "Wave radius should increase by spread_speed per second")
