class_name TagTable
extends Resource


const FILE_PATH: String = "user://tags_table.tres"

@export var _tags: Dictionary[StringName, Dictionary] = {
	#&"UUID": {"tag": "", "spicy": 1, "nsfw": false}
}
@export var _categories: Dictionary = {
	#&"UUID": {"name": "", "priority": 0, "tags": {&"UUID": false}}
}


static func load_or_new() -> TagTable:
	var db: TagTable = null
	var global_path: String = ProjectSettings.globalize_path(FILE_PATH)
	if FileAccess.file_exists(global_path):
		var res_load: Resource = load(global_path)
		if res_load is TagTable:
			db = res_load
	
	if db == null:
		db = TagTable.new()
	
	for tag_id in db._tags.keys():
		var clean: bool = true
		for group_id in db._categories.keys():
			if db._categories[group_id]["tags"].has(tag_id):
				clean = false
				break
		if clean:
			db._tags.erase(tag_id)
	
	return db


func tags() -> Array[StringName]:
	var items: Array[StringName] = []
	items.assign(_tags.keys())
	return items


func category_tags(category: StringName) -> Array[StringName]:
	var tgs: Array[StringName] = []
	if not _categories.has(category):
		return tgs
	tgs.assign(_categories[category]["tags"].keys())
	return tgs


func categories() -> Array[StringName]:
	var cats: Array[StringName] = []
	cats.assign(_categories.keys())
	return cats


func get_category_name(category: StringName) -> String:
	if _categories.has(category):
		return _categories[category]["name"]
	return ""


func get_category_priority(category: StringName) -> int:
	if _categories.has(category):
		return _categories[category]["priority"]
	return 0


func sort_custom_categories_priorities(a: StringName, b: StringName) -> bool:
	if not _categories.has(a) or not _categories.has(b):
		return false
	return _categories[b]["priority"] <= _categories[a]["priority"]


func get_tags_from_pool(tag_pool: Array[StringName], amount: int, max_spicy: int, nsfw: bool) -> Dictionary[StringName, String]:
	var selected_tags: Dictionary[StringName, String] = {}
	var tag_count: int = 0
	for tag_id in tag_pool:
		if not _tags.has(tag_id) or max_spicy < _tags[tag_id]["spicy"]:
			continue
		
		if not nsfw and _tags[tag_id]["nsfw"]:
			continue
		
		selected_tags[tag_id] = _tags[tag_id]["tag"]
		tag_count += 1
		if amount <= tag_count:
			return selected_tags
	return selected_tags


func get_random_from_category(category_id: StringName, max_spicy: int, nsfw: bool, skip_items: Array[StringName] = []) -> Array:
	if not _categories.has(category_id) or _categories[category_id]["tags"].is_empty():
		return [&"", ""]
	var available: Array[StringName] = []
	available.assign(_categories[category_id]["tags"].keys())
	var random_id: StringName = available.pick_random() if not available.is_empty() else &""
	
	var debug_available: Array[String] = []
	var debug_exceptions: Array[String] = []
	
	for item in available:
		debug_available.append(_tags[item]["tag"])
	for item in skip_items:
		debug_exceptions.append(_tags[item]["tag"])
	
	print("Available: ", debug_available)
	print("Exceptions: ", debug_exceptions)
	
	while available.is_empty() == false:
		if _tags[random_id]["spicy"] <= max_spicy and not skip_items.has(random_id) and (true if nsfw else _tags[random_id]["nsfw"] == nsfw):
			print("Selected: ", _tags[random_id]["tag"])
			return [random_id, _tags[random_id]["tag"]]
		available.erase(random_id)
		if not available.is_empty():
			random_id = available.pick_random()
	return [&"", ""]


func get_tags_from_category(category_id: StringName, amount: int, max_spicy: int, nsfw: bool) -> Array[String]:
	var tag_items: Array[String] = []
	if not _categories.has(category_id):
		return tag_items
	var tag_count: int = 0
	for tag_id in _categories[category_id]["tags"].keys():
		if not _tags.has(tag_id) or _tags[tag_id]["nsfw"] != nsfw or max_spicy < _tags[tag_id]["spicy"]:
			continue
		tag_items.append(_tags[tag_id]["tag"])
		tag_count += 1
		
		if amount <= tag_count:
			return tag_items
	return tag_items


func has_tag(tag_string: String) -> bool:
	for tag_uid in _tags.keys():
		if _tags[tag_uid]["tag"] == tag_string:
			return true
	return false


func get_tag_id(tag_string: String) -> StringName:
	for tag in _tags.keys():
		if _tags[tag]["tag"] == tag_string:
			return tag
	return &""


func add_tag(tag_string: String, spicy: int = 0, nsfw: bool = false, add_to_group: StringName = &"", uses: bool = true) -> StringName:
	var uuid: StringName = StringName(UUID.generate_new())
	_tags[uuid] = {
		"tag": tag_string,
		"spicy": spicy,
		"nsfw": nsfw}
	
	if not add_to_group.is_empty() and _categories.has(add_to_group):
		_categories[add_to_group]["tags"][uuid] = uses
	
	return uuid


func remove_tag_from(category_id: StringName, tag_id: StringName) -> void:
	if _categories.has(category_id):
		_categories[category_id]["tags"].erase(tag_id)


func add_category(group_string: String, priority: int = 0) -> StringName:
	var uuid: StringName = StringName(UUID.generate_new())
	var tag_items: Dictionary[StringName, bool] = {}
	_categories[uuid] = {
		"name": group_string,
		"priority": priority,
		"tags": tag_items}
	return uuid


func add_tag_to_category(tag: StringName, category: StringName, checked: bool) -> void:
	if not _categories.has(category) or _categories[category]["tags"].has(tag):
		return
	_categories[category]["tags"][tag] = checked


func erase_category(group_id: StringName) -> void:
	_categories.erase(group_id)


func save() -> void:
	ResourceSaver.save(self, ProjectSettings.globalize_path(FILE_PATH))
