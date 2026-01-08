extends CheckBox

var group_name: String = ""


func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview: Label = Label.new()
	preview.text = "   " + text
	set_drag_preview(preview)
	return str("{!", group_name, ":", text, "}")
