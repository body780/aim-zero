class_name FrameMetrics
extends RefCounted

const CAPACITY := 16384
const WINDOW_USEC := 4000000

# 25 us bins, with an overflow bin retaining its true elapsed sum.
const BIN_US := 25
const BINS := 512
var frequencies := PackedInt32Array()
var sums := PackedInt64Array()
var p99_ms := 0.0
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
	frequencies.resize(BINS)
	sums.resize(BINS)
	times.resize(CAPACITY)
	intervals.resize(CAPACITY)


func sample(now: int) -> bool:
	if last == 0 or now - last > WINDOW_USEC:
		frequencies.fill(0)
		sums.fill(0)
		p99_ms = 0
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
		var old_bin := mini(intervals[start] / BIN_US, BINS - 1)
		frequencies[old_bin] -= 1
		sums[old_bin] -= intervals[start]
		total -= intervals[start]
		start = (start + 1) % CAPACITY
		count -= 1
	var write := (start + count) % CAPACITY
	times[write] = now
	intervals[write] = interval
	var bin := mini(interval / BIN_US, BINS - 1)
	frequencies[bin] += 1
	sums[bin] += interval
	total += interval
	count += 1
	last_frame = interval / 1000.0
	instant = 1000000.0 / interval
	average = count * 1000000.0 / total
	if now - last_update < 250000:
		return false
	last_update = now
	var worst := ceili(count * 0.01)
	var remaining := worst
	var tail_us := 0.0
	for bin_index in range(BINS - 1, -1, -1):
		var n := frequencies[bin_index]
		if n == 0:
			continue
		var take := mini(n, remaining)
		tail_us += float(sums[bin_index]) * take / n
		remaining -= take
		if remaining == 0:
			p99_ms = (bin_index * BIN_US) / 1000.0
			break
	low = worst * 1000000.0 / tail_us if count >= 100 else 0.0
	return true
