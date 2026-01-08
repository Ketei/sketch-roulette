extends VBoxContainer


signal preset_saved(preset_id: int, preset_name: int, format_template: String, preset_data: Dictionary)
#signal group_selected(group_id: int)

const ROLL_GROUP_ITEM = preload("res://scenes/roll_group_item.tscn")

var selected_group: Control = null

var preset_id: int = -1
var preset_name: String = ""
var roll_state: Dictionary = {
	#"group_id": {
		#"name": "Hemlo",
		#"node": Control.new(),
		#"tags": [{
			#"id": 0,
			#"name": ":3",
			#"enabled": true}]
	#}
}

@onready var groups_container: VBoxContainer = $DataContainer/ItemsContainer/GroupsScroll/GroupsContainer
@onready var tags_container: VBoxContainer = $DataContainer/ItemsContainer/TagsScroll/TagsContainer
@onready var format_text_edit: TextEdit = $DataContainer/FormatTextEdit
@onready var save_preset_btn: Button = $ButtonContainer/SavePresetBtn
@onready var done_btn: Button = $ButtonContainer/DoneBtn


func _ready() -> void:
	save_preset_btn.pressed.connect(_on_save_preset_pressed)


func is_tag_enabled(on_group: int, tag_id: int) -> bool:
	if roll_state.has(on_group):
		for item in roll_state[on_group]["tags"]:
			if item["id"] == tag_id:
				return item["enabled"]
	return false


#func get_tags_from_group(group_id: int, tag_amount: int, max_spiciness: int, use_nsfw: bool, allow_repeats: bool = false, exclude: Array[int] = []) -> Array[String]:
	#var s: Array[String] = []
	#
	#if tag_amount <= 0:
		#return s
	#
	#var tag_bag: Array[Dictionary] = []
	#var cumulative_weight: int = 0
	#var drawn: int = 0
	#
	#if 0 < tag_amount and roll_state.has(group_id):
		#var weight_bag: Array[Dictionary] = []
		#for tag_dict in roll_state[group_id]["tags"]:
			#if not tag_dict["enabled"] or exclude.has(tag_dict["id"]) or (not use_nsfw and tag_dict["explicit"]) or max_spiciness < tag_dict["spicy_level"]:
				#continue
			#weight_bag.append({"name": tag_dict["name"], "weight": tag_dict["weight"]})
		#
		#weight_bag.sort_custom(func(a,b): return b["weight"] < a["weight"])
		#
		#for item in weight_bag:
			#cumulative_weight += item["weight"]
			#tag_bag.append({
				#"name": item["name"],
				#"weight": item["weight"]})
		#
		#tag_bag.sort_custom(func(a,b): return a["weight"] < b["weight"])
	#
	#while not tag_bag.is_empty() and drawn < tag_amount:
		#var random_weight: int = randi_range(0, cumulative_weight)
		#var weight_step: int = 0
		#for item_idx in range(tag_bag.size()):
			#if random_weight <= tag_bag[item_idx]["weight"] + weight_step:
				#drawn += 1
				#s.append(tag_bag[item_idx]["name"])
				#if not allow_repeats:
					#cumulative_weight -= tag_bag[item_idx]["weight"]
					#tag_bag.remove_at(item_idx)
			#else:
				#weight_step += tag_bag[item_idx]["weight"]
	#
	#return s
#
#
#func get_tags_from_group_with_id(group_id: int, tag_amount: int, max_spiciness: int, use_nsfw: bool, exclude: Array[int] = []) -> Dictionary[int, String]:
	#var d: Dictionary[int, String] = {}
	#
	#if tag_amount <= 0:
		#return d
	#
	#var count: int = 0
	#if 0 < tag_amount and roll_state.has(group_id):
		#for tag_dict in roll_state[group_id]["tags"]:
			#if not tag_dict["enabled"] or exclude.has(tag_dict["id"]) or (not use_nsfw and tag_dict["explicit"]) or max_spiciness < tag_dict["spicy_level"]:
				#continue
			#d[tag_dict["id"]] = tag_dict["name"]
			#count += 1
			#
			#if tag_amount <= count :
				#break
	#
	#return d


func create_group_node(group_id: int, group_name: String, group_mode: int = 0) -> Control:
	var new_group := ROLL_GROUP_ITEM.instantiate()
	groups_container.add_child(new_group)
	new_group.group_id = group_id
	new_group.set_group_name(group_name)
	new_group.group_selected.connect(_on_group_selected)
	
	if group_mode != 0:
		groups_container.set_group_mode(group_mode)
	
	return new_group


func create_tag_node(tag_id: int, tag_name: String, enabled: bool = true) -> CheckBox:
	var new_tag: CheckBox = CheckBox.new()
	tags_container.add_child(new_tag)
	new_tag.text = tag_name
	new_tag.set_pressed_no_signal(enabled)
	new_tag.set_meta(&"tag_id", tag_id)
	return new_tag


