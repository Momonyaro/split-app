extends PanelContainer

func populate(participants: Array, selected_id: String, select_callback: Callable):
	get_header().text = str("Participants (", participants.size(), ")");

	var list_parent = get_list_parent();

	for child in list_parent.get_children():
		list_parent.remove_child(child);

	for participant in participants:
		var contact_obj = SQL.contact_utils.get_contact_by_id(participant.contact_id);
		var panel_container = PanelContainer.new();
		panel_container.clip_children = true;
		panel_container.custom_minimum_size = Vector2(56, 56);

		var stylebox_flat = StyleBoxFlat.new();
		stylebox_flat.bg_color = Color(0, 0, 0);
		stylebox_flat.set_corner_radius_all(8);

		panel_container.add_theme_stylebox_override("panel", stylebox_flat);

		if contact_obj.img_avatar == null:
			panel_container.add_child(ImageUtils.get_default_avatar(contact_obj, ImageUtils.AvatarSize.SMALL));
		else:
			var avatar_rect = TextureRect.new();
			avatar_rect.texture = ImageTexture.create_from_image(contact_obj.get_avatar());
			avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;
			panel_container.add_child(avatar_rect);

		var button = Button.new();
		button.pressed.connect(func():
			select_callback.call(participant.id);
		);

		if participant.id == selected_id:
			button.theme_type_variation = &"ParticipantButton";
		else:
			button.flat = true;

		panel_container.add_child(button);
		list_parent.add_child(panel_container);

	pass;

func get_header():
	return $VBoxContainer/Label;

func get_list_parent():
	return $VBoxContainer/ScrollContainer/HBoxContainer;
