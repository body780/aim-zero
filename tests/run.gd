extends SceneTree

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	run.call_deferred()


func expect(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)
		push_error(description)


func start(mode: String, seconds: int = 30, level: int = 3) -> RangeSession:
	var session := RangeSession.new()
	session.begin(mode, seconds, level, Drills.ADAPTIVE_MODES, 727)
	return session


func aim(session: RangeSession, point: Vector3) -> Vector2:
	return RangeGeometry.angles(session.player + Vector3.UP * Drills.EYE_HEIGHT, point)


func wait_ticks(session: RangeSession, steps: int, move := Vector2.ZERO) -> void:
	for tick in steps:
		session.step(move, Vector2.ZERO)


func show(session: RangeSession, look := Vector2.ZERO) -> void:
	session.present(1.0, look, Drills.vertical_fov(103.0), 16.0 / 9.0)


func run() -> void:
	expect(absf(rad_to_deg(Drills.angular_input(Vector2(1000, 0), 1.0).x) - 70.0) < 0.0001, "鼠标灵敏度角度")
	var fov := Drills.vertical_fov(103.0)
	expect(absf(rad_to_deg(2.0 * atan(tan(deg_to_rad(fov) * 0.5) * 16.0 / 9.0)) - 103.0) < 0.0001, "水平与垂直视野换算")
	expect(LocalProfile.LIMITS == [60, 120, 144, 165, 180, 240, 360, 480, 500, 600, 1000, 0], "完整帧率限额")
	var grid := start("grid")
	show(grid)
	expect(grid.targets.filter(func(target): return target.active).size() == 6, "六靶同场")
	var point := grid.targets[5].position
	expect(grid.shoot(aim(grid, point)) == 2 and grid.targets[5].position != point, "六球命中并补靶")
	expect(grid.shoot(Vector2.ZERO) == 0, "射击冷却")
	wait_ticks(grid, 35)
	expect(grid.shoot(Vector2(PI * 0.95, 0)) == 1 and grid.metrics.values.shots == 2, "未命中与冷却计数")
	expect(Array(grid.metrics.heat).reduce(func(sum, value): return sum + value, 0) == 2, "热力图累计真实射击")

	var micro := start("micro")
	expect(micro.targets[0].radius < grid.targets[0].radius and absf(micro.targets[0].position.x) < 1.0, "微调小靶与邻近位置")
	show(micro)
	wait_ticks(micro, 48)
	expect(micro.shoot(aim(micro, micro.targets[0].position)) == 2 and micro.metrics.values.reaction_n == 1 and is_equal_approx(micro.metrics.values.reaction_ms, 200.0), "实际曝光到命中的反应时间")
	var flick := TrainingMetrics.new()
	flick.record_flick(Vector2(0.2, 0.0), Vector2(-0.04, 0.0), 0.02)
	flick.record_flick(Vector2(0.2, 0.0), Vector2(0.04, 0.0), 0.02)
	flick.record_flick(Vector2(0.2, 0.0), Vector2(0.0, 0.04), 0.02)
	expect(flick.values.over == 1 and flick.values.under == 1 and flick.values.on == 1, "过度和不足沿拉枪方向计算")
	flick.record_error(Vector2(deg_to_rad(-30.0), deg_to_rad(30.0)))
	expect(flick.heat[TrainingMetrics.WIDTH - 1] == 1, "偏差越界落在热力图边缘")

	var head := start("head")
	show(head)
	var robot := head.targets[0].position
	expect(head.shoot(aim(head, robot + Vector3(0, 1.15, 0))) == 2 and head.targets[0].position == robot, "仅击中躯干不刷新")
	wait_ticks(head, 35)
	expect(head.shoot(aim(head, robot + RangeGeometry.HEAD)) == 3 and head.targets[0].position != robot and head.metrics.values.heads == 1, "头部击中和刷新")

	var stop := start("stop")
	expect(not stop.targets[0].active, "急停初始等待横移")
	wait_ticks(stop, 84, Vector2.RIGHT)
	expect(stop.targets[0].active and stop.settled_for == 0.0, "移动触发急停靶并清空稳定时间")
	show(stop)
	stop.shoot(aim(stop, stop.targets[0].position))
	expect(stop.metrics.values.unsettled == 1, "移动开枪记入误差样本")
	wait_ticks(stop, 72)
	expect(stop.settled_for == Drills.SETTLE_SECONDS and stop.velocity.is_zero_approx(), "松键后恢复精度")

	var peek := start("peek")
	peek.targets[0].position = Vector3(0, 0, -9.2)
	peek.targets[0].previous = peek.targets[0].position
	show(peek)
	expect(peek.shoot(aim(peek, peek.targets[0].point(false))) == 1 and peek.metrics.values.preaim_n == 0, "掩体阻挡射线和反应采样")
	var blocked := RangeGeometry.move_player(Vector3.ZERO, Vector3(0, 0, -15), true)
	expect(blocked.z >= -5.58 + RangeGeometry.PLAYER_RADIUS, "移动扫掠阻止穿越掩体")
	peek.player = Vector3(4.8, 0, -6.45)
	peek.previous_player = peek.player
	wait_ticks(peek, 30)
	show(peek, aim(peek, peek.targets[0].point(false)))
	expect(peek.metrics.values.preaim_n == 1 and peek.shoot(aim(peek, peek.targets[0].point(false))) == 3, "绕过掩体后采集预瞄并判定头部命中")

	var reaction := start("reaction")
	expect(not reaction.targets[0].active and reaction.pending_at >= 0.7, "反应项目随机延迟")
	expect(reaction.shoot(Vector2.ZERO) == 1, "空窗抢射记为未命中")
	wait_ticks(reaction, ceili(reaction.pending_at / Drills.STEP) + 1)
	show(reaction)
	wait_ticks(reaction, 60)
	expect(reaction.targets[0].active, "亮靶有效时窗")
	expect(reaction.shoot(aim(reaction, reaction.targets[0].position)) == 2 and absf(reaction.metrics.values.reaction_ms - 250.0) < 0.01, "定时亮靶与实测反应")
	wait_ticks(reaction, 1000)
	expect(reaction.metrics.values.expired >= 1, "遗漏目标计数")

	var warmup := start("warmup", 600)
	var sequence: Array = []
	for tick in 144000:
		if warmup.step(Vector2.ZERO, Vector2.ZERO):
			sequence.append(warmup.stages.back().mode)
	var warm_report := warmup.report()
	expect(warmup.finished and warmup.elapsed == 600.0 and sequence == Drills.WARMUP, "热身 600 秒自动切换并完成")
	expect(warm_report.stages.map(func(stage): return int(stage.seconds)) == Drills.WARMUP_SECONDS, "热身分项时长")
	expect(warm_report.shots == 0 and warm_report.hits == 0, "未开枪报告维持零值")

	var adaptive := start("adaptive", 30, 3)
	for sample in 4:
		show(adaptive)
		adaptive.shoot(aim(adaptive, adaptive.targets[0].position))
		wait_ticks(adaptive, 30)
	wait_ticks(adaptive, 15 * 240 - 120)
	expect(adaptive.stage_mode == "head" and adaptive.level == 4, "自适应根据实际命中提高难度")
	var weak := start("adaptive", 30, 3)
	for sample in 4:
		weak.shoot(Vector2(PI, 0))
		wait_ticks(weak, 30)
	wait_ticks(weak, 15 * 240 - 120)
	expect(weak.level == 2, "自适应根据实际未命中降难度")

	var reference := _paced(60)
	for fps in [120, 144, 240, 500, 1000]:
		expect(reference == _paced(fps), "固定训练状态在 %d 帧/秒渲染采样下相同" % fps)
	_test_performance()
	_test_data(head)
	print("AIM_ZERO_TESTS %d PASS / %d" % [checks - failures.size(), checks])
	quit(int(not failures.is_empty()))


