extends Panel
class_name Encyclopedia

@onready var item_grid = $HSplitContainer/LeftPanel/ScrollContainer/ItemGrid
@onready var item_icon = $HSplitContainer/RightPanel/ItemIcon
@onready var item_name_label = $HSplitContainer/RightPanel/ItemNameLabel
@onready var item_description_label = $HSplitContainer/RightPanel/ItemDescriptionLabel
@onready var item_tutorial_text = $HSplitContainer/RightPanel/Panel/MarginContainer/ItemTutorialText
@onready var close_button = $HSplitContainer/RightPanel/CloseButton

var encyclopedia_data = {}
var current_item_id = ""

func _ready():
	
	load_encyclopedia_data()
	populate_items()
	
	# 默认选择第一个物品
	if encyclopedia_data.items.size() > 0:
		var first_item_id = encyclopedia_data.items.keys()[0]
		show_item_details(first_item_id)
	

func load_encyclopedia_data():
	var file = FileAccess.open("res://data/encyclopedia_data.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			encyclopedia_data = json.get_data()
		file.close()

func populate_items():
	# 清除现有项目
	for child in item_grid.get_children():
		child.queue_free()
	
	# 添加所有物品
	for item_id in encyclopedia_data.items:
		var item = encyclopedia_data.items[item_id]
		
		var button = TextureButton.new()
		button.texture_normal = load(item.icon)
		button.custom_minimum_size = Vector2(64, 64)
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		
		# 连接点击事件
		button.pressed.connect(func(): show_item_details(item_id))
		
		item_grid.add_child(button)

func show_item_details(item_id):
	if item_id in encyclopedia_data.items:
		current_item_id = item_id
		var item = encyclopedia_data.items[item_id]
		
		item_icon.texture = load(item.icon)
		item_name_label.text = item.name
		item_description_label.text = item.description
		item_tutorial_text.text = item.tutorial
