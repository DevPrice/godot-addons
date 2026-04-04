class_name TurnSequence extends Node

signal sequence_started
signal sequence_ending
signal turn_started(turn: Turn)
signal turn_ending(turn: Turn)

var _active_turn: Turn:
	set(value):
		if value and value.get_parent() != self: return
		if value != _active_turn:
			var turns := get_turns()
			var prev_turn_index := turns.find(_active_turn)
			var new_turn_index := turns.find(value)
			if _active_turn:
				turn_ending.emit(_active_turn)
				_active_turn.end()
				if prev_turn_index == turns.size() - 1:
					sequence_ending.emit()
			_active_turn = value
			if _active_turn:
				if new_turn_index == 0:
					sequence_started.emit()
				_active_turn.start()
				turn_started.emit(_active_turn)

var _active_turn_path: NodePath:
	get: return get_path_to(_active_turn) if _active_turn else NodePath()
	set(value):
		var node := get_node_or_null(value)
		if node is Turn: _active_turn = node

func _ready() -> void:
	if is_multiplayer_authority():
		next_turn()

func _enter_tree() -> void:
	child_order_changed.connect(_child_order_changed)
	child_exiting_tree.connect(_child_exiting_tree)

func _exit_tree() -> void:
	child_order_changed.disconnect(_child_order_changed)
	child_exiting_tree.disconnect(_child_exiting_tree)

func _child_exiting_tree(child: Node) -> void:
	if child == _active_turn:
		_active_turn = null

func _child_order_changed() -> void:
	if is_multiplayer_authority() and not _active_turn: next_turn()

func end_turn() -> void:
	_active_turn = null

func next_turn() -> void:
	var turns := get_turns()
	if turns.is_empty(): return

	var active_index := get_active_turn_index(turns)
	var next_turn_index := _get_next_turn_index(turns, active_index)
	var next_turn := turns[next_turn_index]
	if next_turn == _active_turn:
		_restart_turn.rpc()
	else:
		_active_turn = next_turn

func _get_next_turn_index(turns: Array[Turn], active_index: int) -> int:
	return (active_index + 1) % turns.size() if active_index >= 0 else 0

@rpc("authority", "call_local")
func _restart_turn() -> void:
	var current_turn := _active_turn
	_active_turn = null
	_active_turn = current_turn

func get_turns() -> Array[Turn]:
	var result: Array[Turn] = []
	result.append_array(get_children().filter(func (it: Node): return it is Turn))
	return result

func get_active_turn_index(turns: Array[Turn] = get_turns()) -> int:
	return turns.find_custom(func (it: Turn): return it.is_active())

func get_active_turn() -> Turn:
	return _active_turn

func is_running() -> bool:
	return get_active_turn_index() >= 0
