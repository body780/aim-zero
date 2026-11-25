class_name RangeScreens
extends Control

var app
var page: Control
var status: Label
var edpi: Label
var data_path: LineEdit
var crosshair_preview: RangeHUD
var seconds := 60


func setup(owner_app) -> void:
	app = owner_app
	theme = RangeStyle.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _clear() -> void:
	if is_instance_valid(page):
		remove_child(page)
		page.queue_free()
	page = Control.new()
	page.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(page)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	status = null
	edpi = null
	crosshair_preview = null
	show()


func _fill(node: Control) -> void:
	page.add_child(node)
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _shell(opaque: bool) -> VBoxContainer:
	_clear()
	if opaque:
		var shade := ColorRect.new()
		shade.color = RangeStyle.INK
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fill(shade)
	var margin := MarginContainer.new()
	_fill(margin)
	for edge: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + edge, 70)
	margin.add_theme_constant_override("margin_top", 33)
	margin.add_theme_constant_override("margin_bottom", 29)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	margin.add_child(body)
	return body


func _space(row: BoxContainer) -> void:
	var space := Control.new()
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if row is HBoxContainer:
		space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(space)


func _rule(parent: Control, color: Color = RangeStyle.BORDER) -> void:
	var line := ColorRect.new()
	line.color = color
	line.custom_minimum_size.y = 1
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)


func _button(parent: Control, value: String, callback: Callable, primary: bool = false) -> Button:
	var result := RangeStyle.button(value, callback, primary)
	parent.add_child(result)
	return result


func _brand(parent: HBoxContainer) -> void:
	var logo := TextureRect.new()
	logo.texture = preload("res://assets/icon.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(47, 47)
	parent.add_child(logo)
	var title := RangeStyle.text("AIM ZERO", 24)
	title.add_theme_constant_override("outline_size", 1)
	title.add_theme_color_override("font_outline_color", RangeStyle.PAPER)
	parent.add_child(title)


func _nav(body: VBoxContainer) -> void:
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 15)
	body.add_child(top)
	_brand(top)
	_space(top)
	_button(top, "Viscose S2 场景库", func(): benchmarks())
	_button(top, "训练记录", app.open_history)
	_button(top, "设置", app.open_settings)
	_button(top, "操作指南", app.open_guide)
	_rule(body)


func benchmarks() -> void:
	var body := _shell(true)
	_heading(body, "Viscose S2 精选", "五项专项训练 · 每轮 60 秒")
	var list := _scroller(body)
	for title: String in BenchmarkCatalog.ITEMS:
		var entry := _button(list, "%s    %s" % [BenchmarkCatalog.ITEMS[title].label,title], func(): app.start(title,60))
		entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry.custom_minimum_size.y = 65

func _heading(body: VBoxContainer, title: String, detail: String) -> void:
	var row := HBoxContainer.new()
	body.add_child(row)
	_brand(row)
	_space(row)
	_button(row, "返回主菜单", app.open_menu)
	_rule(body)
	body.add_child(RangeStyle.text(title, 43))
	if not detail.is_empty():
		body.add_child(RangeStyle.text(detail, 17, RangeStyle.MUTED))


