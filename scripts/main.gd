extends Node2D

const MAP_SIZE := Vector2(2400, 1600)
const TILE_SIZE := 96.0
const TOWNHALL_SIZE := Vector2(180, 150)

@onready var camera: Camera2D = $Camera2D

var is_dragging := false
var drag_start_mouse := Vector2.ZERO
var drag_start_camera := Vector2.ZERO

func _ready() -> void:
	camera.position = Vector2.ZERO
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = mouse_button.pressed
			drag_start_mouse = mouse_button.position
			drag_start_camera = camera.position
		elif mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button.pressed:
			_set_zoom(camera.zoom * 1.1)
		elif mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button.pressed:
			_set_zoom(camera.zoom * 0.9)
	elif event is InputEventMouseMotion and is_dragging:
		var mouse_motion := event as InputEventMouseMotion
		var drag_delta: Vector2 = mouse_motion.position - drag_start_mouse
		camera.position = _clamp_camera(drag_start_camera - drag_delta / camera.zoom)
		queue_redraw()
	elif event is InputEventScreenDrag:
		var screen_drag := event as InputEventScreenDrag
		camera.position = _clamp_camera(camera.position - screen_drag.relative / camera.zoom)
		queue_redraw()


func _draw() -> void:
	_draw_map()
	_draw_townhall()
	_draw_hud_hint()


func _draw_map() -> void:
	var top_left := -MAP_SIZE / 2.0
	draw_rect(Rect2(top_left, MAP_SIZE), Color("#7fba74"), true)

	for x in range(int(top_left.x), int(top_left.x + MAP_SIZE.x) + 1, int(TILE_SIZE)):
		draw_line(Vector2(x, top_left.y), Vector2(x, top_left.y + MAP_SIZE.y), Color(1, 1, 1, 0.12), 2.0)
	for y in range(int(top_left.y), int(top_left.y + MAP_SIZE.y) + 1, int(TILE_SIZE)):
		draw_line(Vector2(top_left.x, y), Vector2(top_left.x + MAP_SIZE.x, y), Color(1, 1, 1, 0.12), 2.0)

	draw_circle(Vector2(-420, -180), 140, Color("#78ab69"))
	draw_circle(Vector2(530, 260), 190, Color("#70a262"))
	draw_circle(Vector2(740, -420), 120, Color("#8ccf7a"))
	draw_rect(Rect2(Vector2(-60, -MAP_SIZE.y / 2.0), Vector2(120, MAP_SIZE.y)), Color("#cba56a"), true)
	draw_rect(Rect2(Vector2(-MAP_SIZE.x / 2.0, -70), Vector2(MAP_SIZE.x, 140)), Color("#cba56a"), true)


func _draw_townhall() -> void:
	var base_rect := Rect2(-TOWNHALL_SIZE / 2.0 + Vector2(0, 32), TOWNHALL_SIZE)
	var roof_points := PackedVector2Array([
		Vector2(-118, -42),
		Vector2(0, -140),
		Vector2(118, -42),
	])
	var roof_outline := PackedVector2Array([
		Vector2(-118, -42),
		Vector2(0, -140),
		Vector2(118, -42),
		Vector2(-118, -42),
	])

	draw_polygon(roof_points, PackedColorArray([Color("#9e3e35"), Color("#9e3e35"), Color("#9e3e35")]))
	draw_polyline(roof_outline, Color("#30251f"), 8.0)
	draw_rect(base_rect, Color("#e2b15b"), true)
	draw_rect(base_rect, Color("#30251f"), false, 6.0)
	draw_rect(Rect2(Vector2(-24, 70), Vector2(48, 72)), Color("#674333"), true)
	draw_rect(Rect2(Vector2(-70, 12), Vector2(38, 34)), Color("#f8e4a2"), true)
	draw_rect(Rect2(Vector2(32, 12), Vector2(38, 34)), Color("#f8e4a2"), true)

	var label_font := ThemeDB.fallback_font
	draw_string(label_font, Vector2(-52, 190), "Townhall", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#1f241d"))


func _draw_hud_hint() -> void:
	var screen_top_left := camera.get_screen_center_position() - get_viewport_rect().size / (2.0 * camera.zoom)
	var hint_rect := Rect2(screen_top_left + Vector2(24, 24) / camera.zoom, Vector2(420, 44) / camera.zoom)
	draw_rect(hint_rect, Color(0.08, 0.1, 0.08, 0.72), true)
	draw_string(
		ThemeDB.fallback_font,
		hint_rect.position + Vector2(16, 30) / camera.zoom,
		"Drag the map. Scroll to zoom.",
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
