extends Node

# Audio streams for different levels
var default_music: AudioStream = preload("res://assets/music/default.mp3")
var level1_music: AudioStream = preload("res://assets/music/l1.mp3")
var level2_music: AudioStream = preload("res://assets/music/l2.mp3")
var level3_music: AudioStream = preload("res://assets/music/l3.mp3")
var level4_music: AudioStream = preload("res://assets/music/l4.mp3")

# Audio player for background music
var music_player: AudioStreamPlayer = null
var current_music: String = ""  # Tracks the currently playing music

const FADE_DURATION: float = 1.0  
var fade_tween: Tween = null
var default_volume_db: float = -5.0

const SILENCE_DB: float = -80.0


# Initialize the audio player
func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.volume_db = SILENCE_DB 
	add_child(music_player)
	
	# Connect signals
	Signals.level_loaded.connect(Callable(self, "_on_level_loaded"))
	Signals.level_unloaded.connect(Callable(self, "_on_level_unloaded"))
	
	# Start default music when game launches
	play_default_music()


# Play the default background music for menus and non-level areas
func play_default_music():
	if current_music != "default":
		_change_music(default_music)
		current_music = "default"

# Play specific level music
func play_level_music(level_id: String):
	match level_id:
		"0":  # level1
			if current_music != "level1":
				_change_music(level1_music)
				current_music = "level1"
		"1":  # level2
			if current_music != "level2":
				_change_music(level2_music) 
				current_music = "level2"
		"2":  # level3
			if current_music != "level3":
				_change_music(level3_music)
				current_music = "level3"
		"3":  # level4
			if current_music != "level4":
				_change_music(level4_music)
				current_music = "level4"
		_:
			# For any other level ID, play default music
			play_default_music()

# Helper function to switch music tracks with crossfade
func _change_music(new_stream: AudioStream):
	# 如果有正在运行的渐变，停止它
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	# 如果音乐在播放，先淡出
	if music_player.playing:
		fade_out_music()
		# 等待淡出完成后再播放新音乐
		await get_tree().create_timer(FADE_DURATION).timeout
		
	# 设置新音乐并播放（从静音开始，然后淡入）
	music_player.stream = new_stream
	music_player.volume_db = SILENCE_DB # 几乎静音的起始值
	music_player.play()
	
	# 淡入新音乐
	fade_in_music()

# 淡出当前音乐
func fade_out_music():
	fade_tween = create_tween()
	fade_tween.tween_property(music_player, "volume_db", -80.0, FADE_DURATION)

# 自定义时间淡出当前音乐
func custom_fade_out_music(duration: float = 1.0):
	# 如果有正在运行的渐变，停止它
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
		
	# 创建新的淡出效果
	fade_tween = create_tween()
	fade_tween.tween_property(music_player, "volume_db", -80.0, duration)
	return fade_tween  # 返回tween对象以便外部监听完成事件

# 淡入当前音乐
func fade_in_music():
	fade_tween = create_tween()
	fade_tween.tween_property(music_player, "volume_db", default_volume_db, FADE_DURATION)

# Handle when a level is loaded
func _on_level_loaded(level_id: String):
	play_level_music(level_id)

# Handle when a level is unloaded
func _on_level_unloaded():
	play_default_music()

# Set volume (value between 0.0 and 1.0)
func set_music_volume(volume: float):
	var db_volume = max(linear_to_db(volume), SILENCE_DB)
	default_volume_db = db_volume
	
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
		fade_tween = null
	
	music_player.volume_db = db_volume
