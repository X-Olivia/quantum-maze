extends GutTest

var Accelarator = preload("res://scripts/objects/particle_accelerator.gd")

class MockDash extends Node2D:
	func dash(direction: Vector2 = Vector2.ZERO) -> void:
		get_parent().velocity *= (direction * 2)
	
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

func set_up_player():
	var player = MockPlayer.new()
	player.velocity = Vector2(1, 0)
	
	var dash = MockDash.new()
	dash.name = "DashAbility"
	
	player.add_child(dash)
	get_tree().root.add_child(player)
	
	return player

func set_up_accelerator():
	var accelerator = Accelarator.new()
	accelerator.position = Vector2(2, 0)
	
	return accelerator

func test_effect_on_player():
	var accelerator = set_up_accelerator()
	var player = set_up_player()
	#
	accelerator._on_effect_area_body_entered(player)
	assert_true(true)
	
