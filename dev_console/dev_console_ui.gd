extends Control

@export var history: RichTextLabel
@export var input: LineEdit

var _history_offset: int = -1
var _completion := TextCompletionContext.new()
var _completion_start: int = -1

func _enter_tree() -> void:
	if input:
		input.gui_input.connect(_gui_input)
		input.text_submitted.connect(_on_input_text_submitted)
		input.text_changed.connect(_on_input_text_changed)

func _exit_tree() -> void:
	if input:
		input.gui_input.disconnect(_gui_input)
		input.text_submitted.disconnect(_on_input_text_submitted)
		input.text_changed.disconnect(_on_input_text_changed)

func _ready() -> void:
	if input: input.grab_focus()
	var console := _get_console()
	if console and history:
		console.command_executed.connect(_add_history)
		console.history_cleared.connect(_clear_history)
		var reverse_history := console.history()
		reverse_history.reverse()
		for command: DevConsole.HistoryEntry in reverse_history:
			if not command.hidden: _add_history(command)
		_completion.options = console.get_completion_options("")

func _gui_input(event: InputEvent) -> void:
	var console := _get_console()
	if not console: return
	if input and event.is_action_pressed("console_history_prev", true):
		_move_history(1)
		accept_event()
	elif input and event.is_action_pressed("console_history_next", true):
		_move_history(-1)
		accept_event()
	elif input and event.is_action_pressed("text_completion_prev", true):
		var suggestion := _completion.prev_suggestion()
		_set_suggestion(suggestion)
		accept_event()
	elif input and event.is_action_pressed("text_completion_next", true):
		var suggestion := _completion.next_suggestion()
		_set_suggestion(suggestion)
		accept_event()
	elif event.is_action_pressed("ui_cancel"):
		console.close()
		accept_event()

func _set_suggestion(suggestion: String) -> void:
	if suggestion:
		input.text = input.text.left(_completion_start + 1) + suggestion
		input.caret_column = input.text.length()

func _move_history(offset: int) -> void:
	_history_offset += offset
	var console := _get_console()
	if not console: return

	var hist := console.history()
	_history_offset = clampi(_history_offset, -1, hist.size() - 1)

	input.text = hist[_history_offset].command if _history_offset >= 0 else ""
	input.caret_column = input.text.length()
	_completion.partial_text = input.text

func _add_history(entry: DevConsole.HistoryEntry) -> void:
	if history:
		history.push_context()
		if history.get_line_count(): history.add_text("\n")
		history.add_text(entry.command)
		if entry.result != null:
			var output: Variant = entry.result
			if output is ConsoleCommands:
				output = output._help()
			history.add_text("\n")
			var text_color := history.get_theme_color("error_text_color") if entry.error else history.get_theme_color("secondary_text_color")
			history.push_color(text_color)
			history.add_text(str(output))
			history.pop()
		history.scroll_to_line(history.get_line_count())
		history.pop_context()

func _clear_history() -> void:
	if history: history.clear()

func _on_input_text_submitted(new_text: String) -> void:
	var console := _get_console()
	if console:
		console.run_command(new_text)
	if input: input.clear()
	_history_offset = -1

func _on_input_text_changed(new_text: String) -> void:
	_completion_start = new_text.rfind(".")
	_completion.partial_text = new_text.right(new_text.length() - _completion_start - 1)
	var console := _get_console()
	if console:
		_completion.options = console.get_completion_options(new_text.left(_completion_start + 1))

func _get_console() -> DevConsole:
	return DevConsole.find_console(self)
