@tool
class_name ConsolePlugin extends EditorPlugin

func _enable_plugin() -> void:
	add_autoload_singleton("Console", "dev_console.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton("Console")
