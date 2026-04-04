class_name TextCompletionContext extends RefCounted

var partial_text: String:
	set(value):
		partial_text = value
		_dirty = true

var options: PackedStringArray:
	set(value):
		options = value
		_dirty = true

var _suggestion_index: int = -1
var _suggestions: PackedStringArray
var _dirty: bool = false

func current_suggestion() -> String:
	if _dirty: _update()
	return _current_suggestion_no_update()

func prev_suggestion() -> String:
	if _dirty: _update()
	if _suggestions.is_empty(): return ""
	_suggestion_index -= 1
	if _suggestion_index < 0:
		_suggestion_index += _suggestions.size()
	_suggestion_index = _suggestion_index % _suggestions.size()
	return _suggestions[_suggestion_index]

func next_suggestion() -> String:
	if _dirty: _update()
	if _suggestions.is_empty(): return ""
	_suggestion_index += 1
	_suggestion_index = _suggestion_index % _suggestions.size()
	return _suggestions[_suggestion_index]

func get_suggestions() -> PackedStringArray:
	if _dirty: _update()
	return _suggestions.duplicate()

func get_suggestion_index() -> int:
	if _dirty: _update()
	return _suggestion_index

func _current_suggestion_no_update() -> String:
	if _suggestion_index < 0 or _suggestions.is_empty(): return ""
	return _suggestions[_suggestion_index]

func _update() -> void:
	var prev := _current_suggestion_no_update()
	_suggestions.clear()
	for option: String in options:
		if option.length() > partial_text.length() and option.begins_with(partial_text):
			_suggestions.push_back(option)
	_suggestions.sort()
	_suggestion_index = _suggestions.find(prev)
	_dirty = false