func clear_tags() -> void:
	for item in tags_container.get_children():
		tags_container.remove_child(item)
		item.queue_free()


func set_tag_name(tag_id: int, new_name: String) -> void:
	for group_id in roll_state.keys():
		for item in roll_state[group_id]["tags"]:
			if item["id"] != tag_id:
				continue
			
			item["name"] = new_name
			break
	
	for tag_item in tags_container.get_children():
		if tag_item.get_meta(&"tag_id", -1) == tag_id:
			tag_item.text = new_name
			break


func add_group(group_id: int, group_name: String, group_mode: int = 0) -> void:
	if roll_state.has(group_id):
		return
	var tags: Array[Dictionary] = []
	var node: Control = create_group_node(group_id, group_name, group_mode)
	roll_state[group_id] = {
		"name": group_name,
		"status": group_mode,
		"tags": tags,
		"node": node}


func remove_group(group_id: int) -> void:
	if roll_state.has(group_id):
		var node: Control = roll_state[group_id]["node"]
		if selected_group == node:
			clear_tags()
		node.group_selected.disconnect(_on_group_selected)
		groups_container.remove_child(node)
		node.queue_free()
		roll_state.erase(group_id)


func remove_tag_from(group_id: int, tag_id: int) -> void:
	if not roll_state.has(group_id):
		return
	var removed: bool = false
	
	for item_idx in range(roll_state[group_id]["tags"].size()):
		if roll_state[group_id]["tags"][item_idx]["id"] == tag_id:
			roll_state[group_id]["tags"].remove_at(item_idx)
			removed = true
			break
	
	if selected_group != null and selected_group.group_id == group_id and removed :
		for item:CheckBox in tags_container.get_children():
			if item.get_meta(&"tag_id", -1) == tag_id:
				tags_container.remove_child(item)
				item.queue_free()
				break


func add_tags_to_group(group_id: int, tags: Array[Dictionary]) -> void:
	var tag_map: Array[int] = []
	
	for tag_dict in roll_state[group_id]["tags"]:
		tag_map.append(tag_dict["id"])
	
	var sort_nodes: bool = false
	var sort_dict: bool = false
	var same_group: bool = selected_group != null and selected_group.group_id == group_id
	
	for new_item in tags:
		if tag_map.has(new_item["id"]):
			continue
		roll_state[group_id]["tags"].append({
			"id": new_item["id"],
			"name": new_item["tag_name"],
			"enabled": new_item["tag_enabled"]})
		tag_map.append(new_item["id"])
		if sort_dict == false:
			sort_dict = true
		if same_group:
			create_tag_node(new_item["id"], new_item["tag_name"], new_item["tag_enabled"])
			if sort_nodes == false:
				sort_nodes = true
	
	if sort_dict:
		_sort_tags_of_group(group_id)
	
	if sort_nodes == false:
		return
	
	var tag_nodes: Array[Node] = tags_container.get_children()
	
	if tag_nodes.size() <= 1:
		return
	
	tag_nodes.sort_custom(func(a,b): return a.text < b.text)
	
	if tag_nodes[0].get_index() != 0:
		tags_container.move_child(tag_nodes[0], 0)
	
	for tag_node_idx in range(1, tag_nodes.size()):
		tags_container.move_child(tag_nodes[tag_node_idx], tag_node_idx)


func groups() -> Array[int]:
	var e: Array[int] = []
	for item in groups_container.get_children():
		e.append(item.group_id)
	return e


func set_tags_enabled(tag_ids: Array) -> void:
	for existing_tag:CheckBox in tags_container.get_children():
		existing_tag.set_pressed_no_signal(tag_ids.has(existing_tag.get_meta(&"tag_id", -1)))


func get_groups_mode() -> Dictionary[int, int]:
	var g: Dictionary[int, int] = {}
	for item in groups_container.get_children():
		g[item.group_id] = item.current_mode
	return g


#func get_group_names_mode(only_active: bool = false) -> Dictionary[String, int]:
	#var g: Dictionary[String, int] = {}
	#for item in groups_container.get_children():
		#if only_active and item.current_mode == 2:
			#continue
		#g[item.get_group_name()] = item.current_mode
	#return g


func get_group_names_mode(only_active: bool = false) -> Array[Dictionary]:
	var g: Array[Dictionary] = []
	for item in groups_container.get_children():
		if only_active and item.current_mode == 2:
			continue
		g.append({"id": item.group_id, "name": item.get_group_name(), "mode": item.current_mode})
	return g


func get_tags_enabled() -> Dictionary[int, bool]:
	var t: Dictionary[int, bool] = {}
	for item:CheckBox in tags_container.get_children():
		if not item.has_meta(&"tag_id"):
			continue
		t[item.get_meta(&"tag_id", -1)] = item.button_pressed
	return t


