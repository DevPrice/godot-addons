class_name DeviceSettings

static var _pending_settings: Dictionary[String, Variant]

static func get_device_settings_path() -> String:
	return ProjectSettings.get_setting_with_override("application/config/project_settings_override")

static func get_renderer() -> Renderer:
	match ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method"):
		"forward_plus": return Renderer.FORWARD_PLUS
		"mobile": return Renderer.MOBILE
		_: return Renderer.COMPATIBILITY

static func store_setting(setting_path: String, value: Variant) -> void:
	if _pending_settings.is_empty(): _flush_unhandled.call_deferred()
	_pending_settings[setting_path] = value

static func store_settings(settings: Dictionary[String, Variant]) -> void:
	if settings.is_empty(): return
	if _pending_settings.is_empty(): _flush_unhandled.call_deferred()
	_pending_settings.merge(settings, true)

## Flush any pending settings changes to disk
## This happens automatically at the end of each frame
static func flush() -> Error:
	var flushed_settings := _pending_settings.duplicate()
	_pending_settings.clear()
	if flushed_settings.is_empty(): return OK

	var config_file := ConfigFile.new()
	var load_err := config_file.load(get_device_settings_path())
	if load_err and load_err != ERR_FILE_NOT_FOUND:
		return load_err

	for setting_path: String in flushed_settings:
		var value: Variant = flushed_settings[setting_path]
		var parts := setting_path.split("/")
		assert(parts.size() > 1, "Invalid setting path %s!" % setting_path)
		config_file.set_value(parts[0], "/".join(parts.slice(1)), value)
		ProjectSettings.set(setting_path, value)

	return config_file.save(get_device_settings_path())

static func _flush_unhandled() -> void:
	var err := flush()
	if err: push_error("Failed to flush settings! (%s)" % error_string(err))

static func delete_settings(property_paths: PackedStringArray) -> Error:
	var config_file := ConfigFile.new()
	var load_err := config_file.load(get_device_settings_path())
	if load_err == ERR_FILE_NOT_FOUND: return OK
	if load_err != OK: return load_err

	for path: String in property_paths:
		var section_separator := path.find("/")
		if section_separator == -1:
			if config_file.has_section(path):
				config_file.erase_section(path)
		else:
			var section := path.left(section_separator)
			var key := path.substr(section_separator + 1)
			if config_file.has_section_key(section, key):
				config_file.erase_section_key(section, key)

	return config_file.load(get_device_settings_path())

static func delete_settings_overrides() -> Error:
	var settings_path := get_device_settings_path()
	if FileAccess.file_exists(settings_path):
		return DirAccess.remove_absolute(settings_path)
	return OK

enum Renderer {
	FORWARD_PLUS,
	MOBILE,
	COMPATIBILITY,
}
