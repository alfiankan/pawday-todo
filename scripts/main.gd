extends Node2D

const MAP_SIZE := Vector2(2400, 1600)
const TILE_SIZE := 96.0
const TOWNHALL_SIZE := Vector2(180, 150)
const MAX_TOWNHALL_LEVEL := 10
const TOWNHALL_HITBOX := Rect2(Vector2(-140, -190), Vector2(280, 430))

@onready var camera: Camera2D = $Camera2D
@onready var townhall_popup: PanelContainer = $CanvasLayer/TownhallPopup
@onready var townhall_details: Label = $CanvasLayer/TownhallPopup/VBox/Details
@onready var townhall_upgrade_button: Button = $CanvasLayer/TownhallPopup/VBox/UpgradeButton
@onready var townhall_close_button: Button = $CanvasLayer/TownhallPopup/VBox/CloseButton

var is_dragging := false
var drag_start_mouse := Vector2.ZERO
var drag_start_camera := Vector2.ZERO
var touch_points := {}
var pinch_start_distance := 0.0
var pinch_start_zoom := Vector2.ONE
var townhall_level := 1

func _ready() -> void:
	camera.position = Vector2.ZERO
	townhall_upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	townhall_close_button.pressed.connect(_on_close_button_pressed)
	_refresh_townhall_popup()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed and _is_point_on_townhall(get_global_mouse_position()):
				_open_townhall_popup()
				return
			is_dragging = mouse_button.pressed
			drag_start_mouse = mouse_button.position
			drag_start_camera = camera.position
		elif mouse_button.button_index == MOUSE_BUTTON_RIGHT and mouse_button.pressed:
			_set_townhall_level(townhall_level + 1)
		elif mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button.pressed:
			_set_zoom(camera.zoom * 1.1)
		elif mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button.pressed:
			_set_zoom(camera.zoom * 0.9)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_EQUAL or event.keycode == KEY_PLUS:
			_set_townhall_level(townhall_level + 1)
		elif event.keycode == KEY_MINUS:
			_set_townhall_level(townhall_level - 1)
	elif event is InputEventMouseMotion and is_dragging:
		var mouse_motion := event as InputEventMouseMotion
		var drag_delta: Vector2 = mouse_motion.position - drag_start_mouse
		camera.position = _clamp_camera(drag_start_camera - drag_delta / camera.zoom)
		queue_redraw()
	elif event is InputEventScreenDrag:
		var screen_drag := event as InputEventScreenDrag
		touch_points[screen_drag.index] = screen_drag.position
		if touch_points.size() >= 2:
			_handle_pinch_zoom()
		elif touch_points.size() == 1:
			camera.position = _clamp_camera(camera.position - screen_drag.relative / camera.zoom)
			queue_redraw()
	elif event is InputEventScreenTouch:
		var screen_touch := event as InputEventScreenTouch
		if screen_touch.pressed:
			touch_points[screen_touch.index] = screen_touch.position
			if touch_points.size() == 2:
				pinch_start_distance = _get_touch_distance()
				pinch_start_zoom = camera.zoom
		else:
			touch_points.erase(screen_touch.index)
			if touch_points.size() < 2:
				pinch_start_distance = 0.0


func _draw() -> void:
	_draw_map()
	_draw_townhall()
	_draw_hud_hint()


