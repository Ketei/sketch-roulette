extends PanelContainer


var draw_time: int = 0
var elapsed_seconds: int = 0

var _selected_category_id: StringName = &""

var database: TagTable = TagTable.load_or_new()
var presets: TagPresets = TagPresets.load_or_new()

@onready var second_timer: Timer = $SecondTimer
@onready var sound_player: AudioStreamPlayer = $SoundPlayer



# Main windows
@onready var window_main: VBoxContainer = $MainWindow
@onready var window_tags: VBoxContainer = $EditTagWindow
@onready var window_timer: VBoxContainer = $CountdownContainer
@onready var window_add_tags: VBoxContainer = $AddTags

# Main window
@onready var spicy_spn_bx: SpinBox = $MainWindow/HBoxContainer/HBoxContainer/SpicySpnBx
@onready var enable_nsfw_chk_btn: CheckButton = $MainWindow/HBoxContainer/EnableNSFWChkBtn
@onready var edit_tags_btn: Button = $MainWindow/HBoxContainer/EditTagsBtn
@onready var preset_opt_btn: OptionButton = $MainWindow/HBoxContainer3/PresetOptBtn
@onready var roll_tags_btn: Button = $MainWindow/HBoxContainer3/RollTagsBtn
@onready var tags_tree: RollTagTree = $MainWindow/TagsTree
@onready var hour_spn_bx: SpinBox = $MainWindow/VBoxContainer/HBoxContainer3/HourContainer/HourSpnBx
@onready var min_spn_bx: SpinBox = $MainWindow/VBoxContainer/HBoxContainer3/MinuteContainer/MinSpnBx
@onready var sec_spn_bx: SpinBox = $MainWindow/VBoxContainer/HBoxContainer3/SecondContainer/SecSpnBx
@onready var start_timer_btn: Button = $MainWindow/StartTimerBtn
@onready var erase_preset_btn: Button = $MainWindow/HBoxContainer3/ErasePresetBtn


# Tags Window
@onready var new_category_btn: Button = $EditTagWindow/Label/NewCategoryBtn
@onready var tag_cat_tree: CategoriesTree = $EditTagWindow/TagCatTree
@onready var save_preset_btn: Button = $EditTagWindow/HBoxContainer/SavePresetBtn
@onready var done_btn: Button = $EditTagWindow/HBoxContainer/DoneBtn

# Tag add window
@onready var tags_txt_edt: TextEdit = $AddTags/TagsTxtEdt
@onready var cancel_add_btn: Button = $AddTags/HBoxContainer/CancelAddBtn
@onready var add_tags_btn: Button = $AddTags/HBoxContainer/AddTagsBtn
@onready var add_as_nsfw_chk_bx: CheckBox = $AddTags/AddAsNSFWChkBx


# Timer window
@onready var copy_tags_btn: Button = $CountdownContainer/VBoxContainer/Label/CopyTagsBtn
@onready var time_label: Label = $CountdownContainer/HBoxContainer/TimeLabel
@onready var stop_time_btn: Button = $CountdownContainer/HBoxContainer2/StopTimeBtn
@onready var pause_time_btn: Button = $CountdownContainer/HBoxContainer2/PauseTimeBtn
@onready var return_btn: Button = $CountdownContainer/HBoxContainer2/ReturnBtn
@onready var total_time_label: Label = $CountdownContainer/HBoxContainer/TotalTimeLabel
@onready var selected_tags_txt_edt: TextEdit = $CountdownContainer/VBoxContainer/PanelContainer/SelectedTagsTxtEdt


