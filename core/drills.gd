class_name Drills
extends RefCounted

const MODES := ["grid", "micro", "head", "track", "stop"]
const WARMUP := ["grid", "micro", "head", "track", "stop"]
const WARMUP_SECONDS := [90, 90, 120, 120, 180]
const ADAPTIVE_BLOCK := 15.0
const ADAPTIVE_MODES := ["micro", "head", "track", "stop", "peek", "reaction", "grid"]
const TITLES := {
	"grid": "大角度定位", "micro": "精细微调", "head": "人形头线切换", "reactive": "反应跟枪", "track": "动态跟枪",
	"stop": "急停预瞄", "peek": "实战预瞄", "reaction": "极限反应", "adaptive": "自适应训练",
	"warmup": "排位前热身"
}
const DETAILS := {
	"grid": "同时出现六个靶球，练习大幅甩枪与连续定位。",
	"micro": "在准星附近寻找小靶，练习短距离修正。",
	"head": "命中机器人的头部才会刷新目标。",
	"reactive": "快速变向，持续跟随。",
	"track": "按住左键，持续跟随变速移动的目标。",
	"stop": "横移到触发位置，松开方向键，停稳后开枪。",
	"peek": "利用掩体移动到侧翼，提前对准头部高度。",
	"reaction": "等待随机亮靶，发现目标后尽快射击。",
	"adaptive": "根据历史表现和本轮成绩安排练习并调整难度。",
	"warmup": "定位 90 秒 · 微调 90 秒 · 头线 120 秒 · 跟枪 120 秒 · 急停 180 秒"
}
const FOV_HORIZONTAL := 103.0
const YAW_PER_COUNT := 0.07
const MOVE_SPEED := 5.4
const STOP_SPEED := MOVE_SPEED * 0.275
const EYE_HEIGHT := 1.64
const STEP := 1.0 / 240.0


static func title(mode: String) -> String:
	return TITLES.get(mode, mode)


static func vertical_fov(horizontal: float) -> float:
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(horizontal) * 0.5) * 9.0 / 16.0))


static func cm_per_turn(dpi: float, sensitivity: float) -> float:
	return 360.0 * 2.54 / (dpi * sensitivity * YAW_PER_COUNT)


static func angular_input(motion: Vector2, sensitivity: float) -> Vector2:
	return motion * deg_to_rad(YAW_PER_COUNT * sensitivity)


static func schedule(mode: String, seconds: int, adaptive_order: Array) -> Array:
	var result: Array = []
	if mode == "warmup":
		for index in WARMUP.size():
			result.append({"mode": WARMUP[index], "seconds": float(WARMUP_SECONDS[index])})
	elif mode == "adaptive":
		var remaining := float(seconds)
		var index := 0
		while remaining > 0.0:
			var duration := minf(remaining, ADAPTIVE_BLOCK)
			result.append({"mode": adaptive_order[index % adaptive_order.size()], "seconds": duration})
			index += 1
			remaining -= duration
	else:
		result.append({"mode": mode, "seconds": float(seconds)})
	return result
