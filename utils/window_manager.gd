extends Node

@export var content_scale_curve: Curve

var _default_input_map: Dictionary[StringName, InputEvent] = {
	&"toggle_fullscreen": _create_default_input(KEY_ENTER, false, true),
}

func _init() -> void:
	process_mode = PROCESS_MODE_ALWAYS

func _enter_tree() -> void:
	_add_default_input_actions()
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

## Ideally this would happen when the plugin is enabled, but Godot doesn't seem to support that yet.
## See: godotengine/godot/issues/25865
func _add_default_input_actions() -> void:
	for action: StringName in _default_input_map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			InputMap.action_add_event(action, _default_input_map[action])

func _create_default_input(key: int, shift_pressed: bool = false, alt_pressed: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.shift_pressed = shift_pressed
	event.alt_pressed = alt_pressed
	return event
