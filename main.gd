extends Node

const COUNT_IN := 2500000

var profile: LocalProfile
var arena: TrainingArena
var audio: RangeAudio
var screens: RangeScreens
var hud: RangeHUD
var session: RangeSession
var performance := FrameMetrics.new()
var look := Vector2.ZERO
var yaw_remainder := 0.0
var pitch_remainder := 0.0
var sensitivity_radians := deg_to_rad(0.07 * 0.35)
var vertical_fov := 73.74
var raw_motion := true
var monitor_performance := true
var playing := false
var paused := false
var shooting := false
var started := false
var start_before := 0
var paused_at := 0
var next_hud_time := 0
var profile_dirty := false
var smoke_mode := false
var finish_pending := false


func _ready() -> void:
	var user_args := OS.get_cmdline_user_args()
	smoke_mode = "--smoke-test" in user_args
	profile = LocalProfile.new("user://自动测试.json" if smoke_mode else "user://aim-zero.json")
	if not smoke_mode:
		profile.load_local()
	if not OS.has_feature("web"):
		get_window().min_size = Vector2i(900, 562)
	arena = TrainingArena.new()
	add_child(arena)
	audio = RangeAudio.new()
	add_child(audio)
	var overlay := CanvasLayer.new()
	add_child(overlay)
	hud = RangeHUD.new()
	overlay.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screens = RangeScreens.new()
	overlay.add_child(screens)
	screens.setup(self)
	_apply_settings()
	open_menu()
	if smoke_mode:
		_smoke.call_deferred()


func _process(delta: float) -> void:
	if not playing or paused or finish_pending:
		return
	var now := Time.get_ticks_usec()
	var view := get_viewport().get_visible_rect().size
	session.present(Engine.get_physics_interpolation_fraction(), look, vertical_fov, view.aspect(), started)
	arena.render_session(session, look, delta, now)
	if monitor_performance and performance.sample(now):
		hud.performance = "帧率 %.0f   ·   帧时间 %.2f 毫秒   ·   平均 %.0f   ·   最慢 1%% %s" % [
			performance.instant, performance.last_frame, performance.average, "%.0f" % performance.low if performance.low > 0.0 else "—"
		]
		hud.queue_redraw()
	hud.tick(now)
	if now >= next_hud_time:
		next_hud_time = now + 40000
		hud.update_session(session)


func _physics_process(_delta: float) -> void:
	if not playing or paused or finish_pending:
		return
	if not started:
		if Time.get_ticks_usec() < start_before:
			return
		started = true
		hud.ready_until = 0
	var movement := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if session.step(movement, look):
		if session.finished:
			finish_pending = true
			_finish.call_deferred()
			return
		look = Vector2.ZERO
		arena.show_training(session, vertical_fov)
		hud.update_session(session)
		shooting = false
	elif shooting and (session.stage_mode == "track" or (session is BenchmarkSession and session.automatic())):
		_fire()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if playing and not paused and started:
			var movement: Vector2 = event.screen_relative if raw_motion else event.relative
			var yaw := look.x + yaw_remainder - movement.x * sensitivity_radians
			if yaw < -PI or yaw >= PI:
				yaw = wrapf(yaw, -PI, PI)
			var pitch := clampf(look.y + pitch_remainder - movement.y * sensitivity_radians, -1.53, 1.53)
			look = Vector2(yaw, pitch)
			yaw_remainder = yaw - look.x
			pitch_remainder = pitch - look.y
		return
	if event is InputEventMouseButton:
		if playing and not paused and event.button_index == MOUSE_BUTTON_LEFT:
			shooting = event.pressed and started
			if shooting:
				_fire()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if key == KEY_F11:
			change_setting("fullscreen", not profile.settings.fullscreen)
			_save_settings()
			get_viewport().set_input_as_handled()
		elif key == KEY_ESCAPE and playing:
			if paused:
				resume()
			else:
				pause_training()
			get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and playing and not paused:
		pause_training()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_settings()


func start(mode: String, seconds: int) -> void:
	_save_settings()
	var adaptive := profile.adaptive_choices()
	session = BenchmarkSession.new() if BenchmarkCatalog.ITEMS.has(mode) else RangeSession.new()
	session.begin(mode, seconds, adaptive.level if mode == "adaptive" else 3, adaptive.order)
	playing = true
	paused = false
	started = false
	finish_pending = false
	shooting = false
	look = Vector2.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Input.use_accumulated_input = not raw_motion
	arena.show_training(session, vertical_fov)
	screens.hide()
	hud.profile = profile.settings
	hud.impact = 0
	hud.performance = ""
	start_before = Time.get_ticks_usec() + COUNT_IN
	hud.ready_until = start_before
	next_hud_time = 0
	performance = FrameMetrics.new()
	hud.update_session(session)
	hud.show()


func pause_training() -> void:
	paused = true
	shooting = false
	paused_at = Time.get_ticks_usec()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.use_accumulated_input = true
	screens.paused()


func resume() -> void:
	if not playing or not paused:
		return
	if not started:
		start_before += Time.get_ticks_usec() - paused_at
		hud.ready_until = start_before
	paused = false
	shooting = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Input.use_accumulated_input = not raw_motion
	performance = FrameMetrics.new()
	hud.performance = ""
	screens.hide()


