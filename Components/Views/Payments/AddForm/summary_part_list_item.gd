extends HBoxContainer

func populate(title: String, amount: float, currency: String):

	$Label.text = title;
	$Label2.text = str("%0.2f" % (amount / 100.0), ' ', currency);
	pass;
