class_name ConfigMenu extends Node

signal dirty_changed(is_dirty: bool)
signal committed

@export var commit_on_change: bool = true

var _original_configs: Dictionary[StringName, Variant]
var _changed_configs: Dictionary[StringName, Variant]
var _bind_functions: Dictionary[StringName, Callable]
var _config_nodes: Dictionary[StringName, Control]

var _dirty: bool = false:
	set(value):
		if _dirty != value:
			_dirty = value
			dirty_changed.emit(value)

func _enter_tree() -> void:
	property_list_changed.connect(_property_list_changed)
	_property_list_changed()

func _exit_tree() -> void:
	property_list_changed.disconnect(_property_list_changed)
	revert_pending_changes()

func _property_can_revert(property: StringName) -> bool:
	return _original_configs.has(property)

func _property_get_revert(property: StringName) -> Variant:
	return _original_configs.get(property)

func _property_list_changed() -> void:
	var property_dict := Objects.info_list_to_dict(_get_config_list())
	for property: StringName in property_dict:
		var property_info: Dictionary = property_dict[property]
		if not _config_nodes.has(property):
			var control := _create_config(property_info)
			if control:
				control.tree_entered.connect(func (): _config_nodes[property_info.name] = control, CONNECT_ONE_SHOT)
				control.tree_exiting.connect(func (): _config_nodes.erase(property_info.name), CONNECT_ONE_SHOT)
				add_child.call_deferred(control)
		if _config_nodes.has(property) and not (property_info.usage & (PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SUBGROUP)):
			var config_node := _config_nodes[property]
			config_node.visible = property_info.usage & PROPERTY_USAGE_EDITOR
			config_node.tooltip_text = _get_tooltip_text(property_info.name)
		if _bind_functions.has(property):
			_bind_functions[property].call(property_info)
	for property: StringName in _config_nodes:
		if not property_dict.has(property):
			var node := _config_nodes[property]
			node.queue_free()

func _get_settings_registry() -> Object:
	return ProjectSettings

func _get_config_list() -> Array[Dictionary]:
	return Objects.get_declared_property_list(self)

func _get_display_name(config: StringName) -> String:
	return config.capitalize()

func _get_tooltip_text(config: StringName) -> String:
	return ""

func _commit() -> void:
	pass

func _config_changed(config: StringName, value: Variant) -> void:
	pass

func get_key_binding(action: StringName) -> InputEventKey:
	var events := InputMap.action_get_events(action).filter(func (ev: InputEvent): return ev is InputEventKey)
	if events.is_empty(): return null
	return events[0]

func get_joy_binding(action: StringName) -> InputEventKey:
	var events := InputMap.action_get_events(action).filter(func (ev: InputEvent): return ev is InputEventJoypadButton)
	if events.is_empty(): return null
	return events[0]

func store_action_binding(action: StringName, binding: InputEvent) -> void:
	for ev: InputEvent in InputMap.action_get_events(action):
		# TODO: Need to figure out robustly which events were player-bound to remove/replace
		# This, for example, doesn't allow using mouse button buttons on KBM controls.
		if ev.get_class() == binding.get_class():
			InputMap.action_erase_event(action, ev)
	InputMap.action_add_event(action, binding)
	DeviceSettings.store_setting("input/%s" % action, {
		"deadzone": InputMap.action_get_deadzone(action),
		"events": InputMap.action_get_events(action),
	})

func is_pending(property: StringName) -> bool:
	return _changed_configs.has(property)

func get_pending_value(property: StringName) -> Variant:
	if _changed_configs.has(property): return _changed_configs[property]
	return get(property)

func set_pending_value(property: StringName, value: Variant) -> void:
	if value == get(property):
		_original_configs.erase(property)
		_changed_configs.erase(property)
	else:
		if not _original_configs.has(property):
			_original_configs[property] = get(property)
		_changed_configs[property] = value
	_config_changed(property, value)
	if not commit_on_change:
		_dirty = has_uncommitted_changes()

func get_pending_changes() -> Dictionary:
	return _changed_configs.duplicate()

func has_uncommitted_changes() -> bool:
	return not _changed_configs.is_empty()

func revert_config(config: StringName) -> void:
	if _property_can_revert(config):
		_config_changed(config, _property_get_revert(config))
		_original_configs.erase(config)
		_changed_configs.erase(config)
		_dirty = has_uncommitted_changes()
		_property_list_changed()

func revert_pending_changes() -> void:
	for config: StringName in _original_configs:
		_config_changed(config, _original_configs[config])
	_original_configs.clear()
	_changed_configs.clear()
	_dirty = false
	_property_list_changed()

func commit() -> void:
	if not has_uncommitted_changes(): return
	var changed_configs := _changed_configs.duplicate()
	while not changed_configs.is_empty():
		_changed_configs.clear()
		for property: StringName in changed_configs:
			var value: Variant = changed_configs[property]
			set(property, value)
			_config_changed(property, value)
		changed_configs = _changed_configs.duplicate()
	_commit()
	_original_configs.clear()
	_changed_configs.clear()
	_dirty = false
	committed.emit()
	_property_list_changed()

func _create_config(property_info: Dictionary) -> Control:
	if property_info.usage & PROPERTY_USAGE_CATEGORY: return null
	if property_info.usage & PROPERTY_USAGE_GROUP or property_info.usage & PROPERTY_USAGE_SUBGROUP:
		return _create_header(property_info)

	var label := _create_label(property_info)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var container := _create_container(property_info)
	var heading := _create_header(property_info)
	container.add_child(heading)
	var knob := _create_knob(property_info)
	if knob:
		knob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(knob)
	return container

