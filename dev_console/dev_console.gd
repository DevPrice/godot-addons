class_name DevConsole extends Node

signal command_executed(entry: HistoryEntry)
signal history_cleared

@export var _console_ui_scene: PackedScene = preload("uid://cnicb0ows6hmb")

var _active_ui: Node
var _command_history: Array[HistoryEntry]
var _commands: Dictionary[String, Command]
var _prev_result: Variant

var _custom_context: Dictionary[StringName, Variant]

static var _valid_completion_regex := RegEx.new()

func _init() -> void:
	process_mode = PROCESS_MODE_ALWAYS

func _ready() -> void:
	if not _console_enabled(): return
	for global_class: Dictionary in ProjectSettings.get_global_class_list():
		if global_class.base == "ConsoleCommands":
			var script: Script = load(global_class.path)
			var node: ConsoleCommands = script.new()
			node.name = global_class.class.to_snake_case().replace("_commands", "")
			add_child(node)

func run_command(command_string: String) -> Variant:
	if not _console_enabled(): return null
	var history_entry := HistoryEntry.new()
	history_entry.command = command_string
	var expression := Expression.new()
	var expression_context := _get_expression_context()
	if expression.parse(command_string, expression_context.keys()) == OK:
		var result := expression.execute(expression_context.values(), self, false)
		if typeof(result) == TYPE_CALLABLE and _can_run_without_args(result):
			result = result.call()
		if not expression.has_execute_failed():
			history_entry.result = result
			_prev_result = result
			command_executed.emit(history_entry)
			_command_history.push_front(history_entry)
			return result
	history_entry.result = expression.get_error_text()
	history_entry.error = true
	command_executed.emit(history_entry)
	_command_history.push_front(history_entry)
	return null

func _can_run_without_args(callable: Callable) -> bool:
	if not callable.is_valid(): return false
	if callable.is_standard():
		var object := callable.get_object()
		var method := callable.get_method()
		var method_info := Objects.get_method_info(object, method)
		if method_info:
			return callable.get_argument_count() == method_info.default_args.size()
	return callable.get_argument_count() == 0

func _get_expression_context() -> Dictionary[String, Variant]:
	var player := LocalPlayer.for_viewport(get_viewport())
	var controller := Controller.get_instigator(player)
	var context: Dictionary[String, Variant] = {
		"_": _prev_result,
		"_PLAYER": player,
		"_CONTROLLER": controller,
		"_AVATAR": controller.avatar if controller else null,
	}
	context.merge(_custom_context)
	for singleton: String in Engine.get_singleton_list():
		context[singleton] = Engine.get_singleton(singleton)
	for child: Node in get_children():
		if child is ConsoleCommands:
			if child._enabled():
				context[child.name] = child
				context.merge(child._context())
	return context

func _console_enabled() -> bool:
	return OS.has_feature("console") or OS.has_feature("debug")

func _unhandled_input(event: InputEvent) -> void:
	if _console_enabled() and event.is_action_pressed("console") and _console_ui_scene:
		if _active_ui:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and _active_ui:
		close()
		get_viewport().set_input_as_handled()

func open() -> void:
	if not _active_ui and _console_enabled():
		_active_ui = _console_ui_scene.instantiate()
		get_viewport().add_child(_active_ui)

func close() -> void:
	if _active_ui:
		_active_ui.queue_free()
		_active_ui = null

func get_completion_options(partial_text: String) -> PackedStringArray:
	var parts := partial_text.split(".")
	var expression_context := _get_expression_context()
	expression_context.merge(_get_object_completion_context(self))
	var context_object: Variant = self
	for i in range(parts.size()):
		var part := parts[i]
		if not part: return expression_context.keys() if i == parts.size() - 1 else PackedStringArray()
		context_object = expression_context.get(part, null)
		expression_context.clear()
		if context_object is Object:
			expression_context.assign(_get_object_completion_context(context_object))
	return expression_context.keys()

func _get_object_completion_context(object: Object) -> Dictionary[StringName, Variant]:
	var completion_context: Dictionary[StringName, Variant]
	for property_info: Dictionary in Objects.get_declared_property_list(object):
		if _valid_completion_regex.search(property_info.name) and not (property_info.usage & (PROPERTY_USAGE_INTERNAL | PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SUBGROUP)):
			completion_context[property_info.name] = object.get(property_info.name)
	for method_info: Dictionary in Objects.get_declared_method_list(object):
		if _valid_completion_regex.search(method_info.name):
			completion_context[method_info.name] = object.get(method_info.name)
	return completion_context

func _clear_immediate(erase_history: bool = false) -> void:
	if erase_history: _command_history.clear()
	history_cleared.emit()
	for entry: HistoryEntry in _command_history:
		entry.hidden = true

#region Root commands

func clear(erase_history: bool = false) -> void:
	_clear_immediate.call_deferred(erase_history)

func clear_settings() -> void:
	var err := DeviceSettings.delete_settings_overrides()
	if err != OK:
		push_error("Failed to delete settings (%s)" % error_string(err))

func list() -> String:
	return "\n".join([ConsoleCommands.default_help(self)] + get_children().map(func (item: Node): return "%s: ConsoleCommands" % item.name))

func history() -> Array[HistoryEntry]:
	return _command_history.duplicate()

func store(var_name: StringName, value: Variant = _prev_result) -> void:
	_custom_context[var_name] = value

func erase(var_name: StringName) -> void:
	_custom_context.erase(var_name)

func help(value: Variant = null) -> String:
	if value == null:
		return list()
	if value is Callable:
		if value.is_valid() and value.is_standard():
			return Objects.signature_string(Objects.get_method_info(value.get_object(), value.get_method()))
	if value is ConsoleCommands:
		return value._help()
	return ConsoleCommands.default_help(value)

func quit(exit_code: int = 0) -> void:
	get_tree().quit(exit_code)

#endregion

static func _static_init() -> void:
	var err := _valid_completion_regex.compile("(?i)^[a-z]")
	if err: push_error("Failed to compile completion regex (%s)" % error_string(err))

static func find_console(node: Node) -> DevConsole:
	if not node: return null
	if node is DevConsole: return node
	var viewport := node.get_viewport()
	if viewport:
		for child: Node in viewport.get_children():
			if child is DevConsole: return child
	var window := node.get_window()
	if window:
		for child: Node in window.get_children():
			if child is DevConsole: return child
	return null

class Command extends RefCounted:
	var run: Callable
	var arguments: Array[Dictionary]
	var default_arguments: Array[Variant]

class HistoryEntry extends RefCounted:
	var command: String
	var result: Variant
	var error: bool
	var hidden: bool

	func _to_string() -> String:
		return "HistoryEntry(command=%s, result=%s, error=%s)" % [command, result, error]
