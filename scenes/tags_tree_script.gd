class_name RollTagTree
extends Tree


var target_prompt: String = ""
var group_modes: Dictionary[int, int] = {} # Group ID: mode
var tag_pool: TagPool = null
var root: TreeItem = null
var _groups: Dictionary[int, Array] = {} # 0: [item, item, item], 1: [item], 2: []...
var _others: Array[TreeItem] = []


func _ready() -> void:
	root = create_item()
	button_clicked.connect(_on_button_clicked)


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == 0:
		reroll_tag(item)


func update_tag_reference(tag_id: int, reference: String) -> void:
	if tag_pool != null:
		tag_pool.set_tag_reference(tag_id, reference)


func update_tag_spicy_level(tag_id: int, spicy: int) -> void:
	if tag_pool != null:
		tag_pool.set_tag_spicy_level(tag_id, spicy)


func update_tag_explicit(tag_id: int, explicit: bool) -> void:
	if tag_pool != null:
		tag_pool.set_tag_explicit(tag_id, explicit)


func update_tag_name(tag_id: int, new_name: String) -> void:
	if tag_pool != null:
		tag_pool.set_tag_name(tag_id, new_name)
		
		for item in root.get_children():
			if item.get_metadata(0)["id"] == tag_id:
				item.set_text(0, new_name)


func update_tag_weight(group_id: int, tag_id: int, new_weight: int) -> void:
	if tag_pool != null:
		tag_pool.set_tag_weight(group_id, tag_id, new_weight)


func reroll_tag(of_item: TreeItem) -> void:
	var meta: Dictionary = of_item.get_metadata(0)
	var result: Array[Dictionary] = tag_pool.pick_from_group_pool(
			meta["group"],
			1,
			false,
			meta["picked"])
	
	if result.is_empty():
		if 1 < tag_pool.group_tag_count(meta["group"]) and 1 < meta["picked"].size():
			meta["picked"].assign([meta["id"]])
			var second_try: Array[Dictionary] = tag_pool.pick_from_group_pool(
					meta["group"],
					1,
					false,
					meta["picked"])
			
			if not second_try.is_empty():
				of_item.set_text(0, second_try[0]["name"])
				meta["picked"].append(second_try[0]["id"])
				meta["id"] = second_try[0]["id"]
			return
		
		else:
			return
	
	of_item.set_text(0, result[0]["name"])
	meta["id"] = result[0]["id"]
	meta["picked"].append(result[0]["id"])


func add_tag(tag_text: String, id: int, group: int, group_index: int = -1, allow_reroll: bool = true) -> void:
	var new_item: TreeItem = get_root().create_child()
	new_item.set_text(0, tag_text)
	new_item.set_metadata(0, {"id": id, "group": group, "picked": [id]})
	new_item.add_button(
			0,
			preload("res://icons/refresh_icon.svg"),
			0,
			not allow_reroll,
			"Reroll tag")
	new_item.visible = not tag_text.is_empty()
	if -1 < group_index:
		if not _groups.has(group_index):
			var item_array: Array[TreeItem] = []
			_groups[group_index] = item_array
		_groups[group_index].append(new_item)
	else:
		_others.append(new_item)


func get_tags(in_format: bool) -> Array[Array]:
	var tags: Array[Array] = []
	if in_format:
		var keys: Array = _groups.keys()
		keys.sort()
		
		for key in keys:
			var jobs: Array[Dictionary] = []
			for item:TreeItem in _groups[key]:
				var meta: Dictionary = item.get_metadata(0)
				jobs.append({
					"tag_name": item.get_text(0),
					"reference": tag_pool.get_tag_reference(meta["id"]),
					"tag_id": meta["id"],
					"group_id": meta["group"]})
			tags.append(jobs)
	else:
		var all: Array[Dictionary] = []
		for item in _others:
			var meta: Dictionary = item.get_metadata(0)
			all.append({
				"tag_name": item.get_text(0),
				"reference": tag_pool.get_tag_reference(meta["id"]),
				"tag_id": meta["id"],
				"group_id": meta["group"]})
		tags.append(all)
	return tags


func get_tag_ids() -> Array[StringName]:
	var strs: Array[StringName] = []
	for item in get_root().get_children():
		strs.append(item.get_metadata(0)["id"])
	return strs


func clear_tags() -> void:
	_groups.clear()
	_others.clear()
	root.free()
	root = create_item()
