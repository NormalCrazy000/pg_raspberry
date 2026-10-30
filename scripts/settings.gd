extends Node
# Impostazioni del giocatore (autoload "Settings"), salvate in user://settings.json.
# Definisce anche l'azione "pause" (Esc o Start del gamepad).
# --lang=it|en e --graphics=auto|high|low valgono solo per questa esecuzione, senza salvarli.

const JsonFile := preload("res://scripts/common/json_file.gd")
const PATH := "user://settings.json"
const LANGUAGES := ["it", "en"]
const DEFAULTS := {
	"music_volume": 0.7, # 0..1
	"sfx_volume": 0.9, # 0..1
	"fullscreen": false,
	"aim_speed": 1.0, # moltiplicatore della mira con tastiera e gamepad
	"language": "", # vuoto = lingua del sistema (italiano se è italiano, altrimenti inglese)
	"graphics": "auto", # auto, high, low
}
const GRAPHICS := ["auto", "high", "low"]

var values := DEFAULTS.duplicate()
var forced_language := ""


func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS
	_add_pause_action()
	var saved := JsonFile.load_dict(PATH)
	for key in DEFAULTS:
		if saved.has(key) and typeof(saved[key]) == typeof(DEFAULTS[key]):
			values[key] = saved[key]
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--lang="):
			forced_language = arg.split("=")[1]
		elif arg.begins_with("--graphics="):
			values.graphics = arg.split("=")[1]
	apply()


func value(key: String):
	return values[key]


func set_value(key: String, new_value) -> void:
	values[key] = new_value
	apply()
	JsonFile.save_dict(PATH, values)


func language() -> String:
	if forced_language in LANGUAGES:
		return forced_language
	if values.language in LANGUAGES:
		return values.language
	return "it" if OS.get_locale().begins_with("it") else "en"


# Effetti grafici ridotti (niente aloni, particelle e scia). In automatico si riducono
# sul Raspberry Pi (GPU VideoCore) e sui processori ARM.
func low_graphics() -> bool:
	match values.graphics:
		"low":
			return true
		"high":
			return false
	var gpu := VisualServer.get_video_adapter_name().to_upper()
	return "VC4" in gpu or "V3D" in gpu or OS.has_feature("arm") or OS.has_feature("arm64") or OS.has_feature("arm32")


func apply() -> void:
	TranslationServer.set_locale(language())
	OS.window_fullscreen = values.fullscreen
	Audio.set_volumes(values.music_volume, values.sfx_volume)


func _add_pause_action() -> void:
	if InputMap.has_action("pause"):
		return
	InputMap.add_action("pause")
	var key := InputEventKey.new()
	key.scancode = KEY_ESCAPE
	InputMap.action_add_event("pause", key)
	var start := InputEventJoypadButton.new()
	start.button_index = JOY_START
	InputMap.action_add_event("pause", start)