func _paced(fps: int) -> Array:
	var tracking := start("track")
	var moving := start("stop")
	var draw_accumulator := 0
	for tick in 1800:
		var look := aim(tracking, tracking.targets[0].position)
		tracking.step(Vector2.ZERO, look)
		moving.step(Vector2.RIGHT if tick < 180 else Vector2.ZERO, Vector2.ZERO)
		draw_accumulator += fps
		while draw_accumulator >= 240:
			draw_accumulator -= 240
			tracking.present(0.5, look, Drills.vertical_fov(103.0), 16.0 / 9.0)
			moving.present(0.5, Vector2.ZERO, Drills.vertical_fov(103.0), 16.0 / 9.0)
		if tick % 24 == 0:
			tracking.shoot(aim(tracking, tracking.targets[0].position))
	return [tracking.targets[0].position, tracking.elapsed, tracking.metrics.values.hits, tracking.metrics.values.track_on, moving.player, moving.settled_for]


func _test_performance() -> void:
	var frames := FrameMetrics.new()
	var now := 1
	frames.sample(now)
	for index in 2000:
		now += 4000 if index % 100 == 0 else 2000
		frames.sample(now)
	expect(frames.count >= 1950 and frames.average > 490.0 and frames.average < 500.0, "性能环形缓冲和真实时间倒数")
	expect(absf(frames.low - 250.0) < 0.01, "最慢百分之一计算")
	expect(frames.sample(now + 5000000) and frames.count == 0, "长时间中断重置采样")


func _test_data(session: RangeSession) -> void:
	var base := "user://测试-%d" % Time.get_ticks_usec()
	var local := LocalProfile.new(base + ".json")
	var other := LocalProfile.new(base + "-导入.json")
	var exported := base + "-备份.json"
	wait_ticks(session, 30)
	session.shoot(Vector2(PI, 0))
	session.stage_elapsed = session.stage_duration - Drills.STEP
	session.step(Vector2.ZERO, Vector2.ZERO)
	local.settings.fps_limit = 1000
	expect(local.append(session.report()) == OK and local.export_to(exported) == OK, "训练保存与导出")
	expect(other.import_from(exported) == OK and other.import_from(exported) == OK, "重复导入可用")
	expect(other.settings.fps_limit == 1000 and other.records.size() == 1 and other.records[0].heads == 1.0, "导入恢复设置和去重记录")
	expect(other.adaptive_choices().evidence.has("head"), "自适应可读取本地历史样本")
	var malformed := FileAccess.open(exported, FileAccess.WRITE)
	malformed.store_string('{"version":1,"settings":{},"records":[{"shots":9}]}')
	malformed.close()
	expect(other.import_from(exported) == ERR_FILE_CORRUPT and other.records.size() == 1, "损坏数据被拒绝且历史完整")
	for path: String in [local.path, other.path, exported]:
		for extension: String in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(path + extension):
				DirAccess.remove_absolute(path + extension)
