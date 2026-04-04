class_name Url extends Object

static func parse(url_string: String) -> Dictionary[String, Variant]:
	var host := ""
	var port: int = 0
	
	url_string = url_string.strip_edges()
	
	if url_string.begins_with("["):
		# IPv6 with brackets
		var close_idx = url_string.find("]")
		if close_idx == -1:
			push_error("Invalid IPv6 format: missing closing bracket")
			return {}
		host = url_string.substr(1, close_idx - 1)
		if close_idx + 1 < url_string.length() and url_string[close_idx + 1] == ":":
			port = int(url_string.substr(close_idx + 2))
	elif url_string.count(":") > 1:
		# Likely bare IPv6 (multiple colons)
		var last_colon = url_string.rfind(":")
		var possible_port = url_string.substr(last_colon + 1)
		if possible_port.is_valid_int():
			host = url_string.substr(0, last_colon)
			port = int(possible_port)
		else:
			host = url_string
	else:
		# IPv4 or hostname
		var parts = url_string.rsplit(":", false, 1)
		host = parts[0]
		if parts.size() > 1:
			port = int(parts[1])

	if port:
		return {"host": host, "port": port}
	return {"host": host}
