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
			scale_img_to_fit_bounds(img, 1024, 1024);
			var temp_buffer = img.save_png_to_buffer();
			img.load_png_from_buffer(temp_buffer);
		MAGIC_PNG:
			img.load_png_from_buffer(file_data);
			scale_img_to_fit_bounds(img, 1024, 1024);

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

static func scale_img_to_fit_bounds(img: Image, max_width: int, max_height: int):
	var img_size = img.get_size();

	while (img_size.x > max_width || img_size.y > max_height):
		img_size *= 0.5;

	img.resize(img_size.x, img_size.y);

static func string_to_hsl_color(input: String, saturation: float, lightness: float) -> Color:
	var byte_buffer = input.to_utf8_buffer();
	while (byte_buffer.size() % 4) != 0:
		byte_buffer.append(0);

	var to_int = Array(byte_buffer.to_int32_array());
	var hashed = to_int.reduce(func(accum, number): return accum + number, 0);

	var h = (hashed % 360) / 360.0;
	var resulting = Color.from_hsv(h, saturation / 100, lightness / 100);
	return resulting;

static func get_default_avatar(contact: SQLContactsUtils.Contact, size: AvatarSize) -> ColorRect:
	var panel = ColorRect.new();
	var bg_col = string_to_hsl_color(contact.get_name(), 40, 40);
	panel.color = bg_col;

	if contact.deleted:
		var margin_container = MarginContainer.new();
		panel.add_child(margin_container);
		margin_container.set_anchors_preset(Control.PRESET_FULL_RECT);
		margin_container.add_theme_constant_override("margin_left", 16);
		margin_container.add_theme_constant_override("margin_right", 16);
		margin_container.add_theme_constant_override("margin_top", 16);
		margin_container.add_theme_constant_override("margin_bottom", 16);

		var texture_rect = TextureRect.new();
		texture_rect.texture = ResourceLoader.load("res://Media/Icons/ghost-svgrepo-com.svg");
		margin_container.add_child(texture_rect);

		texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT);
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;
	else:
		var label = Label.new();
		label.text = str(contact.name_given[0], contact.name_family[0]);
		panel.add_child(label);

		label.set_anchors_preset(Control.PRESET_FULL_RECT);
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER;

		label.label_settings = LabelSettings.new();

		match size:
			AvatarSize.SMALL: label.label_settings.font_size = 24;
			AvatarSize.MEDIUM: label.label_settings.font_size = 32;
			AvatarSize.LARGE: label.label_settings.font_size = 64;

	return panel;

enum AvatarSize {SMALL, MEDIUM, LARGE}
