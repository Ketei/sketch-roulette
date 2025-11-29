class_name CategoriesTree
extends Tree


signal category_erased(category_id: StringName)
signal tag_removed(category: StringName, tag: StringName)
signal add_tags_to_pressed(category: StringName)
signal spiciness_changed(tag: StringName, level: int)
signal hornyness_changed(tag: StringName, is_horny: bool)
signal category_prio_changed(category: StringName, priority: int)

enum ButtonID{
	ERASE_CATEGORY,
	ERASE_TAG,
	NEW_TAG,
}

var column_pressed: int = 0
var tags: Dictionary[StringName, Array] = {}


func _ready() -> void:
	create_item()
	set_column_title(0, "Name")
	set_column_title(1, "Priority")
	set_column_title(2, "Amount")
	
	set_column_expand(0, true)
	set_column_expand(1, true)
	set_column_expand(2, true)
	
	set_column_expand_ratio(0, 2)
	set_column_expand_ratio(1, 1)
	set_column_expand_ratio(2, 1)
	button_clicked.connect(_on_button_clicked)
	item_edited.connect(_on_item_edited)


func _on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	var edited_column: int = get_edited_column()
	if edited.get_parent() == get_root():
		if edited_column == 0:
			if Input.is_key_pressed(KEY_SHIFT):
				var active: bool = edited.is_checked(0)
				for item in edited.get_children():
					item.set_checked(0, active)
		elif edited_column == 1:
			category_prio_changed.emit(
					edited.get_metadata(0),
					edited.get_range(1))
		return
	
	if edited_column == 1:
		var spiciness: int = int(edited.get_range(1))
		var id: StringName = edited.get_metadata(0)
		for tag:TreeItem in tags[id]:
			tag.set_range(1, spiciness)
		spiciness_changed.emit(id, spiciness)
	elif edited_column == 2:
		var is_horny: bool = edited.is_checked(2)
		var id: StringName = edited.get_metadata(0)
		for tag:TreeItem in tags[id]:
			tag.set_checked(2, is_horny)
		hornyness_changed.emit(id, is_horny)


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == ButtonID.ERASE_CATEGORY:
		var ids: Array[StringName] = []
		for tag_item in item.get_children():
			if tags.has(tag_item.get_metadata(0)):
				tags[tag_item.get_metadata(0)].erase(tag_item)
				ids.append(tag_item.get_metadata(0))
		for tag_id in ids:
			if tags[tag_id].is_empty():
				tags.erase(tag_id)
		category_erased.emit(item.get_metadata(0))
		item.free()
	elif id == ButtonID.ERASE_TAG:
		if tags.has(item.get_metadata(0)):
			tags[item.get_metadata(0)].erase(item)
		if tags[item.get_metadata(0)].is_empty():
			tags.erase(item.get_metadata(0))
		tag_removed.emit(item.get_parent().get_metadata(0), item.get_metadata(0))
		item.free()
	elif id == ButtonID.NEW_TAG:
		add_tags_to_pressed.emit(item.get_metadata(0))


func add_category(category_id: StringName, title: String, priority: int = 0, checked: bool = false, focus: bool = false, data: Dictionary[StringName, Dictionary] = {}) -> void:
	var new_category: TreeItem = get_root().create_child()
	var total_items: int = data.size()
	
	new_category.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	new_category.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_category.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	
	new_category.set_text(0, title)
	new_category.set_checked(0, checked)
	new_category.set_tooltip_text(0, "Include Category.")
	new_category.set_range_config(1, -1000.0, 1000.0, 1.0)
	new_category.set_tooltip_text(1, "Tags Priority.")
	new_category.set_range_config(2, 0.0, total_items, 1.0)
	new_category.set_range(2, total_items)
	new_category.set_tooltip_text(2, "How many should be picked.")
	
	new_category.set_editable(0, true)
	new_category.set_editable(1, true)
	new_category.set_editable(2, true)
	
	new_category.set_range(1, priority)
	
	new_category.add_button(
			2,
			preload("res://icons/new_tag_icon.svg"),
			ButtonID.NEW_TAG,
			false,
			"Add tags")
	
	new_category.add_button(
			2,
			preload("res://icons/trash_bin.svg"),
			ButtonID.ERASE_CATEGORY,
			false,
			"Erase Category")
	
	new_category.set_metadata(0, category_id)
	sort_single_item(new_category, column_pressed)
	
	# Each contains "tag": string, "spicy": int, "nsfw": bool
	if not data.is_empty():
		for item in data.keys():
			var new_item: TreeItem = new_category.create_child()
			
			new_item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
			new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			
			new_item.set_text(0, data[item]["tag"])
			new_item.set_text_overrun_behavior(0, TextServer.OVERRUN_TRIM_ELLIPSIS)
			new_item.set_editable(0, true)
			new_item.set_checked(0, true)
			new_item.set_tooltip_text(0, "Include Tag")
			new_item.set_range_config(1, 0.0, 1000, 1.0)
			new_item.set_range(1, data[item]["spicy"] if not tags.has(item) else tags[item][0].get_range(1))
			new_item.set_editable(1, true)
			new_item.set_tooltip_text(1, "Spiciness Level")
			new_item.set_text(2, "NSFW")
			new_item.set_editable(2, true)
			new_item.set_checked(2, data[item]["nsfw"] if not tags.has(item) else tags[item][0].is_checked(2))
			new_item.add_button(
					2,
					preload("res://icons/trash_bin.svg"),
					ButtonID.ERASE_TAG,
					false,
					"Remove Tag")
			new_item.set_metadata(0, item)
			sort_single_item(new_item, 0)
			
			if not tags.has(item):
				var new_data: Array[TreeItem] = []
				tags[item] = new_data
			tags[item].append(new_item)
	
	if focus:
		new_category.select(0)
		ensure_cursor_is_visible()


