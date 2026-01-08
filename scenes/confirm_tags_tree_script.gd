extends Tree


var root: TreeItem = null


func _ready() -> void:
	set_column_title(0, "Tag")
	set_column_title(1, "Spiciness")
	set_column_title(2, "NSFW")
	
	button_clicked.connect(_on_button_clicked)


func set_tags(tags: Array[String]) -> void:
	if root != null:
		root.free()
		root = create_item()
	else:
		root = create_item()
	
	for item in tags:
		var new_item: TreeItem = root.create_child()
		new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
		new_item.set_cell_mode(1,TreeItem.CELL_MODE_RANGE)
		new_item.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
		
		new_item.set_editable(0, true)
		new_item.set_editable(1, true)
		new_item.set_editable(2, true)
		
		new_item.set_range_config(1, 0, 10000, 1.0)
		
		new_item.set_text(0, item)
		new_item.set_range(1, 0.0)
		new_item.set_text(2, "Explicit")
		
		new_item.add_button(2, preload("res://icons/trash_bin.svg"), 0, false, "Remove")


func get_tags() -> Array[Dictionary]:
	var tgs: Array[Dictionary] = []
	var used: Array[String] = []
	
	for item in root.get_children():
		var tag_name: String = item.get_text(0).strip_edges()
		var comp: String = tag_name.to_upper()
		if tag_name.is_empty() or used.has(comp):
			continue
		
		used.append(comp)
		
		tgs.append({
			"tag_name": tag_name,
			"spicy_level": int(item.get_range(1)),
			"explicit": item.is_checked(2)})
	
	return tgs


func _on_button_clicked(item: TreeItem, _column: int, _id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	item.free()
