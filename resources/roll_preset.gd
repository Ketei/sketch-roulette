class_name RollPreset
extends RefCounted


enum SelectionState{
	USE = 0,
	TRIGGER_ONLY = 1,
	SKIP = 2}

# Key = Group ID
# Value = Tags Enabled
#var preset_id: int = 0
var priorities_updated: bool = false
var _enabled_groups: Dictionary = {
	#0: {
		#"select_count": 0, 
		#"priority": 0, # Doesn't Change
		#"tags": {
			#0: {
				#"weight": 10000, # Doesn't Change
				#"triggers": [0,1,2,3]}} # Doesn't Change
		#}
	}


func clear() -> void:
	_enabled_groups.clear()


func groups(sort_priority: bool = false) -> Array[int]:
	var e: Array[int] = []
	e.assign(_enabled_groups.keys())
	
	if sort_priority:
		e.sort_custom(func (a,b): return _enabled_groups[b]["priority"] < _enabled_groups[a]["priority"])
	
	return e


func tags(from_group: int) -> Array[int]:
	var t: Array[int] = []
	if _enabled_groups.has(from_group):
		t.assign(_enabled_groups[from_group]["tags"].keys())
	return t


func set_group_draw_count(group_id: int, new_count: int) -> void:
	if not _enabled_groups.has(group_id):
		return
	_enabled_groups[group_id]["select_count"] = new_count


func set_group_priority(group_id: int, new_priority: int) -> void:
	if not _enabled_groups.has(group_id):
		return
	_enabled_groups[group_id]["priority"] = new_priority
	if not priorities_updated:
		priorities_updated = true


func has_group(group_id: int) -> bool:
	return _enabled_groups.has(group_id)


func add_group(group_id: int, draw_count: int, priority: int) -> void:
	_enabled_groups[group_id] = {
		"select_count": draw_count,
		"priority": priority,
		"tags": {}}


func remove_group(group_id: int) -> void:
	_enabled_groups.erase(group_id)


func set_group_tag(group_id: int, tag_id: int, weight: int, triggers: Array) -> void:
	var trigger_array: PackedInt64Array = []
	for item in triggers:
		if typeof(item) == TYPE_INT and not trigger_array.has(item):
			trigger_array.append(item)
	
	_enabled_groups[group_id]["tags"][tag_id] = {
		"weight": weight,
		"triggers": trigger_array}


func remove_group_tag(group_id: int, tag_id: int) -> void:
	if _enabled_groups.has(group_id) and _enabled_groups[group_id]["tags"].has(tag_id):
		_enabled_groups[group_id]["tags"].erase(tag_id)


func get_trigger_groups(group_id: int, tag_id: int) -> Array[int]:
	var a: Array[int] = []
	if _enabled_groups.has(group_id) and _enabled_groups[group_id]["tags"].has(tag_id):
		a.assign(_enabled_groups[group_id]["tags"][tag_id]["triggers"])
	return a


func set_trigger_on_tag(group_id: int, tag_id: int, trigger_group: int, trigger: bool) -> void:
	if _enabled_groups.has(group_id) and _enabled_groups[group_id]["tags"].has(tag_id):
		if trigger:
			if not _enabled_groups[group_id]["tags"][tag_id]["triggers"].has(trigger_group):
				_enabled_groups[group_id]["tags"][tag_id]["triggers"].append(trigger_group)
		else:
			var idx: int = _enabled_groups[group_id]["tags"][tag_id]["triggers"].find(trigger_group)
			if idx != -1:
				_enabled_groups[group_id]["tags"][tag_id]["triggers"].remove_at(idx)


func get_tag_weight(group_id: int, tag_id: int) -> int:
	if _enabled_groups.has(group_id) and _enabled_groups[group_id]["tags"].has(tag_id):
		return _enabled_groups[group_id]["tags"][tag_id]["weight"]
	return 10000


func set_tag_weight(group_id: int, tag_id: int, weight: int) -> void:
	if _enabled_groups.has(group_id) and _enabled_groups[group_id]["tags"].has(tag_id):
		_enabled_groups[group_id]["tags"][tag_id]["weight"] = weight


func get_draw_count(group_id: int) -> int:
	if _enabled_groups.has(group_id):
		return _enabled_groups[group_id]["select_count"] if 0 <= _enabled_groups[group_id]["select_count"] else _enabled_groups[group_id]["tags"].size()
	return 0


func get_priority(group_id: int) -> int:
	if _enabled_groups.has(group_id):
		return _enabled_groups[group_id]["priority"]
	return 0
