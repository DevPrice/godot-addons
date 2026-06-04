## Creates a color correction look-up-table from a list of colors.
## Can be used directly with the [WorldEnvironment]'s [member Environment.adjustment_color_correction] property
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
var _current_task_id: int = -1
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
	if _current_task_id == -1:
		_start_thread()
		_regen_queued = false
	else:
		_regen_queued = true
	_updated_queued = false

func _generate_texture(p_palette: PackedColorArray, p_depth: int) -> Array[Image]:
	if not _data_dirty: return _data
	var new_data: Array[Image]
	new_data.resize(p_depth)
	var size := maxf(1.0, float(p_depth) - 1.0)
	var offset := .5 / size
	for b: int in range(p_depth):
		var image := Image.create_empty(p_depth, p_depth, has_mipmaps(), get_format())
		new_data[b] = image
		for g: int in range(p_depth):
			# cancel if a new task was scheduled
			if _regen_queued:
				return _data
			for r: int in range(p_depth):
				var color := Color(r / size, g / size, b / size)
				var palette_color := _get_palette_color(p_palette, color)
				image.set_pixel(r, g, palette_color)
	return new_data

func _update_texture_from_image(image: Array[Image], size: Vector3i) -> void:
	if _data == image: return
	_data = image
	if image.is_empty(): return
	var new_texture: RID = RenderingServer.texture_3d_create(_get_format(), size.x, size.y, size.z, has_mipmaps(), image)
	if _texture_rid.is_valid():
		RenderingServer.texture_replace(_texture_rid, new_texture)
	else:
		_texture_rid = new_texture
	RenderingServer.texture_set_path(_texture_rid, get_path())
	emit_changed()

func _start_thread() -> void:
	_current_task_id = WorkerThreadPool.add_task(_thread_function.bind(palette, depth), false, "PaletteLUT generation")

func _thread_function(p_palette: PackedColorArray, p_depth: int) -> void:
	_thread_finished.call_deferred(_generate_texture(p_palette, p_depth), Vector3i(p_depth, p_depth, p_depth))

func _thread_finished(image: Array[Image], size: Vector3i) -> void:
	if _current_task_id != -1:
		WorkerThreadPool.wait_for_task_completion(_current_task_id)
		_current_task_id = -1
	_update_texture_from_image(image, size)
	if _regen_queued:
		_data_dirty = true
		_regen_queued = false
		_start_thread()

func _get_palette_color(p_palette: PackedColorArray, color: Color) -> Color:
	if p_palette.is_empty():
		return color

	var nearest_color := p_palette[0]
	var nearest_distance := _get_perceptual_distance(color, p_palette[0])

	for i: int in range(1, p_palette.size()):
		var distance := _get_perceptual_distance(color, p_palette[i])
		if distance < nearest_distance:
			nearest_color = p_palette[i]
			nearest_distance = distance

	return nearest_color

func _get_perceptual_distance(left: Color, right: Color) -> float:
	return Vector3(left.ok_hsl_h, left.ok_hsl_l, left.ok_hsl_s).distance_to(Vector3(right.ok_hsl_h, right.ok_hsl_l, right.ok_hsl_s))