func _fire() -> void:
	var outcome := session.shoot(look)
	if outcome == 0:
		return
	var now := Time.get_ticks_usec()
	arena.flash(now)
	audio.fire(outcome, profile.settings.audio)
	hud.set_impact(outcome, now)


func _finish() -> void:
	if not is_instance_valid(hud) or session == null or not session.finished:
		return
	var report := session.report()
	var result := profile.append(report)
	open_report(report)
	if result != OK:
		screens.notify("写入训练记录失败。报告仍可查看。", true)


func _leave_training() -> void:
	playing = false
	paused = false
	started = false
	shooting = false
	finish_pending = false
	session = null
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.use_accumulated_input = true
	hud.hide()
	arena.show_menu()


func open_menu() -> void:
	var saved := _save_settings()
	_leave_training()
	screens.menu(profile)
	if saved != OK:
		screens.notify("写入设置失败，请检查数据目录。", true)


func open_settings() -> void:
	_leave_training()
	screens.settings()


func open_history() -> void:
	_leave_training()
	screens.history()


func open_guide() -> void:
	_leave_training()
	screens.guide()


func open_report(report: Dictionary) -> void:
	_leave_training()
	screens.report(report)


func change_setting(key: String, value: Variant) -> void:
	profile.settings[key] = value
	profile_dirty = true
	match key:
		"fullscreen":
			if not smoke_mode:
				var target := DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED
				DisplayServer.window_set_mode(target)
		"fps_limit":
			Engine.max_fps = profile.settings.fps_limit
		"vsync":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED)
		"quality":
			arena.set_quality(value)
		"raw":
			raw_motion = value
		"sensitivity":
			sensitivity_radians = deg_to_rad(Drills.YAW_PER_COUNT * value)
		"fov":
			vertical_fov = Drills.vertical_fov(value)
		"perf":
			monitor_performance = value


func _apply_settings() -> void:
	for key: String in profile.settings:
		change_setting(key, profile.settings[key])
	profile_dirty = false


func _save_settings() -> Error:
	if not profile_dirty or not is_instance_valid(screens):
		return OK
	var result := profile.save()
	if result == OK:
		profile_dirty = false
	else:
		screens.notify("写入设置失败，请检查数据目录。", true)
	return result


func backup(path: String, importing: bool) -> void:
	if not (path.is_absolute_path() and path.get_extension().to_lower() == "json") or path.begins_with("res://"):
		screens.notify("请输入带有 .json 扩展名的完整文件路径。", true)
		return
	if importing:
		if profile.import_from(path) != OK:
			screens.notify("导入失败。请检查文件是否为有效的零点练枪备份。", true)
			return
		_apply_settings()
		screens.settings("已导入设置并合并训练记录。")
	else:
		if profile.export_to(path) != OK:
			screens.notify("导出失败。请确认目标文件夹存在且可写。", true)
			return
		screens.notify("备份已导出。")


func _smoke() -> void:
	# Runs against the actual exported application and its bundled resources.
	var checks: Array[bool] = []
	checks.append(arena.camera != null and audio.shot.data.size() > 0)
	open_settings()
	checks.append(is_instance_valid(screens.crosshair_preview))
	open_guide()
	open_history()
	open_menu()
	var card := screens.page.find_child("grid", true, false) as Button
	checks.append(card != null)
	if card != null:
		card.pressed.emit()
	else:
		start("grid", 30)
	start_before = 0
	started = true
	await get_tree().process_frame
	await get_tree().process_frame
	var motion_total := 0.0
	for packet in 8000:
		var movement := InputEventMouseMotion.new()
		movement.screen_relative = Vector2(2 if packet % 4 == 0 else -1, 0)
		movement.relative = Vector2(200, 0)
		motion_total += movement.screen_relative.x
		Input.parse_input_event(movement)
	await get_tree().process_frame
	var expected_yaw := wrapf(-motion_total * sensitivity_radians, -PI, PI)
	checks.append(absf(wrapf(look.x - expected_yaw, -PI, PI)) < 0.001)
	look = RangeGeometry.angles(session.visible_eye, session.targets[0].point(false))
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	await get_tree().process_frame
	checks.append(session.metrics.values.hits == 1 and session.metrics.values.shots == 1)
	pause_training()
	var paused_clock := session.elapsed
	await get_tree().physics_frame
	await get_tree().physics_frame
	checks.append(is_equal_approx(session.elapsed, paused_clock))
	resume()
	session.stage_elapsed = session.stage_duration - Drills.STEP
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	checks.append(not playing and not profile.records.is_empty())
	checks.append(not LocalProfile.read_backup(profile.path).is_empty())
	screens.benchmarks(0)
	var library_buttons := screens.page.find_children("*", "Button", true, false)
	var found := false
	for button: Button in library_buttons:
		if button.text == "Smoothsphere Viscose Easier":
			button.pressed.emit()
			found = true
			break
	checks.append(found and session is BenchmarkSession)
	if found:
		session.stage_elapsed = session.stage_duration - Drills.STEP
		session.step(Vector2.ZERO,Vector2.ZERO)
		_finish()
		checks.append(not LocalProfile.read_backup(profile.path).is_empty())
	DirAccess.remove_absolute(profile.path)
	DirAccess.remove_absolute(profile.path + ".bak")
	if false in checks:
		push_error("AIM_ZERO_SMOKE_FAILED " + str(checks))
		get_tree().quit(1)
	else:
		print("AIM_ZERO_SMOKE_OK")
		get_tree().quit(0)
