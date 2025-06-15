extends StaticBody2D

@onready var heavy_button: HeavyButton = get_parent()


func damage(value: Variant) -> Dictionary:
	var was_pressed: bool = heavy_button.pressed
	if value.has("callee"):
		heavy_button.press(value.callee)
	return {"stop": heavy_button.pressed and was_pressed}
