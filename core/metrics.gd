class_name TrainingMetrics
extends RefCounted

const WIDTH := 15
const HEIGHT := 11
const CELLS := WIDTH * HEIGHT
const X_LIMIT := 12.0
const Y_LIMIT := 8.0

const COUNTERS := [
	"shots", "hits", "heads", "reaction_n", "reaction_ms", "over", "under", "on",
	"unsettled", "stop_shots", "expired", "opportunities", "track_ticks", "track_on", "preaim_n", "preaim_deg"
]

var values: Dictionary = {}
var heat := PackedInt32Array()


func _init() -> void:
	for key: String in COUNTERS:
		values[key] = 0.0
	heat.resize(CELLS)


func add(key: String, amount: float = 1.0) -> void:
	values[key] += amount


func record_error(error: Vector2) -> void:
	var column := clampi(floori((rad_to_deg(error.x) / -X_LIMIT + 1.0) * WIDTH * 0.5), 0, WIDTH - 1)
	var row := clampi(floori((1.0 - rad_to_deg(error.y) / Y_LIMIT) * HEIGHT * 0.5), 0, HEIGHT - 1)
	heat[row * WIDTH + column] += 1


func record_flick(start_error: Vector2, end_error: Vector2, angular_radius: float) -> void:
	var required := start_error.length()
	if required < maxf(angular_radius * 1.4, deg_to_rad(0.2)):
		return
	var along := end_error.dot(-start_error / required)
	if along > angular_radius * 0.55:
		add("over")
	elif along < -angular_radius * 0.55:
		add("under")
	else:
		add("on")


func merge(other: TrainingMetrics) -> void:
	for key: String in COUNTERS:
		add(key, other.values[key])
	for index in CELLS:
		heat[index] += other.heat[index]


func snapshot(mode: String, seconds: float) -> Dictionary:
	var result := values.duplicate()
	result["mode"] = mode
	result["seconds"] = seconds
	result["heat"] = Array(heat)
	return result


static func ratio(numerator: float, denominator: float) -> float:
	return numerator / denominator if denominator > 0.0 else 0.0


static func percent(numerator: float, denominator: float) -> String:
	return "—" if denominator <= 0.0 else "%.1f%%" % (100.0 * ratio(numerator, denominator))


static func average_reaction(data: Dictionary) -> String:
	return "—" if data.reaction_n == 0 else "%.0f 毫秒" % ratio(data.reaction_ms, data.reaction_n)


static func hits_per_minute(data: Dictionary) -> float:
	return ratio(data.hits * 60.0, data.seconds)


static func drill_priority(data: Dictionary) -> float:
	var mode: String = data.mode
	if mode == "track":
		return 1.0 - ratio(data.track_on, data.track_ticks)
	if mode == "head":
		return 1.0 - ratio(data.heads, data.shots)
	if mode == "reaction":
		var timeout_rate := ratio(data.expired, data.opportunities)
		var reaction := clampf(ratio(data.reaction_ms, data.reaction_n) / 750.0, 0.0, 1.0)
		return maxf(timeout_rate, reaction)
	if mode == "peek":
		var exposure_error := clampf(ratio(data.preaim_deg, data.preaim_n) / 15.0, 0.0, 1.0)
		return maxf(exposure_error, 1.0 - ratio(data.heads, data.shots))
	if mode == "stop":
		return maxf(ratio(data.unsettled, data.stop_shots), 1.0 - ratio(data.hits, data.shots))
	return 1.0 - ratio(data.hits, data.shots)