func menu(profile: LocalProfile) -> void:
	var body := _shell(false)
	var left := RangeStyle.gradient(Color("#0a0d15fa"), Color("#0c101537"))
	_fill(left)
	page.move_child(left, 0)
	var bottom := RangeStyle.gradient(Color("#0c101500"), Color("#0a0d15"), Vector2.DOWN)
	_fill(bottom)
	page.move_child(bottom, 1)
	_nav(body)

	var hero := VBoxContainer.new()
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero.custom_minimum_size.y = 335
	hero.add_theme_constant_override("separation", 16)
	body.add_child(hero)
	_space(hero)
	hero.add_child(RangeStyle.text("第一人称竞技训练", 17, RangeStyle.RED))
	var wordmark := RangeStyle.text("零点练枪", 78)
	wordmark.add_theme_constant_override("outline_size", 2)
	wordmark.add_theme_color_override("font_outline_color", RangeStyle.PAPER)
	hero.add_child(wordmark)
	hero.add_child(RangeStyle.text("为无畏契约排位准备手感。", 24, RangeStyle.MUTED))
	var primary := HBoxContainer.new()
	primary.add_theme_constant_override("separation", 18)
	hero.add_child(primary)
	var warm := _button(primary, "开始 10 分钟热身   ›", func(): app.start("warmup", 600), true)
	warm.custom_minimum_size = Vector2(240, 55)
	warm.add_theme_font_size_override("font_size", 18)
	var recent: Dictionary = profile.records.back() if not profile.records.is_empty() else {}
	if not recent.is_empty():
		_button(primary, "查看最近报告", func(): app.open_report(recent))
	hero.add_child(RangeStyle.text("快速定位  2 分钟     爆头  2 分钟     急停  3 分钟     预瞄  3 分钟", 15, RangeStyle.MUTED))
	_space(hero)

	var section := HBoxContainer.new()
	section.add_theme_constant_override("separation", 12)
	body.add_child(section)
	var accent := ColorRect.new()
	accent.color = RangeStyle.RED
	accent.custom_minimum_size = Vector2(4, 22)
	accent.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	section.add_child(accent)
	section.add_child(RangeStyle.text("专项训练", 26))
	_space(section)
	section.add_child(RangeStyle.text("单轮时长", 15, RangeStyle.MUTED))
	var lengths := OptionButton.new()
	lengths.custom_minimum_size = Vector2(106, 38)
	for length: int in [30, 60, 90, 120]:
		lengths.add_item("%d 秒" % length, length)
		if seconds == length:
			lengths.select(lengths.item_count - 1)
	lengths.item_selected.connect(func(index: int): seconds = lengths.get_item_id(index))
	section.add_child(lengths)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 13)
	grid.add_theme_constant_override("v_separation", 12)
	body.add_child(grid)
	var labels := {
		"grid": "六靶并行 · 连续甩枪", "micro": "小靶精度 · 短距修正", "head": "头部判定 · 分离躯干",
		"track": "持续命中 · 变速移动", "stop": "横移触发 · 停稳开枪", "peek": "掩体走位 · 头线预瞄",
		"reaction": "随机亮靶 · 限时命中", "adaptive": "成绩驱动 · 难度调整"
	}
	for index in Drills.MODES.size():
		var mode: String = Drills.MODES[index]
		var card := _button(grid, "", func(): app.start(mode, seconds))
		card.custom_minimum_size.y = 99
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.tooltip_text = Drills.DETAILS[mode]
		card.name = mode
		card.add_theme_stylebox_override("normal", RangeStyle.slab(Color("#121722f9"), RangeStyle.BORDER))
		card.add_theme_stylebox_override("hover", RangeStyle.slab(Color("#231923"), RangeStyle.RED))
		var stack := VBoxContainer.new()
		stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_theme_constant_override("separation", 4)
		card.add_child(stack)
		stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stack.offset_left = 18
		stack.offset_right = -13
		stack.offset_top = 17
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(row)
		row.add_child(RangeStyle.text(Drills.title(mode), 20))
		_space(row)
		var icon := DrillIcon.new()
		icon.drill = index
		row.add_child(icon)
		stack.add_child(RangeStyle.text(labels[mode], 14, RangeStyle.MUTED))
	_rule(body)
	var footer := HBoxContainer.new()
	body.add_child(footer)
	footer.add_child(RangeStyle.text("鼠标瞄准   ·   左键射击   ·   W A S D 移动   ·   Esc 暂停", 14, RangeStyle.MUTED))
	_space(footer)
	status = RangeStyle.text("训练记录保存在本机", 14, RangeStyle.SUBTLE)
	footer.add_child(status)


func _scroller(body: VBoxContainer) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 15)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	return content


func _panel(parent: Control, title: String = "") -> VBoxContainer:
	var container := PanelContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(container)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	container.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)
	if not title.is_empty():
		content.add_child(RangeStyle.text(title, 23))
		_rule(content)
	return content


func _line(parent: VBoxContainer, name: String, note: String = "") -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	parent.add_child(line)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 3)
	line.add_child(words)
	words.add_child(RangeStyle.text(name, 17))
	if not note.is_empty():
		words.add_child(RangeStyle.text(note, 13, RangeStyle.MUTED))
	_space(line)
	return line


