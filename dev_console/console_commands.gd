class_name ConsoleCommands extends Node

func _context() -> Dictionary[String, Variant]:
	return {}

func _enabled() -> bool:
	return true

func _help() -> String:
	return default_help(self)

static func default_help(object: Object) -> String:
	if not object: return ""
	var filtered := Objects.get_declared_method_list(object).filter(
		func (method: Dictionary): return not method.name.begins_with("_")
	)
	filtered.sort_custom(Compare.using([Compare.property("name")]))
	return "\n".join(
		filtered.map(
			func (method: Dictionary): return Objects.signature_string(method)
		)
	)
