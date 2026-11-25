class_name TrainingArena
extends Node3D

class DisplayTarget:
	var root: Node3D
	var orb: Node3D
	var robot: Node3D


const INK := Color("#11141d")
const DARK := Color("#161b26")
const SLATE := Color("#252d3b")
const EDGE := Color("#394354")
const LINE := Color("#262e3b")
const RED := Color("#ff425c")
const DEEP_RED := Color("#641d30")
const BLUE := Color("#68cde5")

var camera: Camera3D
var gun: Node3D
var muzzle: MeshInstance3D
var extras: Node3D
var cover_root: Node3D
var world_light: DirectionalLight3D
var display: Array[DisplayTarget] = []
var box := BoxMesh.new()
var sphere := SphereMesh.new()
var materials := {}
var builders := {}
var preview_nodes: Array[Node3D] = []
var weapon_origin := Vector3(0.245, -0.204, -0.455)
var gun_impulse := 0.0
var quality := 0
var firing_flash_until := 0


func _ready() -> void:
	sphere.radial_segments = 16
	sphere.rings = 8
	sphere.radius = 0.5
	sphere.height = 1.0
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("#e1e9f8")
	world.environment.ambient_light_energy = 0.65
	add_child(world)
	world_light = DirectionalLight3D.new()
	world_light.rotation_degrees = Vector3(-58, -35, 0)
	world_light.light_energy = 0.7
	world_light.shadow_enabled = false
	add_child(world_light)
	_build_room()
	_build_cover()
	camera = Camera3D.new()
	camera.near = 0.045
	camera.far = 55.0
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.current = true
	add_child(camera)
	_build_weapon()
	for index in 6:
		display.append(_build_target())
	preview_nodes.append(_build_robot())
	preview_nodes.append(_build_robot())
	preview_nodes.append(_build_orb(Color("#f73d56")))
	preview_nodes.append(_build_orb(Color("#f73d56")))
	for node: Node3D in preview_nodes:
		add_child(node)
	show_menu()


func _material(color: Color, lit: bool = false) -> StandardMaterial3D:
	var key := color.to_html() + str(lit)
	if materials.has(key):
		return materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL if lit else BaseMaterial3D.SHADING_MODE_UNSHADED
	material.roughness = 0.78
	materials[key] = material
	return material


func _piece(root: Node3D, center: Vector3, dimensions: Vector3, tint: Color, rounded: bool = false, lit: bool = false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = sphere if rounded else box
	node.position = center
	node.scale = dimensions
	node.material_override = _material(tint, lit)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(node)
	return node


func _batch(center: Vector3, dimensions: Vector3, tint: Color, lit: bool = false) -> void:
	var material := _material(tint, lit)
	if not builders.has(material):
		var maker := SurfaceTool.new()
		maker.begin(Mesh.PRIMITIVE_TRIANGLES)
		maker.set_material(material)
		builders[material] = maker
	var surface: SurfaceTool = builders[material]
	surface.append_from(box, 0, Transform3D(Basis.from_scale(dimensions), center))


func _commit(root: Node3D) -> void:
	for material: Material in builders:
		var mesh := MeshInstance3D.new()
		mesh.mesh = builders[material].commit()
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mesh)
	builders.clear()


