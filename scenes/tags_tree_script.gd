class_name RollTagTree
extends Tree


signal item_rerolled(from_category: StringName, id: StringName, item: TreeItem)


func _ready() -> void:
	create_item()
	button_clicked.connect(_on_button_clicked)


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == 0:
		item_rerolled.emit(item.get_metadata(0)["category"], item.get_metadata(0)["id"], item)


func add_tag(tag_text: String, id: StringName, category: StringName) -> void:
	var new_item: TreeItem = get_root().create_child()
	new_item.set_text(0, tag_text)
	new_item.set_metadata(0, {"id": id, "category": category})
	new_item.add_button(
			0,
			preload("res://icons/refresh_icon.svg"),
			0,
			false,
			"Reroll tag")


func get_tags() -> Array[String]:
	var tags: Array[String] = []
	for item in get_root().get_children():
		tags.append(item.get_text(0))
	return tags


func get_tag_ids() -> Array[StringName]:
	var strs: Array[StringName] = []
	for item in get_root().get_children():
		strs.append(item.get_metadata(0)["id"])
	return strs


func clear_tags() -> void:
	for item in get_root().get_children():
		item.free()
