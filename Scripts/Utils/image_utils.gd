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
		MAGIC_JPG, MAGIC_JPG:
			img.load_jpg_from_buffer(file_data);
		MAGIC_PNG:
			img.load_png_from_buffer(file_data);

	if img.get_data().size() == 0:
		push_error("File is not an image.");
		return null;

	return img;
