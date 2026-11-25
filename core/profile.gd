class_name LocalProfile
extends RefCounted

const LIMITS := [60, 120, 144, 165, 180, 240, 360, 480, 500, 600, 1000, 0]
const DEFAULTS := {
	"sensitivity": 0.35, "dpi": 800, "fov": 103.0, "fps_limit": 0, "fullscreen": false,
	"vsync": false, "raw": true, "quality": 0, "perf": true, "audio": 0.65,
	"color": "#75ffe0", "gap": 5, "length": 7, "thickness": 2, "dot": false, "outline": true
}
const MAX_FILE := 12 * 1024 * 1024
const MAX_HISTORY := 500

var path: String
var settings := DEFAULTS.duplicate()
var records: Array = []


func _init(storage_path: String = "user://aim-zero.json") -> void:
	path = storage_path


func load_local() -> void:
	var parsed := read_backup(path)
	if parsed.is_empty():
		parsed = read_backup(path + ".bak")
	if not parsed.is_empty():
		settings = parsed.settings
		records = parsed.records


func append(report: Dictionary) -> Error:
	report["id"] = Crypto.new().generate_random_bytes(16).hex_encode()
	report["timestamp"] = int(Time.get_unix_time_from_system())
	records.append(report)
	_trim()
	return save()


func export_to(destination: String) -> Error:
	if destination == path:
		return save()
	return _write(destination, _bundle())


func import_from(source: String) -> Error:
	var loaded := read_backup(source)
	if loaded.is_empty():
		return ERR_FILE_CORRUPT
	var old_settings := settings
	var old_records := records
	settings = loaded.settings
	records = records.duplicate()
	var existing := {}
	for report: Dictionary in records:
		existing[report.id] = true
	for report: Dictionary in loaded.records:
		if not existing.has(report.id):
			records.append(report)
			existing[report.id] = true
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.timestamp < b.timestamp)
	_trim()
	var result := save()
	if result != OK:
		settings = old_settings
		records = old_records
	return result


func save() -> Error:
	return _write(path, _bundle())


func _bundle() -> Dictionary:
	return {"version": 1, "settings": settings, "records": records}


func _trim() -> void:
	if records.size() > MAX_HISTORY:
		records = records.slice(records.size() - MAX_HISTORY)


static func read_backup(source: String) -> Dictionary:
	var opened := FileAccess.open(source, FileAccess.READ)
	if not opened or opened.get_length() > MAX_FILE:
		return {}
	var parsed: Variant = JSON.parse_string(opened.get_as_text())
	if not parsed is Dictionary or parsed.get("version") != 1:
		return {}
	var config: Variant = parsed.get("settings")
	var history: Variant = parsed.get("records")
	if not config is Dictionary or not history is Array or history.size() > MAX_HISTORY:
		return {}
	var validated: Array = []
	var ids := {}
	for item: Variant in history:
		var report := _validated_report(item)
		if report.is_empty() or ids.has(report.id):
			return {}
		ids[report.id] = true
		validated.append(report)
	validated.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.timestamp < b.timestamp)
	return {"settings": _validated_settings(config), "records": validated}


static func _validated_settings(config: Dictionary) -> Dictionary:
	var result := DEFAULTS.duplicate()
	for key: String in DEFAULTS:
		var candidate: Variant = config.get(key)
		if DEFAULTS[key] is bool and candidate is bool:
			result[key] = candidate
	if config.get("color") is String and String(config.color).length() == 7 and String(config.color).begins_with("#") and Color.html_is_valid(config.color):
		result.color = config.color
	for name: String in ["sensitivity", "dpi", "fov", "gap", "length", "thickness", "quality", "audio"]:
		var bounds: Array = {
			"sensitivity": [0.01, 10.0], "dpi": [100, 35000], "fov": [75.0, 120.0],
			"gap": [0, 30], "length": [1, 30], "thickness": [1, 8], "quality": [0, 2], "audio": [0.0, 1.0]
		}[name]
		var value: Variant = config.get(name)
		if _finite(value, bounds[0], bounds[1]):
			result[name] = int(value) if DEFAULTS[name] is int else float(value)
	var cap: Variant = config.get("fps_limit")
	if _finite(cap, 0, 1000) and floorf(cap) == cap and int(cap) in LIMITS:
		result.fps_limit = int(cap)
	return result