func has_category(category_id: StringName) -> bool:
	for item in get_root().get_children():
		if item.get_metadata(0) == category_id:
			return true
	return false


func categories() -> Array[StringName]:
	var all_cat: Array[StringName] = []
	for item in get_root().get_children():
		all_cat.append(item.get_metadata(0))
	return all_cat


func add_to_category(category: StringName, items: Dictionary[StringName, String], selected: bool = false, nsfw: bool = false) -> void:
	var category_item: TreeItem = null
	
	for category_tree in get_root().get_children():
		if category_tree.get_metadata(0) == category:
			category_item = category_tree
			break
	
	if category_item == null:
		return
	
	var existing: Array[StringName] = []
	for item in category_item.get_children():
		existing.append(item.get_metadata(0))
	
	for item_id in items.keys():
		if existing.has(item_id):
			continue
		var new_item: TreeItem = category_item.create_child()
		
		new_item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
		new_item.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
		
		new_item.set_text(0, items[item_id])
		new_item.set_text_overrun_behavior(0, TextServer.OVERRUN_TRIM_ELLIPSIS)
		new_item.set_editable(0, true)
		new_item.set_checked(0, selected)
		new_item.set_tooltip_text(0, "Include Tag")
		new_item.set_range_config(1, 0.0, 1000, 1.0)
		new_item.set_range(1, 0.0 if not tags.has(item_id) else tags[item_id][0].get_range(1))
		new_item.set_editable(1, true)
		new_item.set_tooltip_text(1, "Spiciness Level")
		new_item.set_text(2, "NSFW")
		new_item.set_editable(2, true)
		new_item.set_checked(2, nsfw if not tags.has(item_id) else tags[item_id][0].is_checked(2))
		new_item.add_button(
				2,
				preload("res://icons/trash_bin.svg"),
				ButtonID.ERASE_TAG,
				false,
				"Remove Tag")
		new_item.set_metadata(0, item_id)
		sort_single_item(new_item, 0)
		
		if not tags.has(item_id):
			var new_data: Array[TreeItem] = []
			tags[item_id] = new_data
		tags[item_id].append(new_item)
	
	category_item.set_range_config(2, 0.0, float(category_item.get_child_count()), 1.0)
	category_item.set_range(2, category_item.get_range(2) + items.size())


func set_category(category_id: StringName, enabled: bool, pick_count: int) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0) == category_id:
			item.set_checked(0, enabled)
			if pick_count < 0:
				item.set_range(2, item.get_child_count())
			else:
				item.set_range(2, pick_count)
			return


func set_items_enabled(from_category: StringName, items: Dictionary[StringName, bool]) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0) == from_category:
			for tag_item in item.get_children():
				if items.has(tag_item.get_metadata(0)):
					tag_item.set_checked(0, items[tag_item.get_metadata(0)])
				else:
					tag_item.set_checked(0, false)
			return


func sort_single_item(item: TreeItem, sort_column: int) -> void:
	var before_item: TreeItem = null
	
	for child in item.get_parent().get_children():
		if child == item:
			continue # We ignore the item we just added
		if item.get_text(sort_column).naturalnocasecmp_to(child.get_text(sort_column)) < 0:
			before_item = child
			break
	
	if before_item != null:
		item.move_before(before_item)
	else:
		if item.get_index() != item.get_parent().get_child_count() - 1:
			item.move_after(item.get_parent().get_child(-1))


func get_available_items() -> Dictionary[StringName, Dictionary]:
	var items: Dictionary[StringName, Dictionary] = {}
	for cat_item in get_root().get_children():
		if cat_item.is_checked(0):
			var available_tags: Array[StringName] = []
			for tag_item in cat_item.get_children():
				if tag_item.is_checked(0):
					available_tags.append(tag_item.get_metadata(0))
			items[cat_item.get_metadata(0)] = {
				"max_amount": cat_item.get_range(2),
				"tags": available_tags}
	
	return items


func get_all_items() -> Dictionary[StringName, Dictionary]:
	var items: Dictionary[StringName, Dictionary] = {}
	for cat_item in get_root().get_children():
		var available_tags: Array[StringName] = []
		for tag_item in cat_item.get_children():
			available_tags.append(tag_item.get_metadata(0))
		items[cat_item.get_metadata(0)] = {
			"max_amount": cat_item.get_range(2),
			"tags": available_tags}
	
	return items


func get_for_preset() -> Dictionary[StringName, Dictionary]:
	var cats: Dictionary[StringName, Dictionary] = {}
	
	for item in get_root().get_children():
		var tags_data: Dictionary[StringName, bool] = {}
		for tag_item in item.get_children():
			tags_data[tag_item.get_metadata(0)] = tag_item.is_checked(0)
		cats[item.get_metadata(0)] = {
			"active": item.is_checked(0),
			"count": item.get_range(2),
			"tags": tags_data}
	
	return cats


func get_for_save() -> Dictionary[StringName, Dictionary]:
	var cats: Dictionary[StringName, Dictionary] = {}
	for item in get_root().get_children():
		var tags_data: Dictionary[StringName, bool] = {}
		for tag_item in item.get_children():
			tags_data[tag_item.get_metadata(0)] = tag_item.is_checked(0)
		cats[item.get_metadata(0)] = tags_data
	
	return cats