func _create_container(property_info: Dictionary) -> Control:
	var container := GridContainer.new()
	container.columns = 2
	container.tooltip_text = _get_tooltip_text(property_info.name)
	container.visible = property_info.usage & PROPERTY_USAGE_EDITOR
	return container

func _create_label(property_info: Dictionary) -> Control:
	var label := Label.new()
	label.text = _get_display_name(property_info.name)
	return label

func _create_header(property_info: Dictionary) -> Control:
	var label := _create_label(property_info)
	label.theme_type_variation = "HeaderSmall" if property_info.usage & PROPERTY_USAGE_SUBGROUP else "HeaderMedium"
	return label

func _create_knob(property_info: Dictionary) -> Control:
	match property_info.type:
		TYPE_OBJECT when ClassDB.is_parent_class(property_info.class_name, &"InputEvent"):
			var button := InputEventSelector.new()
			_bind_functions[property_info.name] = _bind_input_event_selector.bind(button)
			button.value_changed.connect(_on_config_edited.bind(property_info.name))
			return button
		TYPE_BOOL:
			var button := CheckButton.new()
			_bind_functions[property_info.name] = _bind_check_button.bind(button)
			button.toggled.connect(_on_config_edited.bind(property_info.name))
			return button
		TYPE_FLOAT:
			var spin_box := SpinBox.new()
			_bind_functions[property_info.name] = _bind_spin_box.bind(spin_box)
			spin_box.value_changed.connect(_on_config_edited.bind(property_info.name))
			var slider := HSlider.new()
			slider.mouse_force_pass_scroll_events = false
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slider.size_flags_vertical = Control.SIZE_EXPAND_FILL
			spin_box.share(slider)
			var container := HBoxContainer.new()
			container.add_child(slider)
			container.add_child(spin_box)
			return container
		TYPE_INT when property_info.hint == PROPERTY_HINT_ENUM:
			var option_button := OptionButton.new()
			_bind_functions[property_info.name] = _bind_option_button.bind(option_button)
			option_button.item_selected.connect(
				func (i: int) -> void:
					_on_config_edited(option_button.get_item_id(i), property_info.name)
			)
			return option_button
		TYPE_INT:
			var spin_box := SpinBox.new()
			_bind_functions[property_info.name] = _bind_spin_box.bind(spin_box)
			spin_box.value_changed.connect(_on_config_edited.bind(property_info.name))
			return spin_box
		TYPE_CALLABLE:
			var button := Button.new()
			_bind_functions[property_info.name] = _bind_button.bind(button)
			button.pressed.connect(get_pending_value(property_info.name))
			return button
		_:
			push_warning("Unhandled config type: %s" % property_info.get("class_name", type_string(property_info.type)))
			return null

func _bind_input_event_selector(property_info: Dictionary, input_selector: InputEventSelector) -> void:
	input_selector.value = get_pending_value(property_info.name)
	input_selector.disabled = property_info.usage & PROPERTY_USAGE_READ_ONLY
	input_selector.class_filter = PackedStringArray([property_info.class_name])

func _bind_option_button(property_info: Dictionary, option_button: OptionButton) -> void:
	var items: PackedStringArray = property_info.hint_string.split(',')
	var i := -1
	option_button.clear()
	for item_label: String in items:
		var parts := item_label.split(":")
		if parts.size() > 1:
			i = int(parts[1])
		else:
			i += 1
		option_button.add_item(parts[0], i)
	option_button.disabled = property_info.usage & PROPERTY_USAGE_READ_ONLY
	var index := option_button.get_item_index(get_pending_value(property_info.name))
	option_button.select(index)

func _bind_check_button(property_info: Dictionary, check_button: Button) -> void:
	check_button.text = "Enabled"
	check_button.button_pressed = get_pending_value(property_info.name)
	check_button.disabled = property_info.usage & PROPERTY_USAGE_READ_ONLY

func _bind_button(property_info: Dictionary, button: Button) -> void:
	button.text = property_info.hint_string if property_info.hint == PROPERTY_HINT_TOOL_BUTTON else ""
	button.disabled = property_info.usage & PROPERTY_USAGE_READ_ONLY

func _bind_spin_box(property_info: Dictionary, spin_box: SpinBox) -> void:
	if property_info.hint == PROPERTY_HINT_RANGE:
		var parts: PackedStringArray = property_info.hint_string.split(",")
		spin_box.min_value = float(parts[0])
		spin_box.max_value = float(parts[1])
		if parts.size() > 2: spin_box.step = float(parts[2])
		for i: int in range(3, parts.size()):
			var part := parts[i]
			if part.begins_with("prefix:"):
				spin_box.prefix = part.trim_prefix("prefix:")
			elif part.begins_with("suffix:"):
				spin_box.suffix = part.trim_prefix("suffix:")
		spin_box.allow_lesser = parts.has("allow_lesser")
		spin_box.allow_greater = parts.has("allow_greater")
	spin_box.editable = not (property_info.usage & PROPERTY_USAGE_READ_ONLY)
	spin_box.set_value_no_signal(get_pending_value(property_info.name))

func _on_config_edited(value: Variant, property: StringName) -> void:
	set_pending_value(property, value)
	if commit_on_change:
		commit()
	else:
		_property_list_changed()
