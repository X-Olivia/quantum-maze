extends CanvasLayer
class_name HUD
###
# Heads Up Display (HUD)
# Displays information to the player

## Label holding the remaining time as a wave
@onready var wave_countdown_label: Label = $WaveCountdown
@onready var minimap: Minimap = %Minimap
@onready var encyclopedia_button: Button = $EncyclopediaButton


func _ready() -> void:
	Globals.hud = self
	$EnergyBar.max_value = Globals.max_energy
	$EnergyBar.value = $EnergyBar.max_value
	set_process(false)


func hide_hud() -> void:
	visible = false
	hide_tutorial_box()
	close_dialogue_box()
	

func update_tutorial_box(text: String) -> void:
	%TutorialBox.visible = true
	%TutorialText.text = text


func hide_tutorial_box() -> void:
	%TutorialBox.visible = false
	%TutorialText.text = ""


var dialogue_pages: Array[String]
var page_num: int

func update_dialogue_box(pages: Array[String]) -> void:
	if pages.size():
		dialogue_pages = pages
		page_num = 0
		set_process(true)
		%DialogueBox.visible = true
		%DialogueText.text = dialogue_pages[0]
		%PageLabel.text = "1 / " + str(dialogue_pages.size())


## Reset and hide the dialogue box
func close_dialogue_box() -> void:
	%DialogueBox.visible = false
	%DialogueText.text = ""
	%PageLabel.text = ""
	set_process(false)
	hold_time = 0
	holding = false


## Move dialogue to the next page
func progress_dialogue_box() -> void:
	page_num += 1
	if page_num < dialogue_pages.size():
		%DialogueText.text = dialogue_pages[page_num]
		%PageLabel.text = str(page_num + 1) + " / " + str(dialogue_pages.size())
		hold_time = 0
		holding = false
	else:
		close_dialogue_box()


var holding := false
var hold_time: float = 0
const skip_duration: float = 0.8

func _process(delta: float) -> void:
	var was_holding = holding
	holding = Input.is_action_pressed("control dialogue")
	
	if holding:
		hold_time += delta
		if hold_time > skip_duration:
			close_dialogue_box()
	# Key released
	elif was_holding:
		progress_dialogue_box()


###
# Updates the wave countdown
# 
# Arguments : None
# Return : None
func update_wave_countdown(new_time: float) -> void:
	wave_countdown_label.text = str(maxi(0, ceili(new_time)))
	if new_time <= 5:
		wave_countdown_label.modulate = Color.RED
	else:
		wave_countdown_label.modulate = Color.WHITE


###
# Updates the energy bar
# 
# Arguments : None
# Return : None
func update_energy_bar(new_energy: float) -> void:
	$EnergyBar.value = new_energy


# 显示小地图
func show_minimap() -> void:
	if minimap:
		minimap.visible = true


# 隐藏小地图
func hide_minimap() -> void:
	if minimap:
		minimap.visible = false


# 切换小地图的显示状态
func toggle_minimap() -> void:
	if minimap:
		minimap.visible = not minimap.visible
