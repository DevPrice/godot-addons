@tool
class_name PlayerPlugin extends EditorPlugin

const SETTING_PLAYER_CONTROLLER_SCENE = "players/config/player_controller_scene"

func _enable_plugin() -> void:
	add_autoload_singleton("Players", "scenes/players.tscn")
	if not ProjectSettings.has_setting(SETTING_PLAYER_CONTROLLER_SCENE):
		ProjectSettings.set_setting(SETTING_PLAYER_CONTROLLER_SCENE, "uid://cosl2gcdqfe0x")
	ProjectSettings.set_initial_value(SETTING_PLAYER_CONTROLLER_SCENE, "uid://cosl2gcdqfe0x")
	ProjectSettings.add_property_info({
		"name": SETTING_PLAYER_CONTROLLER_SCENE,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tscn",
	})

func _disable_plugin() -> void:
	remove_autoload_singleton("Players")
