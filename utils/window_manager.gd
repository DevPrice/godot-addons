extends Node

@export var content_scale_curve: Curve

func _init() -> void:
	process_mode = PROCESS_MODE_ALWAYS

func _enter_tree() -> void:
	var window := get_window()
	if window:
		window.size_changed.connect(_size_changed)
		if OS.has_feature("web"): JavaScriptBridge.eval("navigator.keyboard && navigator.keyboard.lock()", true)

func _exit_tree() -> void:
	var window := get_window()
	if window: window.size_changed.disconnect(_size_changed)

func _ready() -> void:
	_size_changed()

func _size_changed() -> void:
	var window := get_window()
	if window and content_scale_curve:
		window.content_scale_factor = get_ui_scale(window.size)

func get_ui_scale(viewport_size: Vector2i) -> float:
	var shortest_side := minf(viewport_size.x, viewport_size.y)
	return content_scale_curve.sample(shortest_side)

func _shortcut_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()

func toggle_fullscreen() -> void:
	var window = get_window()
	if window:
		match window.mode:
			Window.MODE_EXCLUSIVE_FULLSCREEN, Window.MODE_FULLSCREEN:
				window.mode = Window.MODE_WINDOWED
			_: window.mode = Window.MODE_FULLSCREEN
		DeviceSettings.store_settings({"display/window/size/mode": window.mode})
