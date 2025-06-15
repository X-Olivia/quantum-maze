extends Node
class_name GameManager


const player_save_path: String = "user://player_save.json"
const game_data_path: String = "res://data/game_data.json"

var save_data: Dictionary
var player_save_data: Dictionary

@onready var menus: Dictionary = {
	"main": %Main,
	"level_select": %LevelSelect,
	"pause": %Pause,
	"level_complete": %LevelComplete,
	"confirm_reset": %ConfirmReset,
	"options": %Options,
	"death": %Death,
	"story_playback": %StoryPlayback,
	"encyclopedia": %Encyclopedia,
}

var current_menu: Control = null
var last_menu_name: String = "main"

var current_level: LevelManager = null
var next_level_id: String = "0"

var playing: bool = false

var paused: bool = false

# Flag to track if splash screen has been shown
var splash_played: bool = false


var empty_player_save = {
	"0": {
		"best_time": 0,
		"collectables": [],
		"unlocked": true
	},
	"1": {
		"best_time": 0,
		"collectables": [],
		"unlocked": false
	},
	"2": {
		"best_time": 0,
		"collectables": [],
		"unlocked": false
	},
	"3": {
		"best_time": 0,
		"collectables": [],
		"unlocked": false
	},
	"is_new_game": true
}


'''
JSON file and dictionary formatting
-----------------------------------------------------

game_data.json =
{
	FOR ALL LEVELS
	"level_id": {
		"ability_config": {
			"dash": bool,
			"entanglement": bool,
			"parry": bool,
			"shoot": bool
		},
		"name": "level_name",
		"unlocked": bool,
		"collectable_num": int,
		"ghost_data": {"ghost_name": "RAW_DATA", ... },
	},
}

player_save.json = player_save_data =
{
	"is_new_game": bool,
	
	FOR ALL LEVELS
	"level_id": {
		"best_time": float,
		"collectables": [bool, ... ],
		"unlocked": true
	},
}

save_data = game_data + player_save =
{
	"is_new_game": bool,
	
	FOR ALL LEVELS
	"level_id": {
		"ability_config": {
			"dash": bool,
			"entanglement": bool,
			"parry": bool,
			"shoot": bool
		},
		"name": "level_name",
		"unlocked": bool
		"collectables": [bool, ... ],
		"ghost_data": {"ghost_name": "RAW_DATA", ... },
	},
}
'''


func _ready() -> void:
	Globals.game_manager = self
	
	var open_menu_func := Callable(self, "open_menu")
	
	%NewGame.pressed.connect(open_menu_func.bind("confirm_reset"))
	
	for options_button in [%Main/Buttons/Options, %Pause/Buttons/Options]:
		options_button.pressed.connect(open_menu_func.bind("options"))
	
	# Connect encyclopedia button to open menu
	Globals.hud.encyclopedia_button.pressed.connect(open_menu_func.bind("encyclopedia"))

	# Connect the Main continue button to open story playback
	%Main/Buttons/Continue.pressed.connect(open_story_playback)
	
	# Connect StoryPlayback continue button to level select
	%StoryPlayback/StoryContainer/ButtonContainer/ContinueButton.pressed.connect(open_level_select_menu)
	
	# Connect level navigation buttons
	%PrevButton.pressed.connect(Callable(%LevelCards, "previous_level"))
	%NextButton.pressed.connect(Callable(%LevelCards, "next_level"))
	
	Signals.died.connect(handle_death)
	
	# Wipe temp_ghost_data.txt (if present)
	var file := FileAccess.open("res://data/temp_ghost_data.txt", FileAccess.WRITE)
	if file:
		file.store_string("")
		file.close()
	
	# Create default template save file from game_data.json
	new_save_data()
	
	# Read from (creating if absent) local player save
	player_save_data = read_from_json(player_save_path)
	if player_save_data.is_empty() or Globals.DEBUG:
		# Create player_save, update from new save_data and write to local
		new_player_save_data()
	else:
		# Update empty save_data with non-empty player_save_data
		recursive_update(save_data, player_save_data)		
	
	%LevelCards.setup(self, save_data)
	
	# Start muted in debug mode
	if Globals.DEBUG:
		%VolumeSlider.value = 0.0
		%VolumeSlider.emit_signal("drag_ended", true)
	
	# Play splash screen animation first
	play_splash_animation()