func _build_room() -> void:
	_batch(Vector3(0, -0.11, -6.75), Vector3(13.55, 0.22, 20.6), DARK, true)
	_batch(Vector3(0, 2.22, -17.01), Vector3(13.8, 4.46, 0.28), INK)
	_batch(Vector3(-6.85, 2.16, -6.75), Vector3(0.3, 4.35, 20.7), INK)
	_batch(Vector3(6.85, 2.16, -6.75), Vector3(0.3, 4.35, 20.7), DARK)
	_batch(Vector3(0, 2.16, 3.35), Vector3(13.8, 4.35, 0.35), INK)
	for index in range(-6, 7):
		_batch(Vector3(index, 0.004, -7.2), Vector3(0.014, 0.008, 18.7), LINE)
	for index in range(-16, 4):
		_batch(Vector3(0, 0.004, index), Vector3(13.3, 0.008, 0.014), LINE)
	for side: float in [-1.0, 1.0]:
		_batch(Vector3(6.52 * side, 0.051, -6.45), Vector3(0.23, 0.11, 19.3), SLATE)
		_batch(Vector3(6.46 * side, 0.116, -6.45), Vector3(0.025, 0.018, 18.96), RED)
		_batch(Vector3(6.60 * side, 3.62, -6.55), Vector3(0.35, 0.32, 20.45), SLATE)
		_batch(Vector3(6.40 * side, 3.47, -6.55), Vector3(0.035, 0.033, 19.74), DEEP_RED)
		for depth: float in [1.9, -2.7, -7.25, -11.8, -16.25]:
			_batch(Vector3(side * 6.55, 2.14, depth), Vector3(0.43, 4.27, 0.33), SLATE)
			_batch(Vector3(side * 6.30, 2.95, depth), Vector3(0.055, 0.99, 0.11), DEEP_RED)
	for index in range(-6, 7, 2):
		_batch(Vector3(index, 2.14, -16.73), Vector3(1.87, 4.22, 0.16), DARK)
		_batch(Vector3(index, 0.92, -16.60), Vector3(1.57, 1.42, 0.11), SLATE)
		_batch(Vector3(index, 1.68, -16.53), Vector3(1.18, 0.033, 0.025), DEEP_RED)
	_batch(Vector3(0, 3.29, -16.54), Vector3(11.4, 0.11, 0.11), EDGE)
	_batch(Vector3(0, 3.34, -16.44), Vector3(9.0, 0.027, 0.05), RED)
	_batch(Vector3(0, 0.019, -1.7), Vector3(3.1, 0.018, 0.046), DEEP_RED)
	for index in range(-4, 5):
		_batch(Vector3(index * 1.25, 0.013, -8.2), Vector3(0.23, 0.017, 0.036), EDGE)
	_commit(self)

	extras = Node3D.new()
	add_child(extras)
	for side: float in [-1.0, 1.0]:
		for index in 6:
			var depth := -1.3 - index * 2.55
			_batch(Vector3(side * 6.63, 1.17, depth), Vector3(0.09, 1.59, 1.95), DARK)
			_batch(Vector3(side * 6.56, 0.6, depth), Vector3(0.043, 0.32, 1.43), SLATE)
			_batch(Vector3(side * 6.56, 1.63, depth), Vector3(0.043, 0.033, 0.61), EDGE)
	for depth: float in [-3.0, -8.0, -13.0]:
		_batch(Vector3(0, 4.27, depth), Vector3(13.3, 0.24, 0.34), SLATE)
		_batch(Vector3(0, 4.13, depth), Vector3(8.85, 0.025, 0.065), Color("#b5c7db"))
	_batch(Vector3(0, 4.51, -6.55), Vector3(13.3, 0.22, 19.55), INK)
	for index in 29:
		_batch(Vector3(-4.2 + index * 0.30, 2.74, -16.46), Vector3(0.10, 0.56, 0.034), EDGE)
	_commit(extras)


func _build_cover() -> void:
	cover_root = Node3D.new()
	add_child(cover_root)
	for bounds: AABB in RangeGeometry.COVER:
		var center := bounds.get_center()
		_batch(center, bounds.size, SLATE, true)
		_batch(Vector3(center.x, bounds.end.y - 0.09, center.z), Vector3(bounds.size.x - 0.09, 0.12, bounds.size.z + 0.008), EDGE)
		for side: float in [-1.0, 1.0]:
			var face := center.z + side * (bounds.size.z * 0.5 + 0.012)
			_batch(Vector3(center.x, 0.21, face), Vector3(bounds.size.x - 0.19, 0.34, 0.024), DARK)
			_batch(Vector3(center.x, Drills.EYE_HEIGHT, face), Vector3(bounds.size.x - 0.16, 0.018, 0.025), RED)
			_batch(Vector3(center.x, 0.78, face), Vector3(bounds.size.x * 0.54, 0.62, 0.022), DARK)
	_commit(cover_root)


func _build_orb(tint: Color) -> Node3D:
	var root := Node3D.new()
	_piece(root, Vector3.ZERO, Vector3.ONE, tint, true, true)
	_piece(root, Vector3(0, 0, 0.38), Vector3(0.55, 0.55, 0.19), Color("#7a2539"), true)
	_piece(root, Vector3(0, 0, 0.49), Vector3(0.20, 0.20, 0.019), Color("#ffe1df"), true)
	return root


func _build_robot() -> Node3D:
	var root := Node3D.new()
	var index := 0
	for part: Array in RangeGeometry.BODY:
		var tint := Color("#354256") if index <= 1 else Color("#263248")
		_piece(root, part[0], part[1], tint, false, true)
		index += 1
	_piece(root, RangeGeometry.HEAD, Vector3.ONE * RangeGeometry.HEAD_RADIUS * 2.0, Color("#d43851"), true, true)
	_piece(root, Vector3(0, 1.654, 0.113), Vector3(0.173, 0.037, 0.029), Color("#fa8190"), true)
	_piece(root, Vector3(0, 1.27, 0.137), Vector3(0.23, 0.18, 0.014), DARK)
	_piece(root, Vector3(0, 1.27, 0.147), Vector3(0.126, 0.028, 0.012), RED)
	_piece(root, Vector3(-0.168, 1.37, 0.137), Vector3(0.038, 0.055, 0.011), BLUE)
	_piece(root, Vector3(0.168, 1.37, 0.137), Vector3(0.038, 0.055, 0.011), BLUE)
	return root


