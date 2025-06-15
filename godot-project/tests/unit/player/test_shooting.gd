extends GutTest

var ShootingAbility = preload("res://scripts/player/shoot_ability.gd")

# Mock shooting ability class for testing
class MockShootingAbility extends "res://scripts/player/shoot_ability.gd":
	var _has_energy := true
	var single_shot_called := false
	var multi_shot_called := false
	
	func has_energy(_amount: float) -> bool:
		return _has_energy
	
	func shoot_single() -> void:
		if has_energy(single_shoot_energy):
			single_shot_called = true
	
	func shoot_multi() -> void:
		if has_energy(multi_shoot_energy):
			multi_shot_called = true

# Tests that shooting state is properly initialized when starting to shoot
# - check shooting flag is set
# - check  press_start_time is initialized
func test_start_shooting():
	# Arrange
	var shooting_ability = MockShootingAbility.new()
	shooting_ability.active = true
	
	# Act
	shooting_ability.start_shooting()
	
	# Assert
	assert_true(shooting_ability.shooting, "Shooting should be true after start_shooting is called.")
	assert_gt(shooting_ability.press_start_time, 0, "press_start_time should be set to a value greater than 0.")

# Tests that a short press (< long_press_duration) correctly triggers single shot
# - check shooting state is reset
# - check that single shot was fired
func test_end_shooting_short_press():
	# Arrange
	var shooting_ability = MockShootingAbility.new()
	shooting_ability.active = true
	shooting_ability._has_energy = true
	
	# Simulate short press
	shooting_ability.start_shooting()
	shooting_ability.press_start_time = Time.get_ticks_msec() / 1000.0 - 0.1
	
	# Act
	shooting_ability.end_shooting()
	
	# Assert
	assert_false(shooting_ability.shooting, "Shooting should be false after end_shooting is called.")
	assert_true(shooting_ability.single_shot_called, "shoot_single should be called for short presses")

# Tests that holding shoot button long enough triggers multi-shot
# - simulate long press by setting press duration > long_press_duration
# - check multi-shot is called
func test_end_shooting_long_press():

	var shooting_ability = MockShootingAbility.new()
	shooting_ability.active = true
	shooting_ability.start_shooting()

	# Simulate long press (> long_press_duration)
	shooting_ability.press_start_time = Time.get_ticks_msec() / 1000.0 - 1.0
	
	
	shooting_ability.end_shooting()
	
	
	assert_true(shooting_ability.multi_shot_called, "Long press should trigger multi-shot")

# Tests that shooting requires sufficient energy
# - sets has_energy to false
# - checks no shots are fired without energy
func test_energy_requirements():
	
	var shooting_ability = MockShootingAbility.new()
	shooting_ability.active = true
	shooting_ability._has_energy = false
	
	
	shooting_ability.start_shooting()
	shooting_ability.end_shooting()
	assert_false(shooting_ability.single_shot_called, "Should not shoot without energy")

# Tests that multi-shot respects cooldown timer
# - set cooldown timer to active
# - checks multi-shot cannot be used during cooldown
func test_cooldown():
	
	var shooting_ability = MockShootingAbility.new()
	shooting_ability.active = true
	shooting_ability.multi_shot_timer = 1.0  # Set cooldown
	
	# Act - Try to shoot during cooldown
	shooting_ability.start_shooting()
	shooting_ability.press_start_time = Time.get_ticks_msec() / 1000.0 - 1.0
	shooting_ability.end_shooting()
	
	# Assert
	assert_false(shooting_ability.multi_shot_called, "Multi-shot should not work during cooldown")

# Tests that shooting ability can be disabled
# - set active to false
# - check no shooting occurs while inactive
func test_inactive_state():
	# Arrange
	var shooting_ability = MockShootingAbility.new()
	shooting_ability.active = false
	
	# Act
	shooting_ability.start_shooting()
	shooting_ability.end_shooting()
	
	# Assert
	assert_false(shooting_ability.single_shot_called, "Should not shoot while inactive")
