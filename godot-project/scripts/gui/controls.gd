extends VBoxContainer


@export var showing := false


func _ready() -> void:
	if showing:
		$CheckButton.set_pressed_no_signal(true)


func _on_control_visibility_toggled(_toggled_on: bool) -> void:
	showing = not showing
	$ControlsTitle.visible = showing
	$TopSeparator.visible = showing
	$Controls.visible = showing
	$BottomSeparator.visible = showing