func _draw_map() -> void:
	var top_left := -MAP_SIZE / 2.0
	draw_rect(Rect2(top_left, MAP_SIZE), Color("#7fd06d"), true)

	for x in range(int(top_left.x), int(top_left.x + MAP_SIZE.x) + 1, int(TILE_SIZE)):
		draw_line(Vector2(x, top_left.y), Vector2(x, top_left.y + MAP_SIZE.y), Color(0.2, 0.45, 0.18, 0.10), 2.0)
	for y in range(int(top_left.y), int(top_left.y + MAP_SIZE.y) + 1, int(TILE_SIZE)):
		draw_line(Vector2(top_left.x, y), Vector2(top_left.x + MAP_SIZE.x, y), Color(0.2, 0.45, 0.18, 0.10), 2.0)

	draw_circle(Vector2(-420, -180), 220, Color("#98de84"))
	draw_circle(Vector2(530, 260), 190, Color("#6cb85e"))
	draw_circle(Vector2(740, -420), 170, Color("#9ae287"))
	draw_circle(Vector2(-120, 380), 150, Color("#83cf72"))
	draw_circle(Vector2(180, -300), 180, Color("#5ba650"))
	draw_circle(Vector2(-760, 220), 130, Color("#a4e68e"))
	draw_circle(Vector2(860, 120), 110, Color("#70c263"))

	# Cartoon road crossing with stone+dirt styling.
	var road_vertical := Rect2(Vector2(-78, -MAP_SIZE.y / 2.0), Vector2(156, MAP_SIZE.y))
	var road_horizontal := Rect2(Vector2(-MAP_SIZE.x / 2.0, -86), Vector2(MAP_SIZE.x, 172))
	draw_rect(road_vertical, Color("#9e8a73"), true)
	draw_rect(road_horizontal, Color("#9e8a73"), true)
	draw_rect(road_vertical.grow(-18), Color("#8a745f"), true)
	draw_rect(road_horizontal.grow(-18), Color("#8a745f"), true)

	for i in range(-10, 11):
		var x := i * 72.0
		draw_circle(Vector2(x, 0), 10, Color("#a99680"))
	for j in range(-8, 9):
		var y := j * 72.0
		draw_circle(Vector2(0, y), 10, Color("#a99680"))


