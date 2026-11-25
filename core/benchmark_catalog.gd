class_name BenchmarkCatalog
extends RefCounted

const ITEMS := {
	"1w6ts reload v2": {"label": "小目标静态定位", "pattern": "wall", "count": 6, "radius": 0.089, "mag": 3, "score": "kills", "multiplier": 1},
	"1w2ts reload smallflicks": {"label": "极小目标精细微调", "pattern": "pair", "count": 2, "radius": 0.048, "mag": 3, "score": "kills", "multiplier": 1},
	"Pasu Voltaic Reload Easy": {"label": "动态目标点击", "pattern": "pasu", "count": 5, "radius": 0.112, "mag": 3, "score": "kills", "multiplier": 1},
	"Air Voltaic Invincible 4 Easier": {"label": "小目标反应跟枪", "pattern": "reactive", "count": 1, "radius": 0.095, "mag": 0, "score": "damage", "multiplier": 100},
	"Smoothsphere Viscose": {"label": "小目标平滑跟枪", "pattern": "smooth", "count": 1, "radius": 0.078, "mag": 0, "score": "damage", "multiplier": 300},
}

# Scoring metadata keeps reports from the previous public build readable.
const PRIOR := {
	"Smoothsphere Viscose Easier": {"score": "damage", "multiplier": 300.05},
	"Ground Plaza Sparky v3 Easy": {"score": "remaining", "multiplier": 18.57},
	"ww5t Voltaic Slightly Larger": {"score": "kills", "multiplier": 1},
	"voxTargetSwitch 2 Large": {"score": "kills", "multiplier": 1},
	"1w6ts reload v2 20% bigger": {"score": "kills", "multiplier": 1},
	"1w2ts reload smallflicks larger": {"score": "kills", "multiplier": 1},
	"Pasu Voltaic Reload Easier": {"score": "kills", "multiplier": 1},
	"VT Bounceshot Viscose Easier": {"score": "kills", "multiplier": 10},
	"VT Floating Heads Viscose Easier": {"score": "sqrt", "multiplier": 10},
	"Smoothsphere Viscose": {"score": "damage", "multiplier": 300.05},
	"Ground Plaza Sparky V3": {"score": "remaining", "multiplier": 19.02},
	"ww4t Voltaic": {"score": "kills", "multiplier": 1},
	"voxTargetSwitch 2": {"score": "kills", "multiplier": 1},
	"1w6ts reload v2": {"score": "kills", "multiplier": 1},
	"1w2ts reload smallflicks slightly larger": {"score": "kills", "multiplier": 1},
	"Pasu Voltaic Reload Easy": {"score": "kills", "multiplier": 1},
	"VT Bounceshot Viscose Medium": {"score": "kills", "multiplier": 10},
	"VT Floating Heads Viscose Medium": {"score": "sqrt", "multiplier": 10},
	"Smoothsphere Viscose Hard": {"score": "damage", "multiplier": 300.05},
	"Ground Plaza Sparky V3 Viscose Hard": {"score": "remaining", "multiplier": 20.1},
	"ww3t Voltaic": {"score": "kills", "multiplier": 1},
	"voxTargetSwitch 2 10% Smaller": {"score": "kills", "multiplier": 1},
	"1w5ts reload": {"score": "kills", "multiplier": 1},
	"1w2ts reload smallflicks": {"score": "kills", "multiplier": 1},
	"Pasu Voltaic Reload": {"score": "kills", "multiplier": 1},
	"VT Bounceshot Viscose Hard": {"score": "kills", "multiplier": 10},
	"VT Floating Heads Viscose Hard": {"score": "sqrt", "multiplier": 10},
	"Smoothsphere Viscose Expert": {"score": "damage", "multiplier": 300.05},
	"Ground Plaza Sparky V3 Thin": {"score": "remaining", "multiplier": 21.32},
	"ww3t Voltaic 10% Smaller": {"score": "kills", "multiplier": 1},
	"voxTargetSwitch 2 20% Smaller": {"score": "kills", "multiplier": 1},
	"1w4ts Voltaic": {"score": "kills", "multiplier": 1},
	"1w2ts reload smallflicks 25% smaller": {"score": "kills", "multiplier": 1},
	"Pasu Voltaic Reload 15% Smaller": {"score": "kills", "multiplier": 1},
	"VT Bounceshot Viscose Expert": {"score": "kills", "multiplier": 10},
	"VT Floating Heads Viscose Expert": {"score": "sqrt", "multiplier": 10},
}

static func known(mode: Variant) -> bool:
	return ITEMS.has(mode) or PRIOR.has(mode)
