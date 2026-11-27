extends SceneTree

var failures := 0
var checks := 0

func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		push_error(label)
		failures += 1

func _initialize() -> void:
	expect(absf(Drills.cm_per_turn(800, 0.35) - 46.65306) < 0.0001,"cm/360 校准")
	var session := RangeSession.new()
	session.begin("reactive", 120, 3, [], 42)
	var t := session.targets[0]
	t.previous = Vector3(t.radius - .004, Drills.EYE_HEIGHT, -7.8)
	t.position = t.previous + Vector3(.012,0,0)
	session.present(.25, Vector2.ZERO, 70.53, 1.7778)
	expect(session.shoot(session.shown_look) == 2, "显示边缘与射线共享快照")
	var e := Vector3.UP * Drills.EYE_HEIGHT
	var bins := PackedInt32Array([0,0,0,0])
	var depths := PackedInt32Array([0,0,0])
	var separated := true
	for seed_value in range(1,1001):
		var grid := RangeSession.new()
		grid.begin("grid",30,3,[],seed_value)
		for i in grid.targets.size():
			var delta := grid.targets[i].position - e
			var yaw := rad_to_deg(atan2(-delta.x,-delta.z))
			bins[clampi(floori((yaw+30)/15),0,3)] += 1
			depths[clampi(floori((delta.length()-7.8)/3.2*3),0,2)] += 1
			for j in i:
				if delta.angle_to(grid.targets[j].position-e) < deg_to_rad(6.99):
					separated = false
	expect(separated,"六靶最小间距")
	for n in bins:
		expect(n > 500 and n < 2500,"方位箱覆盖")
	for n in depths:
		expect(n > 1700 and n < 2300,"深度分层覆盖")
	for mode in ["track","reactive"]:
		var trace := replay(mode,60)
		for fps in [144,240,500,1000]:
			expect(trace == replay(mode,fps), "输入回放与运动重现 " + mode)
	var stop := RangeSession.new()
	stop.begin("stop",30,3,[],42)
	for tick in 100:
		stop.step(Vector2.RIGHT,Vector2.ZERO)
	for tick in 20:
		stop.step(Vector2.LEFT,Vector2.ZERO)
	expect(stop.last_stop_kind == "reverse" and stop.velocity.length() < Drills.STOP_SPEED,"反向制动立即恢复")
	var dir := OS.get_temp_dir().path_join("az-test-"+str(Time.get_ticks_usec()))
	DirAccess.make_dir_recursive_absolute(dir)
	var personal := dir.path_join("old.json")
	var old := LocalProfile.new(personal)
	old.settings.sensitivity = 0.854
	expect(old.save() == OK,"旧档准备")
	var flag := FileAccess.open(dir.path_join("portable.flag"),FileAccess.WRITE)
	flag.close()
	var portable := LocalProfile.open_for_app(dir,false,personal)
	expect(portable.path == dir.path_join("aim-zero.json") and portable.settings.sensitivity == 0.854,"便携迁移")
	portable.settings.sensitivity = 1.25
	portable.save()
	expect(LocalProfile.open_for_app(dir,false,personal).settings.sensitivity == 1.25,"便携重启")
	for name in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(name))
	DirAccess.remove_absolute(dir)
	print("BETA_TESTS ",checks-failures,"/",checks, " bins=",bins," depths=",depths)
	quit(int(failures > 0))

func replay(mode: String, fps: int) -> Array:
	var s := RangeSession.new()
	s.begin(mode,120,3,[],3001)
	var render := 0
	var digest := 17
	for tick in 28800:
		var look := Vector2(sin(tick * .002) * .2,0)
		s.step(Vector2.ZERO,look)
		render += fps
		while render >= 240:
			render -= 240
			s.present(1.0,look,70.53,1.7778)
		if tick % 79 == 0:
			digest = hash([digest,s.targets[0].position])
	return [digest,s.finished,s.elapsed]
