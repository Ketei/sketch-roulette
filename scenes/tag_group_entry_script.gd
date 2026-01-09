class_name TagGroupEntry
extends HBoxContainer


signal remove_tag_pressed(node: TagGroupEntry, prompt: bool)
signal tag_triggers_changed(tag_id: int, group_id: int, triggers: bool)
signal weight_changed(tag_id: int, new_weight: int)


var tag_id: int = 0

#@onready var edit_btn: Button = $TagPanel/TagContainer/EditBtn
@onready var tag_label: Label = $TagLabel
@onready var weight_spinbx: SpinBox = $WeightSpinBx
@onready var group_trigger_mn_btn: MenuButton = $GroupTriggerMnBtn
@onready var remove_tag_btn: Button = $RemoveTagBtn



func _ready() -> void:
	group_trigger_mn_btn.get_popup().hide_on_checkable_item_selection = false
	group_trigger_mn_btn.get_popup().index_pressed.connect(_on_groups_idx_pressed)
	remove_tag_btn.pressed.connect(_on_erase_tag_pressed)


func set_groups(groups: Array[Dictionary], skip_groups: Array = [], restore: bool = true) -> void:
	var popup: PopupMenu = group_trigger_mn_btn.get_popup()
	var current_groups: Dictionary[int, bool] = {}
	
	for idx in range(popup.item_count):
		current_groups[popup.get_item_id(idx)] = popup.is_item_checked(idx)
	
	popup.clear()
	
	var idx: int = -1
	for group_item in groups:
		if skip_groups.has(group_item.id):
			continue
		idx += 1
		popup.add_check_item(
				group_item.name,
				group_item.id)
		
		if restore and current_groups.has(group_item.id):
			popup.set_item_checked(idx, current_groups[group_item.id])
		else:
			if group_item.has("enabled"):
				popup.set_item_checked(
					idx,
					group_item.enabled)



func _on_groups_idx_pressed(idx: int) -> void:
	var p: PopupMenu = group_trigger_mn_btn.get_popup()
	p.set_item_checked(idx, not p.is_item_checked(idx))
	tag_triggers_changed.emit(tag_id, p.get_item_id(idx), p.is_item_checked(idx))


func _on_weight_changed(value: float) -> void:
	var new_weight: int = int(value)
	weight_changed.emit(tag_id, new_weight)


func set_data(tag: String, weight: int, triggers: Array) -> void:
	var popup: PopupMenu = group_trigger_mn_btn.get_popup()
	
	tag_label.text = tag
	weight_spinbx.set_value_no_signal(weight)
	
	for idx in range(popup.item_count):
		popup.set_item_checked(idx, triggers.has(popup.get_item_id(idx)))


func set_tag_name(new_name: String) -> void:
	tag_label.text = new_name


func set_values(weight: int, triggers: Array) -> void:
	var popup: PopupMenu = group_trigger_mn_btn.get_popup()
	
	weight_spinbx.set_value_no_signal(weight)
	
	for idx in range(popup.item_count):
		popup.set_item_checked(idx, triggers.has(popup.get_item_id(idx)))


func get_tag_data() -> Dictionary:
	var triggers: Array[int] = []
	var trigger_popup: PopupMenu = group_trigger_mn_btn.get_popup()
	
	for item_idx in range(trigger_popup.item_count):
		if trigger_popup.is_item_checked(item_idx):
			triggers.append(trigger_popup.get_item_id(item_idx))
	
	var data: Dictionary = {
		"id": tag_id,
		"name": tag_label.text,
		"weight": int(weight_spinbx.value),
		"triggers": triggers}
	
	return data


func _on_erase_tag_pressed() -> void:
	remove_tag_pressed.emit(self, Input.is_key_pressed(KEY_SHIFT))
