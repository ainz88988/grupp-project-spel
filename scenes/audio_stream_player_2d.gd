extends AudioStreamPlayer2D

var is_audio_playing = false

var sound_effects = {
	"Pistol_shot": preload("res://audio/pistol-shot-233473.mp3"),
	"Shotgun_shot": preload("res://audio/080902_shotgun-39753.mp3")
}

func play_sound(sound_name: String):
	if sound_name in sound_effects:
		if is_playing():
			is_audio_playing = true
			stop()
		else:
			is_audio_playing = false
		stream = sound_effects[sound_name]
		play()
	else:
		print("Sound effect not found: ", sound_name)