func _numeric(parent: VBoxContainer, name: String, key: String, limits: Vector3, note: String = "") -> void:
	var line := _line(parent, name, note)
	var spin := SpinBox.new()
	spin.min_value = limits.x
	spin.max_value = limits.y
	spin.step = limits.z
	spin.value = app.profile.settings[key]
	spin.custom_minimum_size.x = 139
	spin.get_line_edit().context_menu_enabled = false
	spin.value_changed.connect(func(value: float):
		app.change_setting(key, int(value) if LocalProfile.DEFAULTS[key] is int else value)
		_refresh_settings()
	)
	line.add_child(spin)


func _options(parent: VBoxContainer, name: String, key: String, options: Array, note: String = "") -> void:
	var line := _line(parent, name, note)
	var list := OptionButton.new()
	list.custom_minimum_size.x = 144
	for index in options.size():
		list.add_item(options[index][0])
		if app.profile.settings[key] == options[index][1]:
			list.select(index)
	list.item_selected.connect(func(index: int): app.change_setting(key, options[index][1]))
	line.add_child(list)


func _toggle(parent: VBoxContainer, name: String, key: String, note: String = "") -> void:
	var line := _line(parent, name, note)
	var button := CheckButton.new()
	button.button_pressed = app.profile.settings[key]
	button.text = "开" if button.button_pressed else "关"
	button.toggled.connect(func(active: bool):
		button.text = "开" if active else "关"
		app.change_setting(key, active)
		_refresh_settings()
	)
	line.add_child(button)


func settings(notice: String = "") -> void:
	var body := _shell(true)
	_heading(body, "设置", "调整输入、画面和准星。更改会保存到本机。")
	var content := _scroller(body)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	content.add_child(columns)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 15)
	columns.add_child(left)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 15)
	columns.add_child(right)

	var mouse := _panel(left, "鼠标与视野")
	_numeric(mouse, "游戏灵敏度", "sensitivity", Vector3(0.01, 10.0, 0.001), "参考无畏契约的游戏内灵敏度")
	_numeric(mouse, "鼠标 DPI", "dpi", Vector3(100, 35000, 1), "填写鼠标当前使用的 DPI")
	edpi = RangeStyle.text("", 17, RangeStyle.GREEN)
	mouse.add_child(edpi)
	_numeric(mouse, "水平视野（16∶9 等效）", "fov", Vector3(75, 120, 0.5), "默认 103°，宽高比变化时保持垂直视野")
	_toggle(mouse, "原始鼠标输入", "raw", "捕获时使用屏幕相对位移，关闭事件累积")
	_numeric(mouse, "射击与命中音量", "audio", Vector3(0, 1, 0.01), "0 为静音，1 为最大音量")

	var display_panel := _panel(right, "画面与性能")
	_options(display_panel, "显示模式", "fullscreen", [["窗口模式", false], ["全屏模式", true]])
	var refresh := DisplayServer.screen_get_refresh_rate()
	display_panel.add_child(RangeStyle.text("系统报告刷新率  %.1f 赫兹" % refresh if refresh > 0.0 else "系统刷新率不可用", 14, RangeStyle.MUTED))
	var limits: Array = []
	for limit: int in LocalProfile.LIMITS:
		limits.append(["无限制" if limit == 0 else "%d 帧/秒" % limit, limit])
	_options(display_panel, "帧率限制", "fps_limit", limits)
	_toggle(display_panel, "垂直同步", "vsync", "开启时由显示系统同步呈现")
	_options(display_panel, "画质", "quality", [["极低 · 电竞性能", 0], ["标准", 1], ["高", 2]], "极低模式关闭附加装饰、动态光照和抗锯齿")
	_toggle(display_panel, "实时性能监测", "perf", "瞬时帧率、帧时间、平均帧率和最慢 1% 帧率")

	var reticle := _panel(right, "准星")
	var example := PanelContainer.new()
	example.custom_minimum_size.y = 80
	example.add_theme_stylebox_override("panel", RangeStyle.slab(Color("#0b1019"), RangeStyle.BORDER))
	reticle.add_child(example)
	crosshair_preview = RangeHUD.new()
	crosshair_preview.profile = app.profile.settings
	crosshair_preview.preview_only = true
	example.add_child(crosshair_preview)
	var color_row := _line(reticle, "颜色", "填写六位十六进制色值")
	var color_field := LineEdit.new()
	color_field.context_menu_enabled = false
	color_field.max_length = 7
	color_field.custom_minimum_size.x = 128
	color_field.text = app.profile.settings.color
	color_field.text_changed.connect(func(value: String):
		if value.length() == 7 and value.begins_with("#") and Color.html_is_valid(value):
			app.change_setting("color", value)
			_refresh_settings()
	)
	color_row.add_child(color_field)
	color_field.focus_exited.connect(func(): color_field.text = app.profile.settings.color)
	_numeric(reticle, "间距", "gap", Vector3(0, 30, 1))
	_numeric(reticle, "线长", "length", Vector3(1, 30, 1))
	_numeric(reticle, "线宽", "thickness", Vector3(1, 8, 1))
	_toggle(reticle, "中心点", "dot")
	_toggle(reticle, "描边", "outline")

	var data := _panel(left, "备份与还原")
	data.add_child(RangeStyle.text("导入会应用备份中的设置并合并训练记录。", 15, RangeStyle.MUTED))
	data_path = LineEdit.new()
	data_path.context_menu_enabled = false
	data_path.placeholder_text = "输入备份文件的完整路径"
	data_path.text = "user://AIM-ZERO-备份.json" if OS.has_feature("web") else ProjectSettings.globalize_path("user://AIM-ZERO-备份.json")
	data.add_child(data_path)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	data.add_child(buttons)
	_button(buttons, "导出备份", func(): app.backup(data_path.text.strip_edges(), false))
	_button(buttons, "导入备份", func(): app.backup(data_path.text.strip_edges(), true))
	if not OS.has_feature("web"):
		_button(buttons, "打开数据文件夹", func(): OS.shell_open(ProjectSettings.globalize_path("user://")))
	status = RangeStyle.text(notice, 15, RangeStyle.GREEN)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	data.add_child(status)
	_refresh_settings()