func _build_target() -> DisplayTarget:
	var target := DisplayTarget.new()
	target.root = Node3D.new()
	target.orb = _build_orb(RED)
	target.robot = _build_robot()
	target.root.add_child(target.orb)
	target.root.add_child(target.robot)
	add_child(target.root)
	return target


func _build_weapon() -> void:
	gun = Node3D.new()
	camera.add_child(gun)
	_piece(gun, Vector3(0, 0, 0), Vector3(0.108, 0.123, 0.43), Color("#202735"), false, true)
	_piece(gun, Vector3(0, 0.058, -0.09), Vector3(0.12, 0.032, 0.26), Color("#485364"), false, true)
	_piece(gun, Vector3(0, 0, -0.257), Vector3(0.067, 0.073, 0.12), Color("#323e52"), false, true)
	_piece(gun, Vector3(0, 0.068, -0.20), Vector3(0.038, 0.023, 0.052), RED)
	_piece(gun, Vector3(-0.055, 0.021, -0.07), Vector3(0.012, 0.016, 0.15), RED)
	_piece(gun, Vector3(0.039, -0.105, 0.09), Vector3(0.135, 0.13, 0.24), Color("#111722"), false, true)
	muzzle = _piece(gun, Vector3(0, 0, -0.335), Vector3(0.13, 0.13, 0.13), Color("#ffbca1"), true)
	muzzle.visible = false
	gun.position = weapon_origin


func set_quality(value: int) -> void:
	quality = value
	extras.visible = quality > 0
	get_viewport().msaa_3d = Viewport.MSAA_4X if quality == 2 else Viewport.MSAA_DISABLED
	world_light.visible = quality > 0


func show_menu() -> void:
	gun.hide()
	world_light.show()
	extras.show()
	cover_root.hide()
	for target: DisplayTarget in display:
		target.root.hide()
	for node: Node3D in preview_nodes:
		node.show()
	preview_nodes[0].position = Vector3(0.43, 0, -7.7)
	preview_nodes[0].scale = Vector3.ONE * 1.40
	preview_nodes[1].position = Vector3(2.39, 0, -11.2)
	preview_nodes[1].scale = Vector3.ONE * 1.10
	preview_nodes[2].position = Vector3(2.67, 2.1, -8.68)
	preview_nodes[2].scale = Vector3.ONE * 0.53
	preview_nodes[3].position = Vector3(0.07, 3.08, -10.1)
	preview_nodes[3].scale = Vector3.ONE * 0.35
	camera.position = Vector3(-3.6, 1.83, -2.15)
	camera.look_at(Vector3(-2.85, 1.74, -9.0))
	camera.fov = 67.0


func show_training(session: RangeSession, fov: float) -> void:
	camera.fov = fov
	world_light.visible = quality > 0
	extras.visible = quality > 0
	gun.show()
	cover_root.visible = session.cover
	for node: Node3D in preview_nodes:
		node.hide()
	for target: DisplayTarget in display:
		target.root.hide()


func flash(now: int) -> void:
	gun_impulse = 1.0
	firing_flash_until = now + 33000


func render_session(session: RangeSession, look: Vector2, delta: float, now: int) -> void:
	if camera.position != session.visible_eye:
		camera.position = session.visible_eye
	var view_angles := Vector3(look.y, look.x, 0.0)
	if camera.rotation != view_angles:
		camera.rotation = view_angles
	if gun_impulse > 0.0:
		gun_impulse = move_toward(gun_impulse, 0.0, delta * 12.0)
		gun.position = weapon_origin + Vector3(0, gun_impulse * 0.013, gun_impulse * 0.070)
	muzzle.visible = quality > 0 and now < firing_flash_until
	for index in display.size():
		var target := session.targets[index]
		var visual := display[index]
		visual.root.visible = target.active
		if not target.active:
			continue
		if visual.root.position != target.presented:
			visual.root.position = target.presented
		visual.orb.visible = not target.human
		visual.robot.visible = target.human
		if not target.human:
			var diameter := target.radius * 2.0
			if visual.orb.scale.x != diameter:
				visual.orb.scale = Vector3.ONE * diameter
