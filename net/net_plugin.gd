@tool
class_name NetPlugin extends EditorPlugin

func _enable_plugin() -> void:
	add_autoload_singleton("Net", "net.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton("Net")