func _refresh_settings() -> void:
	if is_instance_valid(edpi):
		var data: Dictionary = app.profile.settings
		edpi.text = "等效灵敏度（eDPI） %.1f     转身一圈 %.1f 厘米" % [data.dpi * data.sensitivity, 360.0 * 2.54 / (data.dpi * data.sensitivity * Drills.YAW_PER_COUNT)]
	if is_instance_valid(crosshair_preview):
		crosshair_preview.queue_redraw()


func notify(message: String, error: bool = false) -> void:
	if not is_instance_valid(status):
		return
	status.text = message
	status.add_theme_color_override("font_color", RangeStyle.RED if error else RangeStyle.GREEN)


func guide() -> void:
	var body := _shell(true)
	_heading(body, "操作指南", "选择任一专项训练，或从主菜单开始 10 分钟排位前热身。")
	var content := _scroller(body)
	var controls := _panel(content, "操作")
	for text: String in [
		"移动鼠标瞄准，按下左键射击。动态跟枪支持按住左键连续射击。",
		"急停和实战预瞄支持 W、A、S、D 移动。急停练习需要先横移，再松开方向键。",
		"按 Esc 暂停或继续。窗口失焦会暂停训练。按 F11 切换全屏。",
		"在设置中输入鼠标 DPI 和游戏灵敏度。默认视野为 16∶9 下水平 103°。"
	]:
		controls.add_child(RangeStyle.text(text, 18, RangeStyle.MUTED))
	var all := _panel(content, "训练项目")
	for mode: String in Drills.MODES + ["warmup"]:
		var row := HBoxContainer.new()
		all.add_child(row)
		var title := RangeStyle.text(Drills.title(mode), 18)
		title.custom_minimum_size.x = 192
		row.add_child(title)
		row.add_child(RangeStyle.text(Drills.DETAILS[mode], 16, RangeStyle.MUTED))
	var stats := _panel(content, "读懂报告")
	for text: String in [
		"爆头率按人形目标的命中数计算。反应时间从有效目标首次呈现到首次有效命中。",
		"热力图记录开枪瞬间的角度偏差，超出画面标注范围的采样归入边缘格。",
		"拉枪过度与不足根据初始瞄准位置到目标的方向测量，仅统计有效静态定位样本。",
		"平均帧率来自最近约四秒。最慢 1% 帧率为最慢一组帧的平均帧时间倒数。",
		"全屏和关闭垂直同步可用于高刷设置。实际刷新率由 Windows 和显示器决定。"
	]:
		stats.add_child(RangeStyle.text(text, 16, RangeStyle.MUTED))


