class_name InputEventSelector extends Button

signal value_changed(new_value: InputEvent)

var value: InputEvent:
	set(new_value):
		value = new_value
		if _state == State.AMBIENT:
			text = _display_text(new_value)

var _state: State = State.AMBIENT:
	set(new_value):
		if new_value != _state:
			_state = new_value
			match new_value:
				State.AMBIENT: text = _display_text(value)
				State.CHOOSING_INPUT: text = "Press any key..."

var class_filter: PackedStringArray

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_FOCUS_EXIT: _state = State.AMBIENT

func _pressed() -> void:
	_state = State.CHOOSING_INPUT

func _gui_input(event: InputEvent) -> void:
	if _state == State.CHOOSING_INPUT:
		if _cancel_event(event):
			_state = State.AMBIENT
			accept_event()
		elif _valid_event(event):
			_state = State.AMBIENT
			value = event
			value_changed.emit(event)
			accept_event()

func _cancel_event(event: InputEvent) -> bool:
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		return true
	if event is InputEventJoypadButton and (event.button_index == JOY_BUTTON_START or event.button_index == JOY_BUTTON_BACK):
		return true
	return false

func _valid_event(event: InputEvent) -> bool:
	if not class_filter.is_empty():
		for c: String in class_filter:
			if ClassDB.is_parent_class(c, event.get_class()):
				return true
		return false
	return event is InputEventKey or event is InputEventJoypadButton

func _display_text(input_event: InputEvent) -> String:
	if not input_event: return "Unset"
	if input_event is InputEventKey:
		return input_event.as_text_physical_keycode()
	return input_event.as_text()

enum State {
	AMBIENT,
	CHOOSING_INPUT,
}
