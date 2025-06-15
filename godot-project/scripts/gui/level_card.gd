extends Control
class_name LevelCard

var locked_texture = preload("res://assets/images/level_cards/locked_level_card.png")
var default_texture = preload("res://assets/images/level_cards/temp_level_card.png")

var collectable_texture = preload("res://assets/images/objects/collectable.png")

var level_id: String


func update(level_data: Dictionary) -> void:
	%LevelName.text = level_data.display_name if level_data.unlocked else "LOCKED"

	var num := ""
	var suffix := ""
	if level_data.name in ["level1", "level2", "level3", "level4"]:
		num = level_data.name.substr(5)
		if level_data.unlocked:
			suffix = "_open"

	var image_path := "res://assets/images/level_cards/l%s%s.png" % [num, suffix]

	# Load or fall back
	if ResourceLoader.exists(image_path):
		%PreviewImage.texture = load(image_path)
	else:
		%PreviewImage.texture = default_texture if level_data.unlocked else locked_texture
		
	%Value.text = "---" if level_data.best_time == 0.0 else format_time(level_data.best_time)
		
	for i in range(level_data.collectables.size()):
		var sprite = %Collectables.get_child(i)
		sprite.modulate = Color.WHITE if level_data.collectables[i] else Color.BLACK


func format_time(seconds: float) -> String:
	# `X` h `X` m `X.XXX` s
	
	var hours = int(seconds / 3600)
	seconds -= hours * 3600

	var minutes = int(seconds / 60)
	seconds -= minutes * 60

	var result = []

	if hours > 0:
		result.append("%d h" % hours)
	if minutes > 0 or hours > 0:
		result.append("%d m" % minutes)
		
	result.append("%.3f s" % seconds)

	return " ".join(result)


func setup(game: GameManager, id: String, level_data: Dictionary) -> void:
	level_id = id
	var load_level_callback = Callable(game, "load_level").bind(id)
	$Button.pressed.connect(load_level_callback)
	
	%PreviewImage.mouse_filter = Control.MOUSE_FILTER_STOP
	%PreviewImage.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			load_level_callback.call()
	)
	
	name = level_data.name
	
	var collectable_num = level_data.collectables.size()
	if collectable_num == 0:
		%Collectables/Icon.queue_free()
	elif collectable_num > 1:
		for i in range(collectable_num - 1):
			%Collectables.add_child(%Collectables/Icon.duplicate())
	
	update(level_data)
