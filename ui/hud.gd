class_name RangeHUD
extends Control

var preview_only := false
var profile: Dictionary
var current_time := "00:00"
var stage := ""
var stage_progress := ""
var shots := "—"
var hint := ""
var performance := ""
var impact := 0
var impact_until := 0
var ready_until := 0
var countdown := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func update_session(session: RangeSession) -> void:
	var seconds := ceili(maxf(0.0, session.duration - session.elapsed - 0.00001))
	current_time = "%02d:%02d" % [seconds / 60, seconds % 60]
	stage = Drills.title(session.stage_mode)
	if session.mode == "warmup" and session.stage_index == 0:
		stage = "快速定位"
	stage_progress = "%d / %d" % [session.stage_index + 1, session.plan.size()] if session.plan.size() > 1 else ""
	if session.mode == "adaptive":
		stage_progress += "    难度 %d" % session.level
	var hits: float = session.total.values.hits + session.metrics.values.hits
	var attempts: float = session.total.values.shots + session.metrics.values.shots
	shots = "%d / %d" % [int(hits), int(attempts)]
	match session.stage_mode:
		"stop":
			if not session.targets[0].active:
				hint = "左右横移，触发目标"
			elif session.settled_for + 0.000001 < Drills.SETTLE_SECONDS:
				hint = "移动误差 · 松开方向键"
			else:
				hint = "已停稳 · 开火"
		"peek":
			hint = "沿着掩体移动，保持头部高度"
		"reaction":
			hint = "亮靶后射击" if session.targets[0].active else "等待目标出现"
		"track":
			hint = "按住左键，跟随移动目标"
		_:
			hint = ""
	if session is BenchmarkSession:
		if session.spec.mag > 0:
			hint = "装填中" if session.reloading else "弹匣  %d / %d" % [session.magazine,session.spec.mag]
	queue_redraw()


func set_impact(outcome: int, now: int) -> void:
	if outcome < 2:
		return
	impact = outcome
	impact_until = now + 110000
	queue_redraw()


func tick(now: int) -> void:
	var next_count := maxi(0, ceili((ready_until - now) / 1000000.0))
	if next_count != countdown:
		countdown = next_count
		queue_redraw()
	if impact != 0 and now >= impact_until:
		impact = 0
		queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	_crosshair(center)
	if preview_only:
		return
	var heading := stage
	if not stage_progress.is_empty():
		heading += "    " + stage_progress
	_panel(Rect2(28, 25, maxf(318,RangeStyle.FONT.get_string_size(heading,HORIZONTAL_ALIGNMENT_LEFT,-1,19).x + 36), 81))
	_write(heading, Vector2(45, 55), 19, RangeStyle.PAPER)
	_write("退出键  暂停", Vector2(45, 82), 13, RangeStyle.MUTED)
	_panel(Rect2(center.x - 77, 25, 154, 66))
	_write(current_time, Vector2(center.x - 39, 70), 32, RangeStyle.PAPER)
	_panel(Rect2(size.x - 199, 25, 171, 81))
	_write("命中 / 发射", Vector2(size.x - 181, 53), 14, RangeStyle.MUTED)
	_write(shots, Vector2(size.x - 181, 83), 23, RangeStyle.PAPER)
	if not performance.is_empty():
		_panel(Rect2(28, size.y - 66, 595, 39))
		_write(performance, Vector2(43, size.y - 41), 14, RangeStyle.MUTED)
	if not hint.is_empty():
		_center_write(hint, Vector2(center.x, size.y * 0.76), 19, RangeStyle.GREEN if hint.begins_with("已") else RangeStyle.PAPER)
	if impact > 0:
		var tint := RangeStyle.RED if impact == 3 else RangeStyle.PAPER
		for axis in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
			draw_line(center + axis * 11.0, center + axis * 17.0, tint, 2.0)
		if impact == 3:
			_center_write("爆头", center + Vector2(0, -42), 18, tint)
	if countdown > 0:
		_center_write(str(countdown), center + Vector2(0, -77), 66, RangeStyle.RED)
		_center_write("准备开始", center + Vector2(0, -43), 17, RangeStyle.PAPER)


func _crosshair(center: Vector2) -> void:
	var tint := Color.html(profile.color)
	var gap: float = profile.gap
	var length: float = profile.length
	var thickness: float = profile.thickness
	for axis in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		if profile.outline:
			draw_line(center + axis * maxf(0.0, gap - 1.0), center + axis * (gap + length + 1.0), Color("#090c15"), thickness + 2)
		draw_line(center + axis * gap, center + axis * (gap + length), tint, thickness)
	if profile.dot:
		if profile.outline:
			draw_circle(center, thickness + 0.8, Color("#090c15"))
		draw_circle(center, thickness * 0.6, tint)


func _panel(bounds: Rect2) -> void:
	draw_rect(bounds, Color("#0d111bd9"))
	draw_rect(bounds, Color("#30384ae8"), false, 1.0)


func _write(value: String, baseline: Vector2, pixels: int, tint: Color) -> void:
	draw_string(RangeStyle.FONT, baseline, value, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels, tint)


func _center_write(value: String, baseline: Vector2, pixels: int, tint: Color) -> void:
	var extent := RangeStyle.FONT.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels)
	_write(value, baseline - Vector2(extent.x * 0.5, 0), pixels, tint)
