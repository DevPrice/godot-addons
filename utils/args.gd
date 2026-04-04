class_name Args

static var _args: Dictionary[String, Variant] = {}

static func get_cmd_args() -> Dictionary[String, Variant]:
	if _args.is_empty():
		var args_array := OS.get_cmdline_user_args()
		for arg in args_array:
			var kv := arg.trim_prefix("--").split("=")
			if kv.size() == 2:
				var key := kv[0]
				_args[key] = kv[1]
			elif not kv.is_empty():
				_args[kv[0]] = true
		if OS.has_feature("web"):
			var url_search: String = JavaScriptBridge.eval("window.location.search")
			var query_param_array := url_search.trim_prefix("?").split("&")
			for arg in query_param_array:
				var kv := arg.trim_prefix("--").split("=")
				if kv.size() == 2:
					var key := kv[0]
					_args[key] = kv[1]
				elif not kv.is_empty():
					_args[kv[0]] = true
	return _args
