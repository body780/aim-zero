class_name AcceptanceCapture
extends RefCounted

# Dedicated acceptance runs only. Buffer a 120-second session above 4,000 FPS.
const CAPACITY := 524288
var intervals := PackedInt64Array()
var motions := PackedInt32Array()
var count := 0
var dropped := 0
var previous := 0
var pending := 0

func _init() -> void:
	intervals.resize(CAPACITY)
	motions.resize(CAPACITY)

func frame(now: int) -> void:
	if previous != 0:
		if count < CAPACITY:
			intervals[count] = now - previous
			motions[count] = pending
			count += 1
		else:
			dropped += 1
	previous = now
	pending = 0

func save(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_line("frame_us,mouse_events")
	for i in count:
		file.store_line("%d,%d" % [intervals[i], motions[i]])
	file.flush()
	var error := file.get_error()
	file.close()
	return ERR_OUT_OF_MEMORY if dropped > 0 else error
