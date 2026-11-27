extends SceneTree

func _initialize() -> void:
	var frames := FrameMetrics.new()
	var loaded: RangeSession
	var sessions := 12
	var rendered := 0
	for series in sessions:
		loaded = RangeSession.new()
		loaded.begin("warmup",600,3,[],series + 1)
		for tick in 144000:
			loaded.step(Vector2.RIGHT if tick % 180 < 80 else Vector2.LEFT,Vector2.ZERO)
			if tick % 2 == 0:
				loaded.present(.5,Vector2.ZERO,70.53,1.7778)
				rendered += 1
				frames.sample(rendered * 8333)
			if tick % 31 == 0:
				loaded.shoot(loaded.shown_look)
		if not loaded.finished or loaded.stages.size() != 5 or loaded.targets.size() != 6:
			quit(1)
			return
	print("SOAK_OK seconds=", sessions*600, " frames=",rendered," diagnostic_ring=",frames.count)
	quit(0)