static func _validated_report(item: Variant) -> Dictionary:
	var result := _validated_metrics(item)
	if result.is_empty():
		return {}
	var unique: Variant = item.get("id")
	var time: Variant = item.get("timestamp")
	var stages: Variant = item.get("stages")
	if not unique is String or unique.length() != 32 or not unique.is_valid_hex_number(false) or not _finite(time, 0, 4102444800):
		return {}
	if not stages is Array or stages.is_empty() or stages.size() > 20 or not _finite(item.get("level"), 1, 7):
		return {}
	var subs: Array = []
	var summed := TrainingMetrics.new()
	var seconds := 0.0
	for detail: Variant in stages:
		var stage := _validated_metrics(detail)
		if stage.is_empty() or (stage.mode not in Drills.ADAPTIVE_MODES and not BenchmarkCatalog.ITEMS.has(stage.mode)):
			return {}
		subs.append(stage)
		seconds += stage.seconds
		for counter: String in TrainingMetrics.COUNTERS:
			summed.add(counter, stage[counter])
		for index in TrainingMetrics.CELLS:
			summed.heat[index] += stage.heat[index]
	if not is_equal_approx(seconds, result.seconds) or Array(summed.heat) != result.heat:
		return {}
	for counter: String in TrainingMetrics.COUNTERS:
		if not is_equal_approx(summed.values[counter], result[counter]):
			return {}
	result["id"] = unique
	result["timestamp"] = int(time)
	result["stages"] = subs
	result["level"] = int(item.level)
	return result


static func _validated_metrics(data: Variant) -> Dictionary:
	if not data is Dictionary or (data.get("mode") not in Drills.TITLES and not BenchmarkCatalog.ITEMS.has(data.get("mode"))) or not _finite(data.get("seconds"), 0.01, 1000.0 if BenchmarkCatalog.ITEMS.has(data.get("mode")) else 600.0):
		return {}
	var result := {"mode": data.mode, "seconds": float(data.seconds)}
	for name: String in TrainingMetrics.COUNTERS:
		var value: Variant = data.get(name, 0 if name == "eliminations" else null)
		if not _finite(value, 0.0, 10000000000.0):
			return {}
		result[name] = float(value)
	if result.heads > result.hits or result.hits > result.shots or result.reaction_n > result.hits or result.track_on > result.track_ticks + 0.0001 or result.unsettled > result.stop_shots or result.stop_shots > result.shots or result.preaim_n > result.opportunities:
		return {}
	var cells: Variant = data.get("heat")
	if not cells is Array or cells.size() != TrainingMetrics.CELLS:
		return {}
	var normalized: Array = []
	var sample_count := 0
	for value: Variant in cells:
		if not _finite(value, 0, 1000000) or floorf(value) != value:
			return {}
		normalized.append(int(value))
		sample_count += int(value)
	if sample_count > result.shots:
		return {}
	result["heat"] = normalized
	return result


static func _finite(value: Variant, lower: float, upper: float) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and value >= lower and value <= upper


static func _write(destination: String, bundle: Dictionary) -> Error:
	var suffix := Crypto.new().generate_random_bytes(8).hex_encode()
	var temp := destination + "." + suffix + ".tmp"
	var backup := destination + ".bak"
	var opened := FileAccess.open(temp, FileAccess.WRITE)
	if not opened:
		return FileAccess.get_open_error()
	opened.store_string(JSON.stringify(bundle))
	opened.flush()
	var written := opened.get_error()
	opened.close()
	if written != OK:
		DirAccess.remove_absolute(temp)
		return written
	if FileAccess.file_exists(destination) and not read_backup(destination).is_empty():
		var backup_temp := backup + "." + suffix + ".tmp"
		if DirAccess.copy_absolute(destination, backup_temp) == OK:
			var backed_up := DirAccess.rename_absolute(backup_temp, backup)
			if backed_up != OK:
				DirAccess.remove_absolute(backup_temp)
	var replaced := DirAccess.rename_absolute(temp, destination)
	if replaced != OK:
		DirAccess.remove_absolute(temp)
	return replaced


func adaptive_choices() -> Dictionary:
	var evidence := {}
	for report: Dictionary in records.slice(-24):
		for stage: Dictionary in report.stages:
			if stage.mode not in Drills.ADAPTIVE_MODES:
				continue
			var activity: float = stage.shots + stage.preaim_n + stage.opportunities * 0.3
			if activity < 3.0:
				continue
			if not evidence.has(stage.mode):
				evidence[stage.mode] = Vector2.ZERO
			var priority := TrainingMetrics.drill_priority(stage)
			evidence[stage.mode] += Vector2(priority, 1.0)
	var order := Drills.ADAPTIVE_MODES.duplicate()
	order.sort_custom(func(a: String, b: String) -> bool:
		var first: Vector2 = evidence.get(a, Vector2(0.55, 1.0))
		var second: Vector2 = evidence.get(b, Vector2(0.55, 1.0))
		return first.x / first.y > second.x / second.y
	)
	var level := 3
	if not evidence.is_empty():
		var sum := Vector2.ZERO
		for measurement: Vector2 in evidence.values():
			sum += measurement
		level = clampi(roundi(5.0 - 4.0 * sum.x / sum.y), 1, 7)
	return {"order": order, "level": level, "evidence": evidence}