func get_tags_toggled_from_group(group_id: int) -> Dictionary[int, bool]:
	var t: Dictionary[int, bool] = {}
	if roll_state.has(group_id):
		for tag_dict in roll_state[group_id]["tags"]:
			t[tag_dict["id"]] = tag_dict["enabled"]
	return t


func get_group_mode(group_id: int) -> int:
	for item in groups_container.get_children():
		if item.group_id == group_id:
			return item.current_mode
	return 0


func set_state(data: Dictionary) -> void:
	#data = {
		#"int group ID": {
			#"selection_state": 0,
			#"tags": [{"id": 0, "tag_enabled": true}]}}
	
	for group_id in data.keys():
		if not roll_state.has(group_id):
			continue
		
		roll_state[group_id]["node"].set_group_mode(data[group_id]["selection_state"])
		#roll_state[group_id]["status"] = data[group_id]["selection_state"]
		for tag_dict in data[group_id]["tags"]:
			for state_tag in roll_state[group_id]["tags"]:
				if state_tag["id"] != tag_dict["id"]:
					continue
				state_tag["enabled"] = tag_dict["tag_enabled"]
				break
	
	if selected_group != null and data.has(selected_group.group_id):
		var id: int = selected_group.group_id
		for tag_child:CheckBox in tags_container.get_children():
			for state_tag in roll_state[id]["tags"]:
				if state_tag["id"] == tag_child.get_meta(&"tag_id", -1):
					tag_child.set_pressed_no_signal(state_tag["enabled"])
					break


func set_groups(data: Dictionary) -> void:
	roll_state.clear()
	
	for group_id in data.keys():
		var tags: Array[Dictionary] = []
		
		for tag_dict in data[group_id]["tags"]:
			tags.append({
				"id": tag_dict["id"],
				"name": tag_dict["tag_name"],
				"enabled": tag_dict["tag_enabled"],
				"spicy_level": tag_dict["spicy_level"],
				"explicit": tag_dict["explicit"]})
		tags.sort_custom(func (a,b): return a["name"] < b["name"])
		
		roll_state[group_id] = {
			"name": data[group_id]["group_name"],
			"tags": tags}
	
	var group_ids: Array = roll_state.keys()
	
	group_ids.sort_custom(func(a,b): return roll_state[a]["name"] < roll_state[b]["name"])
	
	for group_id in group_ids:
		var node: Control = create_group_node(group_id, roll_state[group_id]["name"], data[group_id]["status"])
		roll_state[group_id]["node"] = node


func is_group_selected() -> bool:
	return selected_group != null


func selected_group_id() -> int:
	return selected_group.group_id


func set_prompt(prompt: String) -> void:
	format_text_edit.text = prompt


func get_prompt() -> String:
	return format_text_edit.text.strip_edges()


func _save_current_state() -> void:
	if selected_group == null:
		return
	
	var tag_map: Dictionary = {}
	
	for tag in roll_state[selected_group.group_id]["tags"]:
		tag_map[tag["id"]] = tag
	
	for tag_node:CheckBox in tags_container.get_children():
		var target_id: int = tag_node.get_meta(&"tag_id", -1)
		if target_id == -1:
			continue
		tag_map[target_id]["enabled"] = tag_node.button_pressed


func _sort_tags_of_group(group_id: int) -> void:
	roll_state[group_id]["tags"].sort_custom(
		func (a,b): return a["name"] < b["name"])


func _on_save_preset_pressed() -> void:
	var save_prompt := preload("res://scripts/line_edit_confirmation_dialog.gd").new()
	save_prompt.allow_empty = false
	add_child(save_prompt)
	save_prompt.popup()
	save_prompt.grab_text_focus()
	if not preset_name.is_empty():
		save_prompt.set_line_text(preset_name)
		save_prompt.caret_to_end()
		save_prompt.select_all_text()
	
	var result: Array = await save_prompt.dialog_finished
	
	save_prompt.queue_free()
	
	if not result[0]:
		return
	
	_save_current_state()

	var preset_data: Dictionary = {}
	
	for group_id in roll_state.keys():
		var tags: Array[Dictionary] = []
		
		for tag_dict in roll_state[group_id]["tags"]:
			tags.append({
				"tag_id": tag_dict["id"],
				"tag_enabled": 1 if tag_dict["enabled"] else 0})
			
		
		preset_data[group_id] = {
			"selection_state": roll_state[group_id]["node"].current_mode,
			"tags": tags}
	
	preset_saved.emit(
			preset_id,
			result[1],
			format_text_edit.text.strip_edges(),
			preset_data)


func _on_group_selected(node: Control) -> void:
	if selected_group != null:
		selected_group.set_group_selected(false)
		_save_current_state()
	
	selected_group = node
	
	var group_id: int = node.group_id
	
	clear_tags()
	
	for tag:Dictionary in roll_state[group_id]["tags"]:
		create_tag_node(
				tag["id"],
				tag["name"],
				tag["enabled"])
