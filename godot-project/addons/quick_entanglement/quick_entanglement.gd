@tool
extends EditorPlugin

@export var entanglement_scene: PackedScene = preload("res://scenes/entangleable/entanglement.tscn")

var selection_mode := false
var delete_mode := false
var invert := false
var selected_nodes: Array[Node2D] = []

var check_active: CheckButton
var check_delete: CheckButton
var check_invert: CheckButton


func _enter_tree():
	# Creating checkboxes
	check_active = _create_checkbox("Quick Entangle", _activate_selection_mode)
	check_delete = _create_checkbox("Delete Mode", func(pressed): delete_mode = pressed)
	check_invert = _create_checkbox("Invert", func(pressed): invert = pressed)

	# Add checkboxes to toolbar
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, check_active)
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, check_delete)
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, check_invert)


func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, check_active)
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, check_delete)
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, check_invert)


func _activate_selection_mode(pressed: bool):
	selection_mode = pressed
	deselect()
	print("Quick Entanglement ", "activated" if selection_mode else "cancelled")


func _handles(object):
	return selection_mode and object is Node2D and object.is_in_group("Entangleable")


func _edit(object):
	if selection_mode and object not in selected_nodes:
		selected_nodes.append(object)
		print("Selected: ", object.name)

		if selected_nodes.size() == 2:
			_process_entanglement()
			deselect()


func deselect():
	EditorInterface.get_selection().clear()
	selected_nodes.clear()


func _process_entanglement():
	var manager: LevelManager = get_editor_interface().get_edited_scene_root()
	if not manager:
		return
	
	var data := {"a": selected_nodes[0], "b": selected_nodes[1], "invert": invert, "natural": true, "delete_mode": delete_mode}
	var result = manager.find_or_create_entanglement(data)
	
	# Pre-existing, newly created, or non-existant entanglement
	var c = result.connection
	
	# Connection created
	if result.new:
		var state = "inverted" if c.invert else "normal"
		print("Spawned ", state, " '", c.name, "': '", c.a.name, "' ↔ '", c.b.name + "'")
	# Entanglement already exists or trying to delete one that doesn't
	elif not c:
		print("Cannot create or delete there ...")
	# Deleting the connection
	elif delete_mode:
		print("Entanglement '", c.name, "' deleted")
		c.get_parent().remove_child(c)
		c.queue_free()
	# Inverting the connection
	elif invert:
		c.invert = not c.invert
		print("Entanglement inverted. Now ", "inverted" if c.invert else "normal")


# Helper function to create checkboxes
func _create_checkbox(text: String, callback: Callable) -> CheckButton:
	var checkbox = CheckButton.new()
	checkbox.text = text
	checkbox.toggled.connect(callback)
	return checkbox
