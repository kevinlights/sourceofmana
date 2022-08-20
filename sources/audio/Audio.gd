extends Node

var audioPlayer : AudioStreamPlayer				= null
var currentTrack : String = ""

#
func Play(pause : bool = false):
	if pause:
		audioPlayer.pause()
	else:
		audioPlayer.play()
	pass

func Stop():
	if audioPlayer.is_playing():
		audioPlayer.Stop()

func Load(soundName : String):
	if audioPlayer == null:
		audioPlayer = Launcher.World.get_node("AudioStreamPlayer")

	assert(audioPlayer, "AudioStreamPlayer could not be found")

	if audioPlayer && currentTrack != name:
		if not soundName.is_empty() && Launcher.DB.MusicsDB[name] != null:
			var soundStream : Resource = Launcher.FileSystem.LoadMusic(Launcher.DB.MusicsDB[name]._path)
			if soundStream != null:
				soundStream.set_loop(true)

				audioPlayer.stream	= soundStream
				currentTrack		= soundName

				audioPlayer.set_autoplay(true)
				audioPlayer.play()

#
func _ready():
	if audioPlayer == null:
		audioPlayer = AudioStreamPlayer.new()
		get_tree().get_root().add_child(audioPlayer)