func history() -> void:
	var body := _shell(true)
	_heading(body, "训练记录", "选择一轮训练查看报告。这里显示最近完成的训练。")
	var content := _scroller(body)
	var profile: LocalProfile = app.profile
	if profile.records.is_empty():
		var empty := _panel(content, "还没有训练记录")
		empty.add_child(RangeStyle.text("完成首次练习后，可在此查看命中、反应时间和进步趋势。", 17, RangeStyle.MUTED))
		_button(empty, "选择训练", app.open_menu, true)
		return
	for index in range(profile.records.size() - 1, -1, -1):
		var report_data: Dictionary = profile.records[index]
		var time := _date(report_data.timestamp)
		var row := _panel(content)
		var details := HBoxContainer.new()
		details.add_theme_constant_override("separation", 20)
		row.add_child(details)
		var title := RangeStyle.text(Drills.title(report_data.mode), 21)
		title.custom_minimum_size.x = 195
		details.add_child(title)
		details.add_child(RangeStyle.text(time, 15, RangeStyle.MUTED))
		_space(details)
		details.add_child(RangeStyle.text("命中率  " + TrainingMetrics.percent(report_data.hits, report_data.shots), 16, RangeStyle.PAPER))
		details.add_child(RangeStyle.text("反应  " + TrainingMetrics.average_reaction(report_data), 16, RangeStyle.MUTED))
		_button(details, "查看报告", func(): app.open_report(report_data))


func _date(time: int) -> String:
	var stamp := Time.get_datetime_dict_from_unix_time(time + int(Time.get_time_zone_from_system().bias) * 60)
	return "%04d-%02d-%02d  %02d:%02d" % [stamp.year, stamp.month, stamp.day, stamp.hour, stamp.minute]


func report(data: Dictionary) -> void:
	var body := _shell(true)
	var date := _date(int(data.get("timestamp", Time.get_unix_time_from_system())))
	_heading(body, Drills.title(data.mode) + " · 训练报告", "%s    ·    %d 秒    ·    发射 %d 次" % [date, roundi(data.seconds), int(data.shots)])
	var content := _scroller(body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 13)
	content.add_child(row)
	var human_hits := 0.0
	for stage: Dictionary in data.stages:
		if stage.mode in ["head", "peek"]:
			human_hits += stage.hits
	_stat(row, "命中率", TrainingMetrics.percent(data.hits, data.shots))
	if BenchmarkCatalog.known(data.mode):
		var config: Dictionary = BenchmarkCatalog.ITEMS.get(data.mode, BenchmarkCatalog.PRIOR.get(data.mode))
		var points: float = data.eliminations * config.multiplier
		var accuracy := TrainingMetrics.ratio(data.hits, data.shots)
		match config.score:
			"remaining": points = maxf(0,1000-data.seconds) if data.eliminations >= 6 else 0.0
			"damage": points = (data.track_on if data.track_ticks > 0 else data.hits * .05) * config.multiplier
			"sqrt": points *= sqrt(accuracy)
			"accuracy": points *= accuracy
		_stat(row, "本地模拟分", "%.1f" % points)
	else:
		_stat(row, "爆头率", TrainingMetrics.percent(data.heads, human_hits))
	_stat(row, "平均反应时间", TrainingMetrics.average_reaction(data))
	_stat(row, "每分钟命中", "%.1f" % TrainingMetrics.hits_per_minute(data))
	_stat(row, "拉枪 过度／不足", "%d / %d" % [int(data.over), int(data.under)] if data.over + data.under + data.on > 0 else "—")
	var plots := HBoxContainer.new()
	plots.add_theme_constant_override("separation", 13)
	content.add_child(plots)
	var heat := _panel(plots, "瞄准偏差热力图")
	var heat_map := RangePlot.new()
	heat_map.heat = true
	heat_map.values = data.heat
	heat_map.custom_minimum_size = Vector2(450, 195)
	heat.add_child(heat_map)
	var history_panel := _panel(plots, "历史命中率")
	var effect := RangePlot.new()
	for report_data: Dictionary in app.profile.records:
		if report_data.mode == data.mode and report_data.shots > 0:
			effect.values.append(TrainingMetrics.ratio(report_data.hits, report_data.shots))
	if effect.values.size() > 20:
		effect.values = effect.values.slice(-20)
	effect.custom_minimum_size = Vector2(450, 195)
	history_panel.add_child(effect)
	var advice := _panel(content, "弱项与建议")
	for tip: String in _suggestions(data):
		advice.add_child(RangeStyle.text(tip, 16, RangeStyle.MUTED))
	if data.stages.size() > 1:
		var detail := _panel(content, "分项成绩")
		for index in data.stages.size():
			var stage: Dictionary = data.stages[index]
			var title := "快速定位" if data.mode == "warmup" and index == 0 else Drills.title(stage.mode)
			var line := "%s    %d 秒     命中 %d／%d     平均反应 %s" % [title, roundi(stage.seconds), int(stage.hits), int(stage.shots), TrainingMetrics.average_reaction(stage)]
			detail.add_child(RangeStyle.text(line, 16, RangeStyle.MUTED))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	body.add_child(actions)
	if Drills.TITLES.has(data.mode) or BenchmarkCatalog.ITEMS.has(data.mode):
		_button(actions, "再练一轮", func(): app.start(data.mode, int(data.seconds)), true)
	_button(actions, "训练记录", app.open_history)
	_space(actions)
	status = RangeStyle.text("", 15, RangeStyle.RED)
	actions.add_child(status)