func _ready() -> void:
	get_window().min_size = Vector2i(450, 600)
	var preset_keys: Array[StringName] = []
	preset_keys.assign(presets.presets.keys())
	preset_keys.sort_custom(presets.sort_custom_name)
	
	for preset in preset_keys:
		preset_opt_btn.add_item(
				presets.presets[preset]["name"])
		preset_opt_btn.set_item_metadata(-1, preset)
	
	for category_id in database.categories():
		var category_data: Dictionary[StringName, Dictionary] = {}
		for tag_id in database.category_tags(category_id):
			category_data[tag_id] = database._tags[tag_id].duplicate()
		
		tag_cat_tree.add_category(
				category_id,
				database.get_category_name(category_id),
				database.get_category_priority(category_id),
				true,
				false,
				category_data)
	
	var cfg_path: String = ProjectSettings.globalize_path("user://main.cfg")
	var cfg: ConfigFile = ConfigFile.new()
	
	if FileAccess.file_exists(cfg_path) and cfg.load(cfg_path) == OK:
		var time: int = cfg.get_value("MAIN", "timer", 0)
		enable_nsfw_chk_btn.button_pressed = cfg.get_value("MAIN", "use_nsfw", false)
		spicy_spn_bx.value = cfg.get_value("MAIN", "spicyness", 0.0)
		if 0 < time:
			var hours: int = floori(time / float(3600))
			time -= hours * 3600
			var minutes: int = floori(time / float(60))
			time -= minutes * 60
		
			hour_spn_bx.value = hours
			min_spn_bx.value = minutes
			sec_spn_bx.value = time
	
	switch_window(0)
	start_timer_btn.pressed.connect(_on_start_timer_pressed)
	edit_tags_btn.pressed.connect(_on_edit_tags_pressed)
	return_btn.pressed.connect(_on_return_timer_pressed)
	pause_time_btn.pressed.connect(_on_pause_timer_pressed)
	stop_time_btn.pressed.connect(_on_stop_timer_pressed)
	done_btn.pressed.connect(_on_done_editing_tags_pressed)
	sec_spn_bx.value_changed.connect(_on_time_value_updated)
	min_spn_bx.value_changed.connect(_on_time_value_updated)
	hour_spn_bx.value_changed.connect(_on_time_value_updated)
	second_timer.timeout.connect(_on_second_timer_timeout)
	new_category_btn.pressed.connect(_on_add_category_pressed)
	add_tags_btn.pressed.connect(_on_submit_tags_pressed)
	
	preset_opt_btn.item_selected.connect(_on_preset_selected)
	copy_tags_btn.pressed.connect(_on_copy_tags_button_pressed)
	
	tag_cat_tree.category_erased.connect(_on_category_erased)
	tag_cat_tree.add_tags_to_pressed.connect(_on_add_tags_to_category_pressed)
	tag_cat_tree.tag_removed.connect(_on_tag_removed_from_category)
	tag_cat_tree.category_prio_changed.connect(_on_category_prio_changed)
	tag_cat_tree.spiciness_changed.connect(_on_spiciness_changed)
	tag_cat_tree.hornyness_changed.connect(_on_hornyness_changed)
	tags_tree.item_rerolled.connect(_on_item_rerolled)
	save_preset_btn.pressed.connect(_on_save_as_preset_pressed)
	
	roll_tags_btn.pressed.connect(_on_roll_for_tags_pressed)
	
	erase_preset_btn.pressed.connect(_on_erase_preset_pressed)


func _on_copy_tags_button_pressed() -> void:
	DisplayServer.clipboard_set(selected_tags_txt_edt.text)


func _on_category_prio_changed(category: StringName, priority: int) -> void:
	if database._categories.has(category):
		database._categories[category]["priority"] = priority


func _on_spiciness_changed(tag: StringName, level: int) -> void:
	if database._tags.has(tag):
		database._tags[tag]["spicy"] = level


func _on_hornyness_changed(tag: StringName, is_horny: bool) -> void:
	if database._tags.has(tag):
		database._tags[tag]["nsfw"] = is_horny


func _on_pause_timer_pressed() -> void:
	second_timer.paused = not second_timer.paused
	if second_timer.paused:
		pause_time_btn.text = "Resume Timer"
	else:
		pause_time_btn.text = "Pause Timer"


func _on_tag_removed_from_category(category: StringName, tag: StringName) -> void:
	database.remove_tag_from(category, tag)


func _on_category_erased(erased_category: StringName) -> void:
	database.erase_category(erased_category)


func _on_edit_tags_pressed() -> void:
	switch_window(1)


func _on_add_tags_to_category_pressed(category: StringName) -> void:
	tags_txt_edt.text = ""
	_selected_category_id = category
	add_as_nsfw_chk_bx.button_pressed = false
	switch_window(3)
	tags_txt_edt.grab_focus()


func _on_cancel_add_tags_pressed() -> void:
	switch_window(1)


func _on_submit_tags_pressed() -> void:
	var new_tags: Array[String] = []
	var new_items: Dictionary[StringName, String] = {}
	var nsfw: bool = add_as_nsfw_chk_bx.button_pressed
	
	for text_line in tags_txt_edt.text.split("\n", false):
		new_tags.append(text_line.strip_edges())
	
	for new_tag in new_tags:
		var tag_id: StringName = &""
		if database.has_tag(new_tag):
			tag_id = database.get_tag_id(new_tag)
			nsfw = database._tags[new_tag]["nsfw"]
			database.add_tag_to_category(tag_id, _selected_category_id, true)
		else:
			tag_id = database.add_tag(new_tag, 0, nsfw, _selected_category_id, true)
		new_items[tag_id] = new_tag
	
	tag_cat_tree.add_to_category(
		_selected_category_id,
		new_items,
		true,
		nsfw)
	
	_selected_category_id = &""
	
	switch_window(1)