func recursive_update(to_update: Dictionary, update_from: Dictionary) -> Dictionary:
	for key in update_from.keys():
		if to_update.has(key):
			var new_value = update_from[key]
			var old_value = to_update[key]
			
			if typeof(new_value) == TYPE_DICTIONARY and typeof(old_value) == TYPE_DICTIONARY:
				# Recursively update nested dictionaries
				recursive_update(old_value, new_value)
			else:
				# Update the value if it's not a dictionary
				to_update[key] = new_value
	return to_update


func new_save_data() -> void:
	save_data = read_from_json(game_data_path)
	assert(not save_data.is_empty())
	
	# Delete DEBUG levels
	if not Globals.DEBUG:
		for level_num in save_data.keys().duplicate():
			if int(level_num) < 0:
				save_data.erase(level_num)
	
	for level_data in save_data.values():
		if level_data is Dictionary:
			level_data["best_time"] = 0
			
			if Globals.DEBUG:
				level_data["unlocked"] = true
			
			level_data["collectables"] = []
			for i in level_data.collectable_num:
				level_data["collectables"].append(false)
			level_data.erase("collectable_num")
		
	save_data["is_new_game"] = true


func new_player_save_data() -> void:
	player_save_data = empty_player_save.duplicate()
	write_to_player_save_json()