func _stat(row: HBoxContainer, key: String, value: String) -> void:
	var cell := _panel(row)
	cell.add_child(RangeStyle.text(key, 15, RangeStyle.MUTED))
	cell.add_child(RangeStyle.text(value, 29, RangeStyle.PAPER))


func _suggestions(data: Dictionary) -> Array[String]:
	var notes: Array[String] = []
	if data.shots == 0:
		notes.append("本轮没有射击样本。完成有命中的训练后会显示基于成绩的建议。")
	else:
		var flicks: float = data.over + data.under + data.on
		if flicks >= 3 and maxf(data.over, data.under) / flicks >= 0.44:
			notes.append("拉枪%s偏多。练习微调定位，先稳定第一段移动，再进行短距离修正。" % ("过度" if data.over >= data.under else "不足"))
		if data.stop_shots > 0 and TrainingMetrics.ratio(data.unsettled, data.stop_shots) >= 0.25:
			notes.append("停稳前开枪 %d 次，占移动项目射击的 %s。用急停提示校准松键到开枪的间隔。" % [int(data.unsettled), TrainingMetrics.percent(data.unsettled, data.stop_shots)])
		if data.preaim_n > 0:
			notes.append("露出目标时，准星平均偏离头部 %.1f°。横移时沿掩体上的头线提前摆好准星。" % TrainingMetrics.ratio(data.preaim_deg, data.preaim_n))
		if data.track_ticks > 0:
			notes.append("跟枪在靶时长占 %s。以稳定跟随作为练习目标，逐步增加速度。" % TrainingMetrics.percent(data.track_on, data.track_ticks))
		if data.reaction_n >= 3 and TrainingMetrics.ratio(data.reaction_ms, data.reaction_n) >= 450.0:
			notes.append("识别到命中的平均间隔较长。可用极限反应项目练习确认亮靶后立即开枪。")
		if data.shots >= 5 and TrainingMetrics.ratio(data.hits, data.shots) < 0.55:
			notes.append("本轮命中率低于 55%。先降低击发节奏，用六球速射练习准星到位后开枪。")
		var human_hits := 0.0
		for stage: Dictionary in data.stages:
			if stage.mode in ["head", "peek"]:
				human_hits += stage.hits
		if human_hits >= 4 and TrainingMetrics.ratio(data.heads, human_hits) < 0.45:
			notes.append("人形命中多落在躯干。用爆头训练练习在转向前保持头部高度。")
	var adapt: Dictionary = app.profile.adaptive_choices()
	for drill: String in adapt.order:
		if adapt.evidence.has(drill):
			notes.append("近期优先练习  %s。自适应训练会参考该项目和其他已有成绩。" % Drills.title(drill))
			break
	if notes.is_empty():
		notes.append("本轮数据尚未达到弱项判定条件。重复同一项目可以观察趋势。")
	return notes


func paused() -> void:
	_clear()
	var shade := ColorRect.new()
	shade.color = Color("#090d17db")
	_fill(shade)
	var center := CenterContainer.new()
	_fill(center)
	var card := _panel(center)
	card.get_parent().custom_minimum_size.x = 450
	card.add_child(RangeStyle.text("训练暂停", 36))
	card.add_child(RangeStyle.text("计时已暂停。按 Esc 或点击下方按钮继续。", 16, RangeStyle.MUTED))
	_button(card, "继续训练", app.resume, true)
	_button(card, "退出本轮", app.open_menu)
