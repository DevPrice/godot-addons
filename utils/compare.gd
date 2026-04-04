class_name Compare

static func using(comparators: Array[Callable]) -> Callable:
	return func (left: Variant, right: Variant) -> bool:
		var result: int = 0
		for comparator: Callable in comparators:
			result = comparator.call(left, right)
			if result != 0: break
		return result < 0

static func property(property_name: StringName, null_sort_type: NullSortType = NullSortType.NULLS_LAST) -> Callable:
	return selector(_get_property.bind(property_name), null_sort_type)

static func property_desending(property_name: StringName, null_sort_type: NullSortType = NullSortType.NULLS_LAST) -> Callable:
	return selector_descending(_get_property.bind(property_name), null_sort_type)

static func selector(selector: Callable, null_sort_type: NullSortType = NullSortType.NULLS_LAST) -> Callable:
	return func (left: Variant, right: Variant) -> int:
		return _values_by(left, right, selector, null_sort_type)

static func selector_descending(selector: Callable, null_sort_type: NullSortType = NullSortType.NULLS_LAST) -> Callable:
	return func (left: Variant, right: Variant) -> int:
		return -_values_by(left, right, selector, null_sort_type)

static func _values_by(left: Variant, right: Variant, selector: Callable, null_sort_type: NullSortType = NullSortType.NULLS_LAST) -> int:
	var l_value = selector.call(left)
	var r_value = selector.call(right)

	if (l_value == r_value): return 0
	if (l_value == null): return null_sort_type
	if (r_value == null): return -null_sort_type

	return 1 if l_value > r_value else -1

static func _get_property(item: Variant, property_name: StringName) -> Variant:
	return item.get(property_name) if item else null

enum NullSortType {
	NULLS_FIRST = -1,
	NULLS_LAST = 1,
}
