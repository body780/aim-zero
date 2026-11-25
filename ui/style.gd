class_name RangeStyle
extends RefCounted

const FONT = preload("res://assets/AimZeroSC.otf")
const INK := Color("#0b0e15")
const PAPER := Color("#edf0f7")
const MUTED := Color("#a2adbf")
const SUBTLE := Color("#718098")
const BORDER := Color("#292f3e")
const PANEL := Color("#11151f")
const RED := Color("#ff4059")
const GREEN := Color("#75ffe0")


static func slab(fill: Color, border: Color = Color.TRANSPARENT, corner: int = 7) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0.0 else 0)
	style.set_corner_radius_all(corner)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style


static func theme() -> Theme:
	var result := Theme.new()
	result.default_font = FONT
	result.default_font_size = 16
	for type: String in ["Button", "OptionButton", "CheckButton", "LineEdit", "SpinBox", "PopupMenu"]:
		result.set_color("font_color", type, PAPER)
		result.set_color("font_hover_color", type, Color.WHITE)
		result.set_color("font_pressed_color", type, Color.WHITE)
		result.set_color("font_disabled_color", type, MUTED)
		result.set_stylebox("normal", type, slab(Color("#181d29"), BORDER))
		result.set_stylebox("hover", type, slab(Color("#222837"), Color("#5a6274")))
		result.set_stylebox("pressed", type, slab(Color("#36202b"), RED))
		result.set_stylebox("focus", type, slab(Color.TRANSPARENT, RED))
	result.set_color("font_placeholder_color", "LineEdit", SUBTLE)
	result.set_color("caret_color", "LineEdit", RED)
	result.set_stylebox("panel", "PopupMenu", slab(PANEL, BORDER))
	result.set_stylebox("panel", "PanelContainer", slab(PANEL, BORDER))
	result.set_constant("h_separation", "PopupMenu", 12)
	result.set_constant("v_separation", "PopupMenu", 9)
	result.set_stylebox("scroll", "VScrollBar", slab(Color("#101520")))
	for state: String in ["grabber", "grabber_highlight", "grabber_pressed"]:
		result.set_stylebox(state, "VScrollBar", slab(Color("#464f61")))
	return result


static func text(value: String, pixels: int, color: Color = PAPER) -> Label:
	var result := Label.new()
	result.text = value
	result.add_theme_font_size_override("font_size", pixels)
	result.add_theme_color_override("font_color", color)
	return result


static func button(value: String, callback: Callable, primary: bool = false) -> Button:
	var result := Button.new()
	result.text = value
	result.custom_minimum_size.y = 43
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.pressed.connect(callback)
	if primary:
		result.add_theme_color_override("font_color", Color("#160910"))
		result.add_theme_color_override("font_hover_color", Color("#160910"))
		result.add_theme_stylebox_override("normal", slab(RED))
		result.add_theme_stylebox_override("hover", slab(Color("#ff6c7e")))
		result.add_theme_stylebox_override("pressed", slab(Color("#d92c44")))
	return result


static func gradient(left: Color, right: Color, axis: Vector2 = Vector2.RIGHT) -> TextureRect:
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([left, right])
	var texture := GradientTexture2D.new()
	texture.gradient = ramp
	texture.fill_to = axis
	texture.width = 256
	texture.height = 256
	var node := TextureRect.new()
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node
