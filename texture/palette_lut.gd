@tool class_name PaletteLUT extends Texture3D

@export_range(1, 128, 1) var depth: int = 32:
	set(value):
		if value == depth: return
		depth = value
		_data_dirty = true
		_queue_update()
@export var palette: PackedColorArray:
	set(value):
		palette = value
		_data_dirty = true
		_queue_update()

@export_storage var _data: Array[Image]:
	set(value):
		_data_dirty = false
		_data = value

var _data_dirty: bool = true
var _updated_queued: bool = false
var _regen_queued: bool = false
var _texture_rid: RID

func _get_data() -> Array[Image]:
	return _data

func _get_format() -> Image.Format:
	return Image.FORMAT_RGB8

func _get_depth() -> int:
	return depth

func _get_width() -> int:
	return depth

func _get_height() -> int:
	return depth

func _has_mipmaps() -> bool:
	return false

func _get_rid() -> RID:
	_get_data()
	if not _texture_rid.is_valid():
		_texture_rid = RenderingServer.texture_3d_placeholder_create()
	return _texture_rid

func _queue_update() -> void:
	if _updated_queued: return
	_updated_queued = true
	_update_texture.call_deferred()

func _update_texture() -> void:
	var image := _generate_texture()
	_update_texture_from_image.call_deferred(image)
	_updated_queued = false

func _generate_texture() -> Array[Image]:
	if not _data_dirty: return _data
	var new_data: Array[Image]
	new_data.resize(depth)
	var size := maxf(1.0, float(depth) - 1.0)
	var offset := .5 / size
	for b: int in range(depth):
		var image := Image.create_empty(depth, depth, has_mipmaps(), get_format())
		new_data[b] = image
		for g: int in range(depth):
			for r: int in range(depth):
				var color := Color(r / size, g / size, b / size)
				var palette_color := _get_palette_color(color)
				image.set_pixel(r, g, palette_color)
	_data_dirty = false
	return new_data

func _update_texture_from_image(image: Array[Image]) -> void:
	_data = image
	if image.is_empty(): return
	var new_texture: RID = create_placeholder() if image.is_empty() else RenderingServer.texture_3d_create(_get_format(), get_width(), get_height(), get_depth(), has_mipmaps(), image)
	if _texture_rid.is_valid():
		RenderingServer.texture_replace(_texture_rid, new_texture)
	else:
		_texture_rid = new_texture
	RenderingServer.texture_set_path(_texture_rid, get_path())
	emit_changed()

func _get_palette_color(color: Color) -> Color:
	if palette.is_empty():
		return color

	var nearest_color := palette[0]
	var nearest_distance := _get_perceptual_distance(color, palette[0])

	for i: int in range(1, palette.size()):
		var distance := _get_perceptual_distance(color, palette[i])
		if distance < nearest_distance:
			nearest_color = palette[i]
			nearest_distance = distance

	return nearest_color

func _get_perceptual_distance(left: Color, right: Color) -> float:
	return Vector3(left.ok_hsl_h, left.ok_hsl_l, left.ok_hsl_s).distance_to(Vector3(right.ok_hsl_h, right.ok_hsl_l, right.ok_hsl_s))
