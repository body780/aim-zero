class_name Drills
extends RefCounted

const MODES := ["grid", "micro", "head", "track", "stop", "peek", "reaction", "adaptive"]
const WARMUP := ["grid", "head", "stop", "peek"]
const WARMUP_SECONDS := [120, 120, 180, 180]
const ADAPTIVE_BLOCK := 15.0
const ADAPTIVE_MODES := ["micro", "head", "track", "stop", "peek", "reaction", "grid"]
const TITLES := {
	"grid": "六球速射", "micro": "微调定位", "head": "人形目标爆头", "track": "动态跟枪",
	"stop": "急停射击", "peek": "实战预瞄", "reaction": "极限反应", "adaptive": "自适应训练",
	"warmup": "排位前热身"
}
const DETAILS := {
	"grid": "同时出现六个靶球，练习大幅甩枪与连续定位。",
	"micro": "在准星附近寻找小靶，练习短距离修正。",
	"head": "命中机器人的头部才会刷新目标。",
	"track": "按住左键，持续跟随变速移动的目标。",
	"stop": "横移到触发位置，松开方向键，停稳后开枪。",
	"peek": "利用掩体移动到侧翼，提前对准头部高度。",
	"reaction": "等待随机亮靶，发现目标后尽快射击。",
	"adaptive": "根据历史表现和本轮成绩安排练习并调整难度。",
	"warmup": "快速定位 2 分钟 · 爆头 2 分钟 · 急停 3 分钟 · 预瞄 3 分钟"
}
const FOV_HORIZONTAL := 103.0
const YAW_PER_COUNT := 0.07
const MOVE_SPEED := 5.4
const STOP_SPEED := 0.32
const SETTLE_SECONDS := 0.085
const EYE_HEIGHT := 1.64
const STEP := 1.0 / 240.0


static func title(mode: String) -> String:
	return TITLES.get(mode, mode)


static func vertical_fov(horizontal: float) -> float:
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(horizontal) * 0.5) * 9.0 / 16.0))


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
