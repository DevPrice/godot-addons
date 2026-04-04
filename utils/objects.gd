class_name Objects

static func property_info_to_string(property_info: Dictionary) -> String:
	if property_info.get("type", TYPE_NIL) == TYPE_NIL:
		return "Variant"
	var name = property_info.get("class_name", null)
	if name: return name
	return type_string(property_info.get("type", TYPE_NIL))

static func return_type_to_string(return_type: Dictionary) -> String:
	if return_type.get("type", TYPE_NIL) == TYPE_NIL:
		return "void"
	return property_info_to_string(return_type)

static func signature_string(method_info: Dictionary) -> String:
	var args: Array = method_info.args.map(
		func (arg: Dictionary):
			# TODO: Show default value
			return "%s: %s" % [arg.name, Objects.property_info_to_string(arg)]
	)
	return "%s(%s) -> %s" % [method_info.name, ", ".join(args), Objects.return_type_to_string(method_info.return)]

static func get_method_info(object: Object, method: StringName) -> Dictionary:
	for method_info: Dictionary in object.get_method_list():
		if method == method_info.name:
			return method_info
	return {}

static func info_list_to_dict(list: Array[Dictionary]) -> Dictionary[StringName, Dictionary]:
	var dict: Dictionary[StringName, Dictionary]
	for info: Dictionary in list:
		dict[info.name] = info
	return dict

static func get_property_dict(object: Object) -> Dictionary[StringName, Dictionary]:
	if not object: return {}
	return info_list_to_dict(object.get_property_list())

static func get_method_dict(object: Object) -> Dictionary[StringName, Dictionary]:
	if not object: return {}
	return info_list_to_dict(object.get_method_list())

static func get_inherited_properties(object: Object) -> Array[StringName]:
	if not object: return []
	var script: Script = object.get_script()
	var inherited_properties: Array[StringName]
	var parent_class := ClassDB.get_parent_class(object.get_class())
	if parent_class:
		for property: Dictionary in ClassDB.class_get_property_list(parent_class):
			inherited_properties.push_back(property.name)
	var base_script: Script = script.get_base_script() if script else null
	if base_script:
		for property: Dictionary in base_script.get_script_property_list():
			inherited_properties.push_back(property.name)
	return inherited_properties

static func get_inherited_methods(object: Object) -> Array[StringName]:
	if not object: return []
	var script: Script = object.get_script()
	var inherited_methods: Array[StringName]
	var parent_class := ClassDB.get_parent_class(object.get_class())
	if parent_class:
		for method_info: Dictionary in ClassDB.class_get_method_list(parent_class):
			inherited_methods.push_back(method_info.name)
	var base_script: Script = script.get_base_script() if script else null
	if base_script:
		for method_info: Dictionary in base_script.get_script_method_list():
			inherited_methods.push_back(method_info.name)
	return inherited_methods

static func get_declared_property_list(object: Object) -> Array[Dictionary]:
	if not object: return []
	var property_list: Array[Dictionary]
	var script: Script = object.get_script()
	if script:
		var inherited_properties: Dictionary[StringName, bool]
		for property: StringName in get_inherited_properties(object):
			inherited_properties[property] = true
		var script_properties: Dictionary[StringName, bool]
		for property_info: Dictionary in script.get_script_property_list():
			if not inherited_properties.has(property_info.name):
				script_properties[property_info.name] = true
		for property_info: Dictionary in object.get_property_list():
			if script_properties.has(property_info.name) and not inherited_properties.has(property_info.name):
				property_list.push_back(property_info)
	else:
		# TODO: Needs to call instance method and filter
		return ClassDB.class_get_property_list(object.get_class(), true)
	return property_list

static func get_declared_method_list(object: Object) -> Array[Dictionary]:
	if not object: return []
	var method_list: Array[Dictionary]
	var script: Script = object.get_script()
	if script:
		var inherited_methods: Dictionary[StringName, bool]
		for method: StringName in get_inherited_methods(object):
			inherited_methods[method] = true
		var script_methods: Dictionary[StringName, bool]
		for method_info: Dictionary in script.get_script_method_list():
			if not inherited_methods.has(method_info.name):
				script_methods[method_info.name] = true
		for method_info: Dictionary in object.get_method_list():
			if script_methods.has(method_info.name) and not inherited_methods.has(method_info.name):
				method_list.push_back(method_info)
	else:
		# TODO: Needs to call instance method and filter
		return ClassDB.class_get_method_list(object.get_class(), true)
	return method_list