func _on_add_category_pressed() -> void:
	var dialog: ConfirmationDialog = preload("res://scripts/line_edit_confirmation_dialog.gd").new()
	dialog.title = "New Category..."
	dialog.ok_button_text = "Add Category"
	dialog.cancel_button_text = "Cancel"
	add_child(dialog)
	dialog.show()
	dialog.grab_text_focus()
	var result = await dialog.dialog_finished
	
	if result[0]:
		var uuid: StringName = database.add_category(result[1])
		tag_cat_tree.add_category(uuid, result[1], 0, true, true)
	dialog.queue_free()


func _on_start_timer_pressed() -> void:
	if not OS.has_feature("editor"):
		var window: Window = get_window()
		window.min_size.y = 270
		if window.size.y == 600:
			window.size.y = 270
	stop_time_btn.visible = true
	pause_time_btn.visible = true
	return_btn.visible = false
	
	var wait_time: int = 0
	wait_time += int(hour_spn_bx.value) * 3600
	wait_time += int(min_spn_bx.value) * 60
	wait_time += int(sec_spn_bx.value)
	
	total_time_label.text = time_to_string(wait_time)
	time_label.text = time_to_string(0)
	
	draw_time = wait_time
	elapsed_seconds = 0
	
	second_timer.start.call_deferred()
	
	#for item in tags_h_flow.get_children():
		#tags_h_flow.remove_child(item)
		#item.queue_free()
	var tag_string: String = ", ".join(tags_tree.get_tags())
	
	selected_tags_txt_edt.text = tag_string
	
	switch_window(2)


func _on_second_timer_timeout() -> void:
	draw_time -= 1
	elapsed_seconds += 1
	time_label.text = time_to_string(elapsed_seconds)
	if draw_time == 0:
		second_timer.stop()
		pause_time_btn.visible = false
		stop_time_btn.visible = false
		return_btn.visible = true
		if sound_player.playing:
			sound_player.stop()
		sound_player.play()


func _on_return_timer_pressed() -> void:
	switch_window(0)
	if not OS.has_feature("editor"):
		var window: Window = get_window()
		if window.size.y == 270:
			window.size.y = 600
		window.min_size.y = 600


func _on_done_editing_tags_pressed() -> void:
	switch_window(0)


func _on_stop_timer_pressed() -> void:
	if not second_timer.is_stopped():
		second_timer.stop()
	if second_timer.paused:
		second_timer.paused = false
	stop_time_btn.visible = false
	pause_time_btn.visible = false
	pause_time_btn.text = "Pause Timer"
	return_btn.visible = true


func switch_window(index: int) -> void:
	window_main.visible = index == 0
	window_tags.visible = index == 1
	window_timer.visible = index == 2
	window_add_tags.visible = index == 3


func _on_time_value_updated(_value: float) -> void:
	if hour_spn_bx.value == 0.0 and min_spn_bx.value == 0.0:
		sec_spn_bx.min_value = 1.0
	else:
		sec_spn_bx.min_value = 0.0


func time_to_string(time: int) -> String:
	var time_string: String = ""
	var seconds: int = time
	var hours: int = floori(time / float(3600))
	seconds -= hours * 3600
	var minutes: int = floori(seconds / float(60))
	seconds -= minutes * 60
	
	if 9 < hours:
		time_string = str(hours) + ":"
	else:
		time_string = "0" + str(hours) + ":"
	
	if 9 < minutes :
		time_string += str(minutes) + ":"
	else:
		time_string += "0" + str(minutes) + ":"
	
	if 9 < seconds:
		time_string += str(seconds)
	else:
		time_string += "0" + str(seconds)
	
	return time_string


