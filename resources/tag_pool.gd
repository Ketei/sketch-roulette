class_name TagPool
extends RefCounted


var _groups_tags: Dictionary[int, Array] = {}
var _tags: Dictionary[int, Dictionary] = {}


func has_tag(tag_id: int) -> bool:
	return _tags.has(tag_id)


func set_tag(tag_id: int, tag_name: String, reference_url: String, explicit: bool, spicy_level: int) -> void:
	_tags[tag_id] = {
		"id": tag_id,
		"name": tag_name,
		"reference": reference_url,
		"explicit": explicit,
		"spicy_level": spicy_level}


func has_tag_reference(tag_id: int) -> bool:
	return _tags.has(tag_id) and not _tags[tag_id]["reference"].is_empty()


func get_tag_reference(tag_id: int) -> String:
	if _tags.has(tag_id):
		return _tags[tag_id]["reference"]
	return ""


func add_tag_to_group(group_id: int, tag_id: int, tag_weight: int, enabled: bool = true) -> void:
	if not _tags.has(tag_id):
		return
	
	if not _groups_tags.has(group_id):
		var d: Array[Dictionary] = []
		_groups_tags[group_id] = d
	
	_groups_tags[group_id].append({"tag_id": tag_id, "weight": tag_weight, "enabled": enabled})


func get_tags_on_group(group_id: int) -> Array[Dictionary]:
	var t: Array[Dictionary] = []
	if _groups_tags.has(group_id):
		t.assign(_groups_tags[group_id])
	return t


func pick_from_group_pool(group_id: int, amount: int, allow_repeats: bool = false, skip: Array = []) -> Array[Dictionary]:
	var picked: Array[Dictionary] = []
	
	if not _groups_tags.has(group_id) or _groups_tags[group_id].is_empty():
		return picked
	
	var bag: Array[Dictionary] = _groups_tags[group_id].duplicate()
	var pick_count: int = 0
	var total_weight: int = 0
	
	for item in bag:
		if skip.has(item["tag_id"]) or not item["enabled"]:
			continue
		total_weight += item["weight"]
	
	while not bag.is_empty() and pick_count < amount and 0 < total_weight:
		var weight_step: int = 0
		var random_weight: int = randi_range(0, total_weight)
		
		for item_idx in range(bag.size()):
			if skip.has(bag[item_idx]["tag_id"]) or not bag[item_idx]["enabled"]:
				weight_step += bag[item_idx]["weight"]
				continue
			
			if random_weight <= bag[item_idx]["weight"] + weight_step:
				picked.append(_tags[bag[item_idx]["tag_id"]].duplicate())
				pick_count += 1
				if not allow_repeats:
					total_weight -= bag[item_idx]["weight"]
					bag[item_idx] = bag[-1]
					bag.pop_back()
				break
			else:
				weight_step += bag[item_idx]["weight"]
	
	return picked
