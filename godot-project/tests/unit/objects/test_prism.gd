extends GutTest

class MockPlayer extends CharacterBody2D:
	var killed := false
	var mode : Globals.Modes = Globals.Modes.PARTICLE
	
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

var Prism = preload("res://scripts/objects/prism.gd")

func set_up_prism() -> Prism:
	var prism = Prism.new()
	return prism
	
func set_up_player() -> MockPlayer:
	var player = MockPlayer.new()
	return player

func test_drop():
	var prism = set_up_prism()
	var init_index = prism.z_index
	prism.drop()
	assert_eq(prism.z_index, init_index - 1, "z_index should be minused by 1")
	assert_false(prism.is_picked_up, "prism should be droped")

func test_pick_up():
	var prism = set_up_prism()
	var init_index = prism.z_index
	prism.pickup()
	assert_eq(prism.z_index, init_index + 1, "z_index should be added by 1")
	assert_true(prism.is_picked_up, "prism should be picked up")
	
func test_energy_suppliments():
	var prism = set_up_prism()
	var player = set_up_player()
	var hud = MockHud.new()
	prism.player = player
	hud._ready()
	var delta : float = 0.016666666667
	
	Globals.energy = 80
	
	for i in range(100):
		prism._physics_process(delta)
		
	assert_almost_eq(Globals.energy, 80 + prism.regen_rate * delta * 100 - 1, 80 + prism.regen_rate * delta * 100 + 1)