func _on_roll_for_tags_pressed() -> void:
	var final_tags: Array[Dictionary] = [] 
	var available_items: Dictionary[StringName, Dictionary] = tag_cat_tree.get_available_items() if preset_opt_btn.selected != 1 else tag_cat_tree.get_all_items()
	var sorted_items: Array[StringName] = []
	
	tags_tree.clear_tags()
	
	sorted_items.assign(available_items.keys())
	sorted_items.sort_custom(database.sort_custom_categories_priorities)
	
	for category_id in sorted_items:
		var items: Array[StringName] = available_items[category_id]["tags"].duplicate()
		items.shuffle()
		
		var results: Dictionary[StringName, String] = database.get_tags_from_pool(
				items,
				available_items[category_id]["max_amount"],
				int(spicy_spn_bx.value),
				enable_nsfw_chk_btn.button_pressed)
		
		for selected_id in results.keys():
			final_tags.append({"tag": results[selected_id], "id": selected_id,  "category": category_id})
	
	for tag_item in final_tags:
		tags_tree.add_tag(tag_item["tag"], tag_item["id"],  tag_item["category"])


func _on_item_rerolled(from_category: StringName, id: StringName, item: TreeItem) -> void:
	var new: Array = database.get_random_from_category(
			from_category,
			int(spicy_spn_bx.value),
			enable_nsfw_chk_btn.button_pressed,
			tags_tree.get_tag_ids())
	
	if not new[0].is_empty() and id != new[0]:
		item.set_text(0, new[1])
		item.get_metadata(0)["id"] = new[0]


func _on_preset_selected(idx: int) -> void:
	erase_preset_btn.disabled = idx < 2
	
	if idx < 2:
		return
	
	var id: StringName = preset_opt_btn.get_item_metadata(idx)
	
	for existing_category in tag_cat_tree.categories():
		if presets.presets[id]["categories"].has(existing_category):
			var data: Dictionary = presets.presets[id]["categories"][existing_category]
			tag_cat_tree.set_category(existing_category, data["active"], data["count"])
			tag_cat_tree.set_items_enabled(
					existing_category,
					data["tags"])
		else:
			tag_cat_tree.set_category(existing_category, false, -1)
			tag_cat_tree.set_items_enabled(
					existing_category,
					{})


func _on_save_as_preset_pressed() -> void:
	var dialog: ConfirmationDialog = preload("res://scripts/line_edit_confirmation_dialog.gd").new()
	add_child(dialog)
	dialog.show()
	dialog.grab_text_focus()
	
	var result: Array = await dialog.dialog_finished
	
	if result[0]:
		var uuid: StringName = presets.create_preset(result[1], tag_cat_tree.get_for_preset())
		var existing_items: Dictionary[StringName, String] = {}
		var sorted_uuids: Array[StringName] = []
		
		for item in range(2, preset_opt_btn.item_count):
			existing_items[preset_opt_btn.get_item_metadata(item)] = preset_opt_btn.get_item_text(item)
		
		existing_items[uuid] = result[1]
		
		sorted_uuids.assign(existing_items.keys())
		
		sorted_uuids.sort_custom(func(a,b): return existing_items[a].naturalnocasecmp_to(existing_items[b]) < 0)
		
		preset_opt_btn.clear()
		preset_opt_btn.add_item("Default")
		preset_opt_btn.add_item("Use All")
		
		for item in sorted_uuids:
			preset_opt_btn.add_item(existing_items[item])
			preset_opt_btn.set_item_metadata(-1, item)
		
		preset_opt_btn.select(sorted_uuids.find(uuid) + 2)
		erase_preset_btn.disabled = false
	dialog.queue_free()


func _on_erase_preset_pressed() -> void:
	presets.erase_preset(preset_opt_btn.get_selected_metadata())
	preset_opt_btn.remove_item(preset_opt_btn.selected)
	preset_opt_btn.select(0)
	erase_preset_btn.disabled = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not second_timer.is_stopped():
			second_timer.stop()
		if sound_player.playing:
			sound_player.stop()
		
		var save_data: Dictionary[StringName, Dictionary] = tag_cat_tree.get_for_save()
		
		for category_id in save_data.keys():
			for tag_id in save_data[category_id].keys():
				database._categories[category_id]["tags"][tag_id] = save_data[category_id][tag_id]
		
		var time: int = 0
		time += int(hour_spn_bx.value) * 3600
		time += int(min_spn_bx.value) * 60
		time += int(sec_spn_bx.value)
		
		var cfg: ConfigFile = ConfigFile.new()
		cfg.set_value("MAIN", "use_nsfw", enable_nsfw_chk_btn.button_pressed)
		cfg.set_value("MAIN", "spicyness", int(spicy_spn_bx.value))
		cfg.set_value("MAIN", "timer", time)
		
		cfg.save(ProjectSettings.globalize_path("user://main.cfg"))
		database.save()
		presets.save()
		
		get_tree().quit()
