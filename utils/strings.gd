class_name Strings extends Node

static func format_int(n: int) -> String:
	var s := str(abs(n))
	var out := ""
	var count := 0
	for i: int in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i != 0:
			out = "," + out
	if n < 0:
		out = "-" + out
	return out

static func format_separators(x: float, format_specifier: String = "%0.2f") -> String:
	var formatted := format_specifier % x
	var sign := "-" if formatted.begins_with("-") else ""
	var parts := formatted.trim_prefix("-").split(".")
	var result := ""
	var left := parts[0]
	var length := left.length()
	for i: int in range(length - 1, -1, -1):
		var c := left[i]
		result = c + result
		var i2 := length - i - 1
		if i2 != 0 and i2 % 3 == 2 and i != 0:
			result = "," + result
	result = sign + result
	if parts.size() > 1:
		result = result + "." + parts[1]
	return result

static func scientific(x: float, sig_figs: int = 4) -> String:
	var raw := String.num_scientific(x)
	if not raw.contains("."): return Strings.format_separators(x, _format_specifier(0, sig_figs))
	var parts := raw.split("e")
	if parts.size() < 2: return Strings.format_separators(x, _format_specifier(0, sig_figs))
	return parts[0].substr(0, sig_figs + 1) + "e" + parts[1]

static func _format_specifier(padding: int, sig_figs: int) -> String:
	return "%%%d.%df" % [padding, sig_figs]
