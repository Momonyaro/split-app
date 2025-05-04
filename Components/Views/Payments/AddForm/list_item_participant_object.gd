extends PanelContainer

func populate(participant: SQLPaymentUtils.LineItemParticipant, contact: SQLContactsUtils.Contact, currency: String, is_current_participant: bool):
	var constraint_panel = get_constraint_panel()
	var has_constraint = participant.has_fixed_amount_or_percentage();

	constraint_panel.visible = has_constraint;
	$HBoxContainer/AvatarBox/Button.flat = !is_current_participant;
	if participant.has_fixed_amount():
		constraint_panel.get_child(0).text = str(participant.fixed_amount_cents / 100.0, ' ', currency);
	elif participant.has_fixed_percentage():
		constraint_panel.get_child(0).text = str(participant.fixed_amount_percentage, '%');

	if contact.img_avatar != null:
		get_avatar_panel().get_child(0).texture = ImageTexture.create_from_image(contact.get_avatar());
	else:
		var default_avatar = ImageUtils.get_default_avatar(contact, ImageUtils.AvatarSize.SMALL);
		get_avatar_panel().add_child(default_avatar);
		get_avatar_panel().move_child(default_avatar, 1);
	pass;

func get_constraint_panel() -> PanelContainer:
	return $HBoxContainer/ConstraintBox;

func get_avatar_panel() -> PanelContainer:
	return $HBoxContainer/AvatarBox;
