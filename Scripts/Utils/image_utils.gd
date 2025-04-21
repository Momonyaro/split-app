class_name ImageUtils;

# FILE FORMAT MAGIC CONSTANTS:
const MAGIC_PNG  := "89504E47";
const MAGIC_JPG  := "FFD8FFE0";
const MAGIC_JPEG  := "FFD8FFE1";

static func _file_data_to_image(file_data: PackedByteArray) -> Image:
	if file_data.size() == 0:
		push_error("File is empty.");
		return null;

	var img := Image.new();

	# Check magic bytes for image type!
	var magic_sample = file_data.slice(0, 4).hex_encode().to_upper();
	match magic_sample:
		MAGIC_JPG, MAGIC_JPEG:
			img.load_jpg_from_buffer(file_data);
			var temp_buffer = img.save_png_to_buffer();
			img.load_png_from_buffer(temp_buffer);
		MAGIC_PNG:
			img.load_png_from_buffer(file_data);

	if img.get_data().size() == 0:
		push_error("File is not an image.");
		return null;

	var img_size = img.get_size();
	var img_aspect = img_size.x / float(img_size.y)
	var new_width = img_size.x
	var new_height = img_size.y
	var thmb_aspect = 1;
	var x_offset = 0
	var y_offset = 0

	# Correct for aspect ratio
	if img_aspect > thmb_aspect:
		# Then crop the left and right edges:
		new_width = int(thmb_aspect * new_height)
		x_offset = roundi((img_size.x - new_width) / 2.0)
	else:
		# ... crop the top and bottom:
		new_height = int(new_width / thmb_aspect)
		y_offset = roundi((img_size.y - new_height) / 2.0)

	var atlas = Image.create(new_width, new_height, false, img.get_format());
	atlas.blit_rect(img, Rect2(Vector2.ZERO, img_size), Vector2i() - Vector2i(x_offset, y_offset));
	atlas.resize(256, 256);

	return atlas;

static func pack_img_data(img: Image) -> PackedByteArray:
	return PackedByteArray([img.get_format()]) + img.get_data();
