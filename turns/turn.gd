class_name Turn extends Node

signal started
signal ending

var _is_active: bool:
	set(value):
		if value != _is_active:
			if value:
				_is_active = value
				_turn_started()
				started.emit()
			else:
				_turn_ending()
				ending.emit()
				_is_active = value

func _exit_tree() -> void:
	_is_active = false

func start() -> void:
	_is_active = true

func end() -> void:
	_is_active = false

func is_active() -> bool:
	return _is_active

func _turn_started() -> void:
	pass

func _turn_ending() -> void:
	pass
