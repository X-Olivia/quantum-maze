extends Control

signal choice_made(choice: int)

# Set to false initially as we don't want buttons visible at start
func _ready():
	visible = false
	
	# Connect button signals
	%Choice1Button.pressed.connect(func(): _on_choice_made(1))
	%Choice2Button.pressed.connect(func(): _on_choice_made(2))

# Show the buttons
func show_choices():
	visible = true

# Hide the buttons
func hide_choices():
	visible = false

# Called when a choice button is pressed
func _on_choice_made(choice_number: int):
	choice_made.emit(choice_number)
	hide_choices() 
