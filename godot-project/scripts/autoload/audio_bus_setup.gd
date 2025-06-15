extends Node

func _ready():
	# Make sure audio buses are set up
	setup_audio_buses()

# Set up audio bus layout if not already configured
func setup_audio_buses():
	# Check if "Music" bus exists, create if not
	if AudioServer.get_bus_index("Music") == -1:
		# Create Music bus
		AudioServer.add_bus()
		var music_bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(music_bus_idx, "Music")
		AudioServer.set_bus_send(music_bus_idx, "Master")
		
		# Set default volume
		AudioServer.set_bus_volume_db(music_bus_idx, -5.0)
	
	# Check if "SFX" bus exists, create if not
	if AudioServer.get_bus_index("SFX") == -1:
		# Create SFX bus
		AudioServer.add_bus()
		var sfx_bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(sfx_bus_idx, "SFX")
		AudioServer.set_bus_send(sfx_bus_idx, "Master")
		
		# Set default volume
		AudioServer.set_bus_volume_db(sfx_bus_idx, 0.0) 
