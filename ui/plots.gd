class_name RangePlot
extends Control

var values: Array = []
var heat := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if heat:
		_draw_heat()
	else:
		_draw_trend()


func _draw_heat() -> void:
	var start := Vector2(27, 8)
	var area := Vector2(size.x - 43.0, size.y - 36.0)
	var cell := area / Vector2(TrainingMetrics.WIDTH, TrainingMetrics.HEIGHT)
	var maximum := 0
	var samples := 0
	for value: int in values:
		maximum = maxi(maximum, value)
		samples += value
	for row in TrainingMetrics.HEIGHT:
		for column in TrainingMetrics.WIDTH:
			var count: int = values[row * TrainingMetrics.WIDTH + column] if not values.is_empty() else 0
			var strength := sqrt(TrainingMetrics.ratio(count, maximum))
			var color := Color("#1b202d").lerp(RangeStyle.RED, strength)
			draw_rect(Rect2(start + Vector2(column, row) * cell, cell - Vector2(2, 2)), color)
	var center := start + area * 0.5 - Vector2.ONE
	draw_line(center - Vector2(7, 0), center + Vector2(7, 0), RangeStyle.PAPER, 1)
	draw_line(center - Vector2(0, 7), center + Vector2(0, 7), RangeStyle.PAPER, 1)
	draw_string(RangeStyle.FONT, Vector2(start.x, size.y - 6), "左 12°", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, RangeStyle.MUTED)
	draw_string(RangeStyle.FONT, Vector2(size.x - 60, size.y - 6), "右 12°", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, RangeStyle.MUTED)
	draw_string(RangeStyle.FONT, Vector2(size.x * 0.42, size.y - 6), "%d 次采样" % samples, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, RangeStyle.MUTED)


func _draw_trend() -> void:
	var start := Vector2(40, 15)
	var area := Vector2(size.x - 55, size.y - 48)
	for index in 5:
		var y := start.y + area.y * index / 4.0
		draw_line(Vector2(start.x, y), Vector2(start.x + area.x, y), RangeStyle.BORDER)
		draw_string(RangeStyle.FONT, Vector2(2, y + 4.0), "%d%%" % (100 - 25 * index), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, RangeStyle.MUTED)
	if values.is_empty():
		draw_string(RangeStyle.FONT, Vector2(size.x * 0.24, size.y * 0.49), "完成有射击记录的训练后显示", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, RangeStyle.MUTED)
		return
	var line := PackedVector2Array()
	for index in values.size():
		var x := 0.5 if values.size() == 1 else float(index) / float(values.size() - 1)
		line.append(start + area * Vector2(x, 1.0 - values[index]))
	if line.size() > 1:
		draw_polyline(line, RangeStyle.RED, 2.0, true)
	for point: Vector2 in line:
		draw_circle(point, 3.8, RangeStyle.RED)
	draw_string(RangeStyle.FONT, Vector2(start.x, size.y - 7), "%d 次同项目记录 · 从早到晚" % values.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, RangeStyle.MUTED)