func _draw_townhall() -> void:
	var palace_base := Rect2(-TOWNHALL_SIZE / 2.0 + Vector2(0, 30), Vector2(220, 162))
	var wall_color := Color("#ffd6e9")
	var wall_shadow := Color("#f4b8d5")
	var outline := Color("#6a4c5c")
	var roof_color := Color("#ff9fc4")
	var roof_inner := Color("#ffc7de")
	var gold := Color("#ffd76a")
	var cool_level: float = float(townhall_level - 1) / float(MAX_TOWNHALL_LEVEL - 1)
	var tower_radius := 40.0 + 2.0 * cool_level
	var crown_y := -150.0 - 12.0 * cool_level

	# Side towers for a stronger "kingdom castle" silhouette.
	draw_circle(Vector2(-126, 72), tower_radius, wall_color)
	draw_circle(Vector2(126, 72), tower_radius, wall_color)
	draw_circle(Vector2(-126, 102), 34, wall_shadow)
	draw_circle(Vector2(126, 102), 34, wall_shadow)
	draw_circle(Vector2(-126, 72), tower_radius, outline, false, 5.0)
	draw_circle(Vector2(126, 72), tower_radius, outline, false, 5.0)

	draw_rect(palace_base, wall_color, true)
	draw_rect(Rect2(palace_base.position + Vector2(0, 114), Vector2(palace_base.size.x, 54)), wall_shadow, true)
	draw_rect(palace_base, outline, false, 5.0)

	var roof := PackedVector2Array([
		Vector2(-130, -48),
		Vector2(0, -170),
		Vector2(130, -48),
	])
	draw_polygon(roof, PackedColorArray([roof_color, roof_color, roof_color]))
	draw_polyline(PackedVector2Array([roof[0], roof[1], roof[2], roof[0]]), outline, 6.0)

	# Cat ears on the roof.
	draw_polygon(PackedVector2Array([Vector2(-86, -78), Vector2(-58, -138), Vector2(-34, -76)]), PackedColorArray([roof_color, roof_color, roof_color]))
	draw_polygon(PackedVector2Array([Vector2(34, -76), Vector2(58, -138), Vector2(86, -78)]), PackedColorArray([roof_color, roof_color, roof_color]))
	draw_polygon(PackedVector2Array([Vector2(-78, -82), Vector2(-58, -124), Vector2(-42, -82)]), PackedColorArray([roof_inner, roof_inner, roof_inner]))
	draw_polygon(PackedVector2Array([Vector2(42, -82), Vector2(58, -124), Vector2(78, -82)]), PackedColorArray([roof_inner, roof_inner, roof_inner]))

	# Crown ornament.
	draw_circle(Vector2(0, crown_y), 16 + 2.0 * cool_level, gold)
	draw_circle(Vector2(-20, crown_y + 6), 8, gold)
	draw_circle(Vector2(20, crown_y + 6), 8, gold)
	draw_polygon(PackedVector2Array([Vector2(-15, crown_y - 4), Vector2(0, crown_y - 22), Vector2(15, crown_y - 4)]), PackedColorArray([gold, gold, gold]))

	# Door and cat face details.
	draw_rect(Rect2(Vector2(-36, 76), Vector2(72, 94)), Color("#b5798f"), true)
	draw_rect(Rect2(Vector2(-36, 76), Vector2(72, 94)), outline, false, 4.0)
	draw_circle(Vector2(0, 36), 16, Color("#fff0f6"))
	draw_circle(Vector2(-7, 34), 3, outline)
	draw_circle(Vector2(7, 34), 3, outline)
	draw_polygon(PackedVector2Array([Vector2(0, 42), Vector2(-4, 48), Vector2(4, 48)]), PackedColorArray([Color("#f69abf"), Color("#f69abf"), Color("#f69abf")]))
	draw_line(Vector2(-15, 44), Vector2(-31, 40), outline, 2.0)
	draw_line(Vector2(-15, 48), Vector2(-31, 48), outline, 2.0)
	draw_line(Vector2(15, 44), Vector2(31, 40), outline, 2.0)
	draw_line(Vector2(15, 48), Vector2(31, 48), outline, 2.0)

	# Windows
	draw_rect(Rect2(Vector2(-88, 16), Vector2(40, 34)), Color("#fff2a8"), true)
	draw_rect(Rect2(Vector2(48, 16), Vector2(40, 34)), Color("#fff2a8"), true)
	draw_rect(Rect2(Vector2(-88, 16), Vector2(40, 34)), outline, false, 3.0)
	draw_rect(Rect2(Vector2(48, 16), Vector2(40, 34)), outline, false, 3.0)

	# Cute bunting and paw badge.
	for i in range(-4, 5):
		var x := i * 22.0
		draw_polygon(
			PackedVector2Array([Vector2(x - 8, -24), Vector2(x + 8, -24), Vector2(x, -8)]),
			PackedColorArray([Color("#ffd3a6"), Color("#ffd3a6"), Color("#ffd3a6")])
		)
	draw_circle(Vector2(0, 2), 14, Color("#ffe8b7"))
	draw_circle(Vector2(-8, -8), 4, Color("#ffd3a6"))
	draw_circle(Vector2(8, -8), 4, Color("#ffd3a6"))
	draw_circle(Vector2(-5, 8), 4, Color("#ffd3a6"))
	draw_circle(Vector2(5, 8), 4, Color("#ffd3a6"))

	_draw_townhall_upgrades(outline, cool_level)

	var label_font := ThemeDB.fallback_font
	draw_string(label_font, Vector2(-126, 224), "Cathouse Kingdom Hall Lv.%d" % townhall_level, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#5b4550"))


func _draw_townhall_upgrades(outline: Color, cool_level: float) -> void:
	if townhall_level >= 2:
		draw_rect(Rect2(Vector2(-112, -8), Vector2(18, 26)), Color("#fff6cf"), true)
		draw_rect(Rect2(Vector2(94, -8), Vector2(18, 26)), Color("#fff6cf"), true)
	if townhall_level >= 3:
		draw_circle(Vector2(-126, 36), 10, Color("#ffef8e"))
		draw_circle(Vector2(126, 36), 10, Color("#ffef8e"))
	if townhall_level >= 4:
		draw_line(Vector2(-108, -60), Vector2(-108, -102), outline, 3.0)
		draw_line(Vector2(108, -60), Vector2(108, -102), outline, 3.0)
		draw_polygon(PackedVector2Array([Vector2(-116, -102), Vector2(-100, -102), Vector2(-108, -86)]), PackedColorArray([Color("#8dd3ff"), Color("#8dd3ff"), Color("#8dd3ff")]))
		draw_polygon(PackedVector2Array([Vector2(100, -102), Vector2(116, -102), Vector2(108, -86)]), PackedColorArray([Color("#8dd3ff"), Color("#8dd3ff"), Color("#8dd3ff")]))
	if townhall_level >= 5:
		draw_rect(Rect2(Vector2(-76, -48), Vector2(152, 12)), Color("#ffe79f"), true)
	if townhall_level >= 6:
		for i in range(-3, 4):
			draw_circle(Vector2(i * 24.0, -60), 5, Color("#fff3ca"))
	if townhall_level >= 7:
		draw_circle(Vector2(0, -194), 11, Color("#9be4ff"))
		draw_circle(Vector2(-18, -186), 6, Color("#9be4ff"))
		draw_circle(Vector2(18, -186), 6, Color("#9be4ff"))
	if townhall_level >= 8:
		draw_arc(Vector2(0, 112), 96, PI, TAU, 24, Color("#f3a0da"), 5.0)
	if townhall_level >= 9:
		draw_rect(Rect2(Vector2(-12, -224), Vector2(24, 34)), Color("#f7f1ff"), true)
		draw_rect(Rect2(Vector2(-12, -224), Vector2(24, 34)), outline, false, 3.0)
	if townhall_level >= 10:
		for i in range(6):
			var angle := float(i) * TAU / 6.0
			var p := Vector2(cos(angle), sin(angle)) * 148.0
			draw_circle(Vector2(0, 18) + p, 7.0 + cool_level, Color("#fff6de", 0.85))


func _draw_hud_hint() -> void:
	var screen_top_left := camera.get_screen_center_position() - get_viewport_rect().size / (2.0 * camera.zoom)
	var hint_rect := Rect2(screen_top_left + Vector2(24, 24) / camera.zoom, Vector2(700, 44) / camera.zoom)
	draw_rect(hint_rect, Color(0.08, 0.1, 0.08, 0.72), true)
	draw_string(
		ThemeDB.fallback_font,
		hint_rect.position + Vector2(16, 30) / camera.zoom,
		"Drag map. Scroll/pinch zoom. +/- or right-click to change Townhall level.",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		int(20 / camera.zoom.x),
		Color.WHITE
	)


func _set_zoom(value: Vector2) -> void:
	var clamped: float = clamp(value.x, 0.45, 2.2)
	camera.zoom = Vector2(clamped, clamped)
	camera.position = _clamp_camera(camera.position)
	queue_redraw()


func _handle_pinch_zoom() -> void:
	if pinch_start_distance <= 0.0:
		pinch_start_distance = _get_touch_distance()
		pinch_start_zoom = camera.zoom
		return
	var current_distance := _get_touch_distance()
	if current_distance <= 0.0:
		return
	var zoom_factor := pinch_start_distance / current_distance
	_set_zoom(pinch_start_zoom * zoom_factor)


func _get_touch_distance() -> float:
	if touch_points.size() < 2:
		return 0.0
	var points := touch_points.values()
	var first: Vector2 = points[0]
	var second: Vector2 = points[1]
	return first.distance_to(second)


func _set_townhall_level(value: int) -> void:
	townhall_level = wrapi(value, 1, MAX_TOWNHALL_LEVEL + 1)
	_refresh_townhall_popup()
	queue_redraw()


func _is_point_on_townhall(world_pos: Vector2) -> bool:
	return TOWNHALL_HITBOX.has_point(world_pos)


func _open_townhall_popup() -> void:
	_refresh_townhall_popup()
	townhall_popup.visible = true


func _refresh_townhall_popup() -> void:
	var boost := 10 + (townhall_level - 1) * 7
	townhall_details.text = "Level: %d/10\nCute Power: %d\nPerk: %s" % [
		townhall_level,
		boost,
		_get_level_perk(townhall_level),
	]
	if townhall_level >= MAX_TOWNHALL_LEVEL:
		townhall_upgrade_button.disabled = true
		townhall_upgrade_button.text = "Max Level Reached"
	else:
		townhall_upgrade_button.disabled = false
		townhall_upgrade_button.text = "Upgrade to Lv.%d" % (townhall_level + 1)


func _get_level_perk(level: int) -> String:
	var perks := [
		"Cozy Cat Banner",
		"Royal Paw Lamps",
		"Sparkle Trim",
		"Twin Mini Flags",
		"Golden Balcony",
		"Star Garland",
		"Crystal Crown",
		"Rainbow Arch",
		"Moon Tower",
		"Kingdom Aura",
	]
	return perks[level - 1]


func _on_upgrade_button_pressed() -> void:
	if townhall_level < MAX_TOWNHALL_LEVEL:
		_set_townhall_level(townhall_level + 1)
		_open_townhall_popup()


func _on_close_button_pressed() -> void:
	townhall_popup.visible = false


func _clamp_camera(target: Vector2) -> Vector2:
	var viewport_size := get_viewport_rect().size / camera.zoom
	var half_limits := (MAP_SIZE - viewport_size) / 2.0
	if half_limits.x < 0.0:
		half_limits.x = 0.0
	if half_limits.y < 0.0:
		half_limits.y = 0.0
	return Vector2(
		clamp(target.x, -half_limits.x, half_limits.x),
		clamp(target.y, -half_limits.y, half_limits.y)
	)
