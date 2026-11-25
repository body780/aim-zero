class_name RangeAudio
extends Node

var firing: AudioStreamPlayer
var feedback: AudioStreamPlayer
var shot: AudioStreamWAV
var hit: AudioStreamWAV
var head: AudioStreamWAV


func _ready() -> void:
	firing = AudioStreamPlayer.new()
	feedback = AudioStreamPlayer.new()
	firing.max_polyphony = 2
	feedback.max_polyphony = 2
	add_child(firing)
	add_child(feedback)
	shot = _synth(0, 0.092)
	hit = _synth(1, 0.087)
	head = _synth(2, 0.142)


func fire(outcome: int, volume: float) -> void:
	if volume <= 0.0:
		return
	firing.volume_db = linear_to_db(volume * 0.65)
	firing.stream = shot
	firing.play()
	if outcome >= 2:
		feedback.volume_db = linear_to_db(volume * 0.55)
		feedback.stream = head if outcome == 3 else hit
		feedback.play()


static func _synth(kind: int, length: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	var samples := PackedByteArray()
	samples.resize(roundi(length * stream.mix_rate) * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 94225
	for index in samples.size() / 2:
		var time := float(index) / stream.mix_rate
		var sound: float
		if kind == 0:
			sound = rng.randf_range(-1.0, 1.0) * exp(-time * 98.0) * 0.55
			sound += sin(TAU * (178.0 * time - 620.0 * time * time)) * exp(-time * 45.0) * 0.52
		elif kind == 1:
			sound = (sin(TAU * time * 973.0) + sin(TAU * time * 1247.0) * 0.24) * exp(-time * 51.0) * 0.56
		else:
			sound = (sin(TAU * time * 1451.0) + sin(TAU * time * 2053.0) * 0.44) * exp(-time * 34.0) * 0.53
		sound *= minf(1.0, time * 3100.0)
		samples.encode_s16(index * 2, roundi(clampf(sound, -1.0, 1.0) * 32767.0))
	stream.data = samples
	return stream
