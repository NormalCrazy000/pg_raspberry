extends Node
# Effetti sonori e musica (autoload "Audio"). I suoni sono generati da tools/assets/make_audio.py.
#   Audio.play("peg", pitch)   effetto sonoro
#   Audio.play_music()         musica di sottofondo in loop

const SOUNDS := {
	"peg": preload("res://assets/audio/peg.wav"),
	"bug": preload("res://assets/audio/bug.wav"),
	"coffee": preload("res://assets/audio/coffee.wav"),
	"launch": preload("res://assets/audio/launch.wav"),
	"bucket": preload("res://assets/audio/bucket.wav"),
	"portal": preload("res://assets/audio/portal.wav"),
	"extra": preload("res://assets/audio/extra.wav"),
	"multiplier": preload("res://assets/audio/multiplier.wav"),
	"win": preload("res://assets/audio/win.wav"),
	"click": preload("res://assets/audio/click.wav"),
}
const MUSIC := preload("res://assets/audio/music.ogg")
const VOICES := 8 # effetti che possono suonare insieme
const MUSIC_DB := -8.0

var players := []
var next_player := 0
var music_player: AudioStreamPlayer
var muted := false


func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS
	# Nei test automatici e nel benchmark niente audio (ma sì con --measure, che misura il gioco vero).
	var args := Array(OS.get_cmdline_args())
	for arg in args:
		if (arg.begins_with("--autoplay") or arg == "--bench") and not args.has("--measure"):
			muted = true
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		players.append(player)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = MUSIC_DB
	add_child(music_player)


func play(sound: String, pitch := 1.0, volume_db := 0.0) -> void:
	if muted or not SOUNDS.has(sound):
		return
	var player: AudioStreamPlayer = players[next_player]
	next_player = (next_player + 1) % players.size()
	player.stream = SOUNDS[sound]
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()


func play_music() -> void:
	if muted or music_player.playing:
		return
	var stream: AudioStreamOGGVorbis = MUSIC
	stream.loop = true
	music_player.stream = stream
	music_player.play()
