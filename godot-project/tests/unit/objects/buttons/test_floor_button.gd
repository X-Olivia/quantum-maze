extends GutTest

var FloorButtonScene = preload("res://scenes/electrical outputs/floor_button.tscn")
var Globals = preload("res://scripts/autoload/globals.gd")


# Mock Wire class!
class MockWire extends Wire:
	var power_called := false
	var unpower_called := false
	
	func _ready(): 
		add_to_group("Output")
		
		# set up required curve (parent needs this)
		curve = Curve2D.new()
		curve.add_point(Vector2.ZERO)
		curve.add_point(Vector2(10, 0))
		
		modulate = Color.WHITE  # godot throws an error unless i set modulate
	
	func power():
		powered = true
		power_called = true
	
	func unpower():
		powered = false
		unpower_called = true

# Create a custom TestFloorButton for our tests
class TestFloorButton extends Area2D:
	# we'll just copy properties from the original floor button
	const darkRed := Color("8a0000")
	const transparent := Color.WHITE
	
	var wires: Array[Wire] = []
	var player: CharacterBody2D = null
	
	func _physics_process(_delta: float) -> void:
		var was_player: CharacterBody2D = player
		player = null
		for body in get_overlapping_bodies():
			# Check both real Player and "Player" group
			if (body is Player or body.is_in_group("Player")) and body.mode == Globals.Modes.PARTICLE:
				player = body
		
		# Released
		if was_player and not player:
			$Image.modulate = transparent
			for wire in wires:
				wire.unpower()
		# Pressed
		elif not was_player and player:
			$Image.modulate = darkRed
			for wire in wires:
				wire.power()


class MockPlayer extends CharacterBody2D:
	var mode = Globals.Modes.PARTICLE
	
	func _init():
		var shape = CollisionShape2D.new()
		shape.shape = CircleShape2D.new()
		shape.shape.radius = 60
		add_child(shape)
		collision_mask = 4
		collision_layer = 1
	
	func make_player():
		add_to_group("Player")
		return self

# Create our test button instance
func before_each():
	# First instantiate the original scene to get its children
	var original_button = FloorButtonScene.instantiate()
	
	# Create our test button
	var button = TestFloorButton.new()
	
	# Copy all the children from the original button
	for child in original_button.get_children():
		original_button.remove_child(child)
		#add to test button
		button.add_child(child)
	
	# free original
	original_button.free()
	
	# add test button to the scene
	add_child(button)
	await get_tree().process_frame
	
	button.monitoring = true
	button.monitorable = true
	
	await get_tree().physics_frame
	return button

func test_initial_state():
	var button = await before_each()
	var Wire = MockWire.new()
	button.wires.append(Wire)
	assert_false(Wire.powered, "Wire should start unpowered")


func test_button_press_and_release():
	var button = await before_each()
	var Wire = MockWire.new()
	add_child(Wire)
	await get_tree().physics_frame
	
	button.wires.append(Wire)

	
	var mock_player = MockPlayer.new().make_player()
	add_child(mock_player)
	await get_tree().physics_frame
	
	mock_player.global_position = button.global_position
	for i in range(5):
		await get_tree().physics_frame
	
	
	assert_true(Wire.power_called, "Wire's power method should be called")
	assert_true(Wire.powered, "Wire should be powered")
	
	mock_player.global_position = button.global_position + Vector2(1000, 1000)
	for i in range(5):
		await get_tree().physics_frame
	
	assert_true(Wire.unpower_called, "Wire's unpower method should be called")
	assert_false(Wire.powered, "Wire should be unpowered")

# test that button ignores wave mode player
func test_wave_mode_player():
	var button = await before_each()
	var Wire = MockWire.new()
	button.wires.append(Wire)
	add_child(Wire)
	
	var mock_player = MockPlayer.new().make_player()
	mock_player.mode = Globals.Modes.WAVE
	add_child(mock_player)
	await get_tree().process_frame
	
	mock_player.global_position = button.global_position
	for i in range(5):
		await get_tree().physics_frame
	
	assert_false(Wire.power_called, "Button should ignore WAVE mode player")
	assert_false(Wire.powered, "Wire should stay unpowered with WAVE mode player")

# test that button ignores non-player objects
func test_non_player_collision():
	var button = await before_each()
	var Wire = MockWire.new()
	button.wires.append(Wire)
	add_child(Wire)
	
	# create non-player body by not adding it to Player group
	# that way its just a character body 2d (could be an enemy)

	var non_player = MockPlayer.new()  # we don't call make_player()!
	add_child(non_player)
	await get_tree().process_frame
	
	non_player.global_position = button.global_position
	for i in range(5):
		await get_tree().physics_frame
	
	assert_false(Wire.power_called, "Button should ignore non-player objects")
	assert_false(Wire.powered, "Wire should stay unpowered with non-player objects")

# test button controls multiple Wires
func test_multiple_Wires():
	var button = await before_each()
	
	var Wires = []
	button.wires.clear()
	
	for i in range(3):
		var Wire = MockWire.new()
		add_child(Wire)
		Wires.append(Wire)
		button.wires.append(Wire)
	
	await get_tree().process_frame
	
	
	var mock_player = MockPlayer.new().make_player()
	add_child(mock_player)
	await get_tree().physics_frame
	
	mock_player.global_position = button.global_position
	for i in range(5):
		await get_tree().physics_frame
	
	for Wire in Wires:
		assert_true(Wire.power_called, "Wire should be powered")
		assert_true(Wire.powered, "Wire should be in powered state")
	
	mock_player.global_position = button.global_position + Vector2(1000, 1000)
	for i in range(5):
		await get_tree().physics_frame
	
	for Wire in Wires:
		assert_true(Wire.unpower_called, "Unpower should be called")
		assert_false(Wire.powered, "Wire should be unpowered")
	
	button.wires.clear()
	mock_player.queue_free()
	for Wire in Wires:
		Wire.queue_free()

# test multiple overlapping bodies
func test_multiple_overlapping_bodies():
	var button = await before_each()
	var Wire = MockWire.new()
	add_child(Wire)
	button.wires.append(Wire)
	
	var player1 = MockPlayer.new().make_player()
	var player2 = MockPlayer.new().make_player()
	add_child(player1)
	add_child(player2)
	await get_tree().physics_frame
	
	
	# Position players over button one at a time
	player1.global_position = button.global_position
	await get_tree().physics_frame
	assert_true(Wire.powered, "Button should be powered with first player")
	
	player2.global_position = button.global_position
	await get_tree().physics_frame
	assert_true(Wire.powered, "Button should remain powered with second player")
	
	# Move first player away and wait for multiple frames
	player1.global_position = Vector2(1000, 1000)
	for i in range(3):  
		await get_tree().physics_frame
	assert_true(Wire.powered, "Button should stay powered with one player")
	
	
	# Move second player away and wait for multiple frames
	player2.global_position = Vector2(1000, 1000)
	for i in range(3):  
		await get_tree().physics_frame
	
	
	assert_false(Wire.powered, "Button should unpower when all players leave")