func write_to_json(path: String, data: Dictionary) -> void:
	if Globals.DEBUG:
		return
		
	var abs_path = ProjectSettings.globalize_path(path)
	var file = FileAccess.open(abs_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func write_to_player_save_json() -> void:
	# Update player_save_data with save_data
	recursive_update(player_save_data, save_data)
	# Save changes to player_save.json
	write_to_json(player_save_path, player_save_data)


func wipe_save_data() -> void:
	new_save_data()
	new_player_save_data()
	open_main_menu()
	

func read_from_json(path: String) -> Dictionary:
	
	var abs_path = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(abs_path):
		return {}
	
	var file := FileAccess.open(abs_path, FileAccess.READ)
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()
	
	if parse_result != OK:
		assert(false, "ERROR parsing JSON file: %s at line %d" % [json.get_error_message(), json.get_error_line()])

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		assert(false, "ERROR: JSON root is not a dictionary.")

	# Sort levels in order using id
	var level_ids = data.keys()
	level_ids.sort()

	var sorted_data = {}
	for id in level_ids:
		sorted_data[id] = data[id]
		
	return sorted_data


func open_menu(menu_name: String) -> void:
	if menus.has(menu_name):
		close_current_menu()
		current_menu = menus[menu_name]
		current_menu.visible = true
	
	if current_level:
		current_level.process_mode = Node.PROCESS_MODE_DISABLED


func close_current_menu() -> void:
	if current_menu:
		last_menu_name = current_menu.name.to_snake_case()
		
		# If leaving main menu, stop the background video
		if current_menu == %Main and %Main/BackgroundVideo and %Main/BackgroundVideo.is_playing():
			%Main/BackgroundVideo.stop()
		
		# If leaving level select menu, stop the background video
		if current_menu == %LevelSelect and %LevelSelect/BackgroundVideo and %LevelSelect/BackgroundVideo.is_playing():
			%LevelSelect/BackgroundVideo.stop()
			
		# If leaving level complete menu, stop the background video
		if current_menu == %LevelComplete and %LevelComplete/BackgroundVideo and %LevelComplete/BackgroundVideo.is_playing():
			%LevelComplete/BackgroundVideo.stop()
			
		# If leaving death menu, stop the background video
		if current_menu == %Death and %Death/DeathVideo and %Death/DeathVideo.is_playing():
			%Death/DeathVideo.stop()
		
		current_menu.visible = false
		current_menu = null
		
	if current_level:
		current_level.process_mode = Node.PROCESS_MODE_INHERIT


func load_level(id: String) -> void:
	if not save_data.has(id):
		return
	
	if current_level and not current_level.is_completed:
		return
	
	var level_data: Dictionary = save_data.get(id)
	if not level_data.unlocked:
		return
	
	# 重置玩家的冻结状态
	Globals.player_frozen = false
	
	# Start fade out animation
	%TransitionLayer/AnimationPlayer.play("fade")
	await %TransitionLayer/AnimationPlayer.animation_finished
	
	close_current_menu()
	
	var level_name: String = level_data.name
	var new_level: LevelManager = load("res://scenes/levels/%s.tscn" % level_name).instantiate()
	
	Globals.level = new_level
	
	new_level.name = level_name
	
	if not current_level:
		add_child(new_level)
	else:
		current_level.replace_by(new_level)
	
	new_level.setup(id, level_data)
	
	current_level = new_level
	%HUD.visible = true
	playing = true
	
	save_data.is_new_game = false
	write_to_player_save_json()
	
	# Emit signal for audio manager
	Signals.emit_level_loaded(id)
	
	# Start fade in animation
	%TransitionLayer/AnimationPlayer.play("unfade")


func unload_level(play_default_music := true) -> void:
	%HUD.hide_hud()
	
	if current_level:
		remove_child(current_level)
		current_level.queue_free()
		current_level = null
	
	# Emit signal for audio manager
	if play_default_music:
		Signals.emit_level_unloaded()
	
	paused = false
	playing = false


func _process(_delta: float) -> void:
	if playing:
		# Original game logic for when a level is playing
		if current_level and current_level.is_completed:
			handle_level_completed()
		
		if Input.is_action_just_pressed("pause"):
			handle_pausing()


func handle_level_completed(open_level_complete := true) -> void:
	if not current_level:
		return
	
	save_data.is_new_game = false
	current_level.is_completed = true
	
	var best_time = save_data[current_level.id].best_time
	if best_time == 0.0 or current_level.timer < best_time:
		save_data[current_level.id].best_time = current_level.timer

	# Unlock the next level, if it exists
	if current_level:
		var next_id: String = str(int(current_level.id) + 1)
		if save_data.has(next_id):
			next_level_id = next_id
			save_data[next_id].unlocked = true
	
	# Write save data to JSON
	write_to_player_save_json()
	
	unload_level(open_level_complete)
	
	if open_level_complete:
		open_menu("level_complete")
		
		# Start background video playback for level complete menu
		if %LevelComplete/BackgroundVideo and not %LevelComplete/BackgroundVideo.is_playing():
			%LevelComplete/BackgroundVideo.play()


func handle_pausing() -> void:
	paused = not paused
	if paused:
		open_menu("pause")
	else:
		close_current_menu()


func handle_death(death_type: String = "default") -> void:
	%HUD.hide_tutorial_box()
	%HUD.close_dialogue_box()
	
	if death_type == "death_zone":
		var shader_material = %DeathZoneLayer/MaskedPlayer/PlayerSprite.material
		shader_material.set_shader_parameter("radius", 1.0)
		
		%DeathZoneLayer.visible = true
	
		%DeathZoneLayer/AnimationPlayer.play("death_zone_sink")
		await %DeathZoneLayer/AnimationPlayer.animation_finished

		%DeathZoneLayer.visible = false
	else:
		var shader_material = %DefaultDeathLayer/PlayerImage.material
		shader_material.set_shader_parameter("progress", 0.0)
		
		%DefaultDeathLayer.visible = true
		
		%DefaultDeathLayer/AnimationPlayer.play("default_death")
		await %DefaultDeathLayer/AnimationPlayer.animation_finished
		
		%DefaultDeathLayer.visible = false
	
	# Start fade out animation
	%TransitionLayer/AnimationPlayer.play("fade")
	await %TransitionLayer/AnimationPlayer.animation_finished
	
	open_menu("death")
	
	# Play the death video
	if %Death/DeathVideo and not %Death/DeathVideo.is_playing():
		%Death/DeathVideo.play()
	
	# Start fade in animation
	%TransitionLayer/AnimationPlayer.play("unfade")


func respawn() -> void:
	current_level.revert_to_checkpoint()
	close_current_menu()


func open_main_menu() -> void:
	# Only show main menu directly if splash has already been played
	%NewGame.disabled = save_data.is_new_game
	
	# Open the main menu
	open_menu("main")
	
	# Start background video playback for the main menu
	if %Main/BackgroundVideo and not %Main/BackgroundVideo.is_playing():
		%Main/BackgroundVideo.play()


func open_level_select_menu() -> void:
	# Add a transition regardless of source menu
	# Start fade out animation
	%TransitionLayer/AnimationPlayer.play("fade")
	await %TransitionLayer/AnimationPlayer.animation_finished
	
	unload_level()
	%LevelCards.update(save_data)
	open_menu("level_select")

	# Start background video playback for level select menu
	if %LevelSelect/BackgroundVideo and not %LevelSelect/BackgroundVideo.is_playing():
		%LevelSelect/BackgroundVideo.play()
	
	# Fade back in
	%TransitionLayer/AnimationPlayer.play("unfade")


func open_previous_menu() -> void:
	if last_menu_name == "main":
		open_main_menu()
	else:
		open_menu(last_menu_name)


func load_next_level() -> void:
	load_level(next_level_id)


# Play the splash screen animation
func play_splash_animation() -> void:
	# Make sure splash screen is visible and other UIs are hidden
	%SplashScreen.visible = true
	
	# Hide all menus during splash animation
	for menu in menus.values():
		menu.visible = false
	
	# Ensure video is playing
	var video_player = %SplashScreen/VideoStreamPlayer
	if not video_player.is_playing():
		video_player.play()


# Called when the video playback finishes
func _on_video_finished() -> void:
	# Hide splash screen immediately
	%SplashScreen.visible = false
	splash_played = true
	
	# Go to main menu
	open_main_menu()


#var story_layer: CanvasLayer
#var video_player: VideoStreamPlayer
#var choice_buttons: Control

var on_credits := false

func _input(event: InputEvent) -> void:
	if %SplashScreen.visible and (event is InputEventMouseButton or event is InputEventKey):
		if event.pressed:
			# Stop video and animation
			%SplashScreen/VideoStreamPlayer.stop()
			%AnimationPlayer.stop()
			# Skip to main menu
			_on_video_finished()
			
	# Skip ending cutscenes with Escape or Enter
	if %EndVideo.stream and event is InputEventKey and event.pressed and event.keycode in [KEY_ESCAPE, KEY_ENTER]:
		if not on_credits:
			story_choice_made(0)
		else:
			end_ack_video()


func play_goal_transition() -> void:
	%GoalTransitionLayer.visible = true
	
	var goal_video = %GoalTransitionLayer/GoalVideo
	
	if goal_video:
		goal_video.scale = Vector2(1, 1)
		goal_video.stop()
		goal_video.play()
	
	var animation_player = %GoalTransitionLayer/AnimationPlayer
	if animation_player:
		animation_player.play("goal_transition")
		await animation_player.animation_finished
	
	handle_level_completed()
	
	%GoalTransitionLayer.visible = false


func play_level4_ending() -> void:
	# First move the camera to focus on the player's position
	# This is similar to how game_over() moves the camera in player_manager.gd
	if Globals.player and is_instance_valid(Globals.player):
		var death_pos = Globals.player.global_position
		
		# Make sure player's character is hidden
		Globals.player.visible = false
		
		# Reposition camera exactly like in PlayerManager.game_over()
		if Globals.camera:
			Globals.camera.reparent(self)
			Globals.camera.global_position = death_pos
	
	# Prepare DeathZoneLayer for the sink effect
	var shader_material = %DeathZoneLayer/MaskedPlayer/PlayerSprite.material
	if shader_material:
		shader_material.set_shader_parameter("radius", 1.0)
	
	# Freeze all level objects immediately
	if current_level:
		current_level.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Make DeathZoneLayer visible
	%DeathZoneLayer.visible = true
	
	# Fade out music
	AudioManager.custom_fade_out_music(3.0)
	
	# Start both animations simultaneously
	%TransitionLayer/AnimationPlayer.play("fade")
	%DeathZoneLayer/AnimationPlayer.play("death_zone_sink")
	
	# Wait for both animations to finish (use the longer one)
	await %DeathZoneLayer/AnimationPlayer.animation_finished
	
	# Hide DeathZoneLayer after animation
	%DeathZoneLayer.visible = false
	
	# Level complete, save player data but DON'T open level_complete menu
	handle_level_completed(false)
	
	# Play story.ogv video immediately after the screen is dark
	play_story_video()


func play_story_video() -> void:
	$EndLayer.visible = true
	#%EndVideo.volume_db = AudioManager.default_volume_db
	
	# Create video stream directly
	var video = VideoStreamTheora.new()
	video.file = "res://assets/videos/story.ogv"
	%EndVideo.stream = video
	
	# Add the choice buttons UI (initially hidden)
	var choice_buttons_scene = load("res://scenes/gui/story_choice_buttons.tscn")
	choice_buttons = choice_buttons_scene.instantiate()
	$EndLayer.add_child(choice_buttons)
	
	# Connect choice button signals - both choices play the ack video
	choice_buttons.choice_made.connect(story_choice_made)
	
	# Play video and start the timer
	%EndVideo.play()
	
	# Create a timer to show the buttons at 46 seconds
	get_tree().create_timer(45).timeout.connect(choice_buttons.show_choices)


var choice_buttons: Control
func story_choice_made(_choice: int) -> void:
	
	# Clean up choice buttons
	choice_buttons.queue_free()
	
	# Add an animation for fading out the video and audio
	var fade_tween = create_tween()
	
	# Fade out video over 2 seconds
	fade_tween.tween_property(%EndVideo, "modulate", Color(1, 1, 1, 0), 2.0)
	
	# When the fade is complete, set up a delay and start the ack video
	fade_tween.tween_callback(func():
		# Stop the video playback after fading
		%EndVideo.stop()
		
		# Create a delay timer before playing the ack video
		get_tree().create_timer(3).timeout.connect(play_ack_video)
	)
	

func end_ack_video() -> void:
	# Fade out
	%TransitionLayer/AnimationPlayer.play("unfade")
	await %TransitionLayer/AnimationPlayer.animation_finished
	
	%EndVideo.stream = null
	$EndLayer.visible = false
	on_credits = false
	
	# Return to level selection
	open_level_select_menu()
	
	# Fade default music back in
	AudioManager.fade_in_music()


func play_ack_video() -> void:
	on_credits = true
	
	# Create video stream directly
	var video = VideoStreamTheora.new()
	video.file = "res://assets/videos/ack.ogv"
	%EndVideo.stream = video
	
	# Connect video completion event
	%EndVideo.finished.connect(end_ack_video)
	
	# Play video
	%EndVideo.modulate = Color.WHITE
	%EndVideo.play()


func open_story_playback() -> void:
	if not save_data.is_new_game:
		open_level_select_menu()
	else:
		# Start fade out animation
		%TransitionLayer/AnimationPlayer.play("fade")
		await %TransitionLayer/AnimationPlayer.animation_finished
		
		open_menu("story_playback")
		
		# Fade back in
		%TransitionLayer/AnimationPlayer.play("unfade")


func back_to_main_menu() -> void:
	# Start fade out animation
	%TransitionLayer/AnimationPlayer.play("fade")
	await %TransitionLayer/AnimationPlayer.animation_finished
	
	open_main_menu()
	
	# Fade back in
	%TransitionLayer/AnimationPlayer.play("unfade")


func exit_game() -> void:
	get_tree().quit(0)


func _on_volume_change(value_changed: bool) -> void:
	if value_changed:
		AudioManager.set_music_volume(%VolumeSlider.value / 100)


func _on_fullscreen_toggled(_toggled_on: bool) -> void:
	Globals.toggle_fullscreen()
