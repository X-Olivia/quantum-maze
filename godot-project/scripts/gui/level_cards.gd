extends HBoxContainer

const card_scene: PackedScene = preload("res://scenes/gui/level_card.tscn")

var current_index = 0
var level_cards = []

func setup(game: GameManager, save_data: Dictionary) -> void:
	# Clear existing cards
	for child in get_children():
		child.queue_free()
	
	level_cards.clear()
	
	# Create cards for each level
	for id in save_data.keys():
		if id.is_valid_int():
			var card: LevelCard = card_scene.instantiate()
			card.setup(game, id, save_data.get(id))
			level_cards.append(card)
	
	# Sort cards by level ID
	level_cards.sort_custom(func(a, b): return int(a.level_id) < int(b.level_id))
	
	# Add the current card if there are any cards
	if level_cards.size() > 0:
		add_child(level_cards[current_index])
		level_cards[current_index].visible = true

func next_level():
	if level_cards.size() <= 1:
		return
	
	# Remove current card
	remove_child(level_cards[current_index])
	
	# Move to next card
	current_index = (current_index + 1) % level_cards.size()
	
	# Add new card
	add_child(level_cards[current_index])
	level_cards[current_index].visible = true

func previous_level():
	if level_cards.size() <= 1:
		return
	
	# Remove current card
	remove_child(level_cards[current_index])
	
	# Move to previous card
	current_index = (current_index - 1 + level_cards.size()) % level_cards.size()
	
	# Add new card
	add_child(level_cards[current_index])
	level_cards[current_index].visible = true

func update_level_counter():
	# 函数保留但不执行任何操作
	pass

func update(save_data: Dictionary) -> void:
	for card in level_cards:
		card.update(save_data[card.level_id])
	queue_redraw()
