class_name FrameMetrics
extends RefCounted

const CAPACITY := 16384
const WINDOW_USEC := 4000000

var times := PackedInt64Array()
var intervals := PackedInt64Array()
var start := 0
var count := 0
var total := 0
var last := 0
var last_update := 0
var last_frame := 0.0
var instant := 0.0
var average := 0.0
var low := 0.0


func _init() -> void:
	times.resize(CAPACITY)
	intervals.resize(CAPACITY)


func sample(now: int) -> bool:
	if last == 0 or now - last > WINDOW_USEC:
		last = now
		start = 0
		count = 0
		total = 0
		last_update = now
		last_frame = 0.0
		instant = 0.0
		average = 0.0
		low = 0.0
		return true
	var interval := maxi(1, now - last)
	last = now
	while count > 0 and (count == CAPACITY or now - times[start] > WINDOW_USEC):
		total -= intervals[start]
		start = (start + 1) % CAPACITY
		count -= 1
	var write := (start + count) % CAPACITY
	times[write] = now
	intervals[write] = interval
	total += interval
	count += 1
	last_frame = interval / 1000.0
	instant = 1000000.0 / interval
	average = count * 1000000.0 / total
	if now - last_update < 250000:
		return false
	if now - last_update >= 250000 and count > 0:
		last_update = now
		if count >= 100:
			var ordered := PackedInt64Array()
			ordered.resize(count)
			for index in count:
				ordered[index] = intervals[(start + index) % CAPACITY]
			ordered.sort()
			var worst := ceili(count * 0.01)
			var elapsed := 0
			for index in range(count - worst, count):
				elapsed += ordered[index]
			low = worst * 1000000.0 / elapsed
		else:
			low = 0.0
	return true
