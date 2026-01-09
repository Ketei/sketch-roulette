extends VBoxContainer


signal tag_removed(group_id: int, tag_id: int)
signal tag_weight_changed(group_id: int, tag_id: int, weight_id: int)
signal tag_triggers_changed(on_group: int, for_tag: int, target_group: int, triggers: bool)

const TAG_GROUP_ENTRY_SCENE = preload("res://scenes/tag_group_entry_scene.tscn")

var tag_groups: Array[Dictionary] = []
#var _set_priority: int = 0
#var _set_draw: int = 0

@onready var group_opt_btn: OptionButton = $HBoxContainer2/GroupOptBtn
@onready var new_group_btn: Button = $Label/NewGroupBtn
@onready var tag_group_container: VBoxContainer = $TagScrollContainer/TagGroupContainer
@onready var select_count_spn_bx: SpinBox = $HBoxContainer4/HBoxContainer2/SelectCountSpnBx
@onready var prio_spn_bx: SpinBox = $HBoxContainer4/HBoxContainer/PrioSpnBx
@onready var done_btn: Button = $HBoxContainer/DoneBtn
@onready var remove_tag_confirm_dialog: ConfirmationDialog = $RemoveTagConfirmDialog


func set_tag_name(tag_id: int, tag_name: String) -> void:
	for item:TagGroupEntry in tag_group_container.get_children():
		if item.tag_id == tag_id:
			item.set_tag_name(tag_name)
			break


func add_group(group_id: int, group_name: String) -> void:
	group_opt_btn.add_item(group_name, group_id)
	tag_groups.append({"id": group_id, "name": group_name})
	tag_groups.sort_custom(func(a,b): return a["name"] < b["name"])
	
	for existing_group:TagGroupEntry in tag_group_container.get_children():
		existing_group.set_groups(tag_groups, [group_opt_btn.get_selected_id()])


func remove_group(group_id: int) -> void:
	for idx in range(tag_groups.size()):
		if tag_groups[idx]["id"] == group_id:
			tag_groups.remove_at(idx)
			break
	
	for idx in range(group_opt_btn.item_count):
		if group_opt_btn.get_item_id(idx) == group_id:
			group_opt_btn.remove_item(idx)
			break
	
	for existing_group:TagGroupEntry in tag_group_container.get_children():
		existing_group.set_groups(tag_groups, [group_opt_btn.get_selected_id()])


func set_groups(groups: Array[Dictionary]) -> void:
	group_opt_btn.clear()
	tag_groups.clear()
	
	for item in groups:
		group_opt_btn.add_item(
				item.name,
				item.id)
		tag_groups.append({"id": item.id, "name": item.name})


func get_current_group() -> int:
	return group_opt_btn.get_selected_id()


func add_tags(tags: Array[Dictionary]) -> void:
	var tag_count: int = tags.size()
	for new_item in tags:
		var item: TagGroupEntry = TAG_GROUP_ENTRY_SCENE.instantiate()
		tag_group_container.add_child(item)
		item.tag_id = new_item.id
		item.set_groups(tag_groups, [group_opt_btn.get_selected_id()])
		item.set_data(new_item.name, 10000, [])
		item.remove_tag_pressed.connect(_on_remove_tag_pressed)
		item.tag_triggers_changed.connect(_on_tag_triggers_changed)
		item.weight_changed.connect(_on_weight_changed)
	select_count_spn_bx.max_value += tag_count
	select_count_spn_bx.set_value_no_signal(select_count_spn_bx.value + tag_count)


func set_group_data(data: Dictionary) -> void:
	for tag_item in tag_group_container.get_children():
		tag_item.remove_tag_pressed.disconnect(_on_remove_tag_pressed)
		tag_item.tag_triggers_changed.disconnect(_on_tag_triggers_changed)
		tag_item.weight_changed.disconnect(_on_weight_changed)
		tag_group_container.remove_child(tag_item)
		tag_item.queue_free()
	
	var tag_count: int = data.tags.size()
	var current_group: int = group_opt_btn.get_selected_id()
	
	prio_spn_bx.editable = not data.is_empty()
	select_count_spn_bx.editable = prio_spn_bx.editable
	
	select_count_spn_bx.max_value = tag_count
	
	for tag:Dictionary in data.tags:
		var item: TagGroupEntry = TAG_GROUP_ENTRY_SCENE.instantiate()
		tag_group_container.add_child(item)
		item.tag_id = tag.id
		item.set_groups(tag_groups, [current_group])
		item.set_data(tag.name, tag.weight, tag.triggers)
		item.remove_tag_pressed.connect(_on_remove_tag_pressed)
		item.tag_triggers_changed.connect(_on_tag_triggers_changed)
		item.weight_changed.connect(_on_weight_changed)
	
	prio_spn_bx.set_value_no_signal(data.priority)
	select_count_spn_bx.set_value_no_signal(data.select_count if 0 <= data.select_count else tag_count)


func set_group_status(data: Dictionary) -> void:
	var tags: Dictionary = data.tags
	#var a = {
		#TagID int: {
			#"id": TagID int,
			#"weight": 100000,
			#"triggers": []}}
	
	select_count_spn_bx.set_value_no_signal(data.select_count)
	prio_spn_bx.set_value_no_signal(data.priority)
	
	for item:TagGroupEntry in tag_group_container.get_children():
		if tags.has(item.tag_id):
			item.set_values(tags[item.tag_id]["weight"], tags[item.tag_id]["triggers"])


func get_group_data() -> Dictionary:
	var tags: Array[Dictionary] = []
	
	for item:TagGroupEntry in tag_group_container.get_children():
		tags.append(item.get_tag_data())
	
	var data: Dictionary = {
		"select_count": int(select_count_spn_bx.value),
		"priority": int(prio_spn_bx.value),
		"tags": tags}
	
	return data


func get_group_tags() -> Array[int]:
	var t: Array[int] = []
	for item:TagGroupEntry in tag_group_container.get_children():
		t.append(item.tag_id) 
	return t


func get_group_tag_names() -> Array[String]:
	var t: Array[String] = []
	
	for item:TagGroupEntry in tag_group_container.get_children():
		t.append(item.tag_label.text)
	
	return t


func is_group_selected() -> bool:
	return -1 < group_opt_btn.selected


func _on_remove_tag_pressed(node: TagGroupEntry, prompt: bool) -> void:
	if prompt:
		remove_tag_confirm_dialog.popup()
		var result: bool = await remove_tag_confirm_dialog.dialog_finished
		
		if result == false:
			return
	
	var tag_id: int = node.tag_id
	
	#node.tag_name_changed.disconnect(_on_tag_name_changed)
	node.remove_tag_pressed.disconnect(_on_remove_tag_pressed)
	tag_group_container.remove_child(node)
	node.queue_free()
	
	tag_removed.emit(group_opt_btn.get_selected_metadata(), tag_id)


func _on_weight_changed(tag_id: int, new_weight: int) -> void:
	tag_weight_changed.emit(group_opt_btn.get_selected_id(), tag_id, new_weight)


func _on_tag_triggers_changed(tag_id: int, group_id: int, triggers: bool) -> void:
	tag_triggers_changed.emit(
			group_opt_btn.get_selected_id(),
			tag_id,
			group_id,
			triggers)
