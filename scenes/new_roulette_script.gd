extends PanelContainer



const DB_VERSION: int = 1
const TAG_GROUP_ENTRY_SCENE = preload("res://scenes/tag_group_entry_scene.tscn")
enum EditMenuIDs {
	TAGS,
	GROUPS
}

var database: SQLite = SQLite.new()

var draw_time: int = 0
var elapsed_seconds: int = 0
var preset_idx: int = 0

var selected_group: int = -1
var active_preset: RollPreset = RollPreset.new()

var _dirty_trigger_pairs: Dictionary[int, Dictionary] = {}

@onready var preset_opt_btn: OptionButton = $MainWindow/HBoxContainer3/PresetOptBtn
@onready var second_timer: Timer = $SecondTimer
@onready var sound_player: AudioStreamPlayer = $SoundPlayer


# Main Window
@onready var edit_menu_btn: MenuButton = $MainWindow/HBoxContainer/EditMenuBtn
@onready var config_roll_btn: Button = $MainWindow/HBoxContainer3/ConfigRollBtn
@onready var erase_preset_btn: Button = $MainWindow/HBoxContainer3/ErasePresetBtn
@onready var hour_spn_bx: SpinBox = $MainWindow/VBoxContainer/HBoxContainer3/HourContainer/HourSpnBx
@onready var min_spn_bx: SpinBox = $MainWindow/VBoxContainer/HBoxContainer3/MinuteContainer/MinSpnBx
@onready var sec_spn_bx: SpinBox = $MainWindow/VBoxContainer/HBoxContainer3/SecondContainer/SecSpnBx
@onready var spicy_spn_bx: SpinBox = $MainWindow/HBoxContainer/HBoxContainer/SpicySpnBx
@onready var enable_nsfw_chk_btn: CheckButton = $MainWindow/HBoxContainer/EnableNSFWChkBtn
@onready var prompt_tags_tree: RollTagTree = $MainWindow/TagsTree
@onready var start_timer_btn: Button = $MainWindow/StartTimerBtn
@onready var roll_tags_btn: Button = $MainWindow/HBoxContainer3/RollTagsBtn
# -----------

# Group WIndow
@onready var new_group_btn: Button = $GroupsWindow/Label/NewGroupBtn
@onready var erase_group_btn: Button = $GroupsWindow/HBoxContainer2/EraseGroupBtn
@onready var add_tag_to_group_btn: Button = $GroupsWindow/HBoxContainer2/AddTagBtn
@onready var group_edit_done_btn: Button = $GroupsWindow/HBoxContainer/DoneBtn
@onready var group_done_btn: Button = $GroupsWindow/HBoxContainer/DoneBtn
@onready var add_tags_to_grp_btn: Button = $GroupsWindow/HBoxContainer2/AddTagBtn
@onready var group_opt_btn: OptionButton = $GroupsWindow/HBoxContainer2/GroupOptBtn
@onready var select_count_spn_bx: SpinBox = $GroupsWindow/HBoxContainer4/HBoxContainer2/SelectCountSpnBx
@onready var prio_spn_bx: SpinBox = $GroupsWindow/HBoxContainer4/HBoxContainer/PrioSpnBx
# ------------


# --- Roll ---
@onready var roll_done_btn: Button = $RollSetUp/ButtonContainer/DoneBtn

# ------------

# Edit Tags
@onready var edit_tags_done_button: Button = $TagEditorWindow/DoneButton
@onready var tag_editor_entries: VBoxContainer = $TagEditorWindow/ScrollContainer/TagEditorEntries
@onready var tag_editor_search_tag: LineEdit = $TagEditorWindow/SearchTag
# ---------

# --- Add Tags ---
@onready var add_tags_txt_edt: TextEdit = $AddTagsWindow/AddTagsReader/TagsTxtEdt
@onready var cancel_submit_tags_btn: Button = $AddTagsWindow/AddTagsReader/HBoxContainer/CancelAddBtn
@onready var submit_tags_btn: Button = $AddTagsWindow/AddTagsReader/HBoxContainer/AddTagsBtn
@onready var new_tags_tree: Tree = $AddTagsWindow/AddTagsConfirmation/TagsTree
@onready var add_tags_btn: Button = $AddTagsWindow/AddTagsConfirmation/ButtonContainer/SubmitAddBtn
@onready var cancel_add_tags_btn: Button = $AddTagsWindow/AddTagsConfirmation/ButtonContainer/CancelAddBtn


# ----------------

# --- Timer ---
@onready var stop_time_btn: Button = $CountdownContainer/HBoxContainer2/StopTimeBtn
@onready var pause_time_btn: Button = $CountdownContainer/HBoxContainer2/PauseTimeBtn
@onready var return_btn: Button = $CountdownContainer/HBoxContainer2/ReturnBtn
@onready var time_label: Label = $CountdownContainer/HBoxContainer/TimeLabel
@onready var total_time_label: Label = $CountdownContainer/HBoxContainer/TotalTimeLabel
@onready var selected_tags_rtl: RichTextLabel = $CountdownContainer/VBoxContainer/PanelContainer/SeletedTagsRTL

# -------------

@onready var main_window: VBoxContainer = $MainWindow
@onready var groups_window: VBoxContainer = $GroupsWindow
@onready var add_tags_window: PanelContainer = $AddTagsWindow
@onready var countdown_window: VBoxContainer = $CountdownContainer
@onready var tag_editor_window: VBoxContainer = $TagEditorWindow
@onready var roll_set_up_window: VBoxContainer = $RollSetUp

@onready var tags_reader_subwindow: VBoxContainer = $AddTagsWindow/AddTagsReader
@onready var tags_confirmation_subwindow: VBoxContainer = $AddTagsWindow/AddTagsConfirmation


func _ready() -> void:
	get_window().title = "SketchRoulette - " + ProjectSettings.get_setting("application/config/version")
	get_window().min_size = Vector2i(450, 600)
	
	database.path = "user://main_database.db"
	database.verbosity_level = SQLite.VerbosityLevel.NORMAL
	
	if not database.foreign_keys:
		database.foreign_keys = true
	
	database.open_db()
	
	database.query("PRAGMA synchronous = NORMAL; PRAGMA journal_mode = WAL; PRAGMA temp_store = MEMORY;")
	
	database.query(
			"CREATE TABLE IF NOT EXISTS schema_info (
					version INTEGER PRIMARY KEY);")
	
	database.query(
			"CREATE TABLE IF NOT EXISTS tags (
				id INTEGER PRIMARY KEY AUTOINCREMENT,
				tag_name TEXT COLLATE NOCASE UNIQUE NOT NULL,
				reference_url TEXT,
				explicit INTEGER DEFAULT 0,
				spicy_level INTEGER DEFAULT 0);")
	
	database.query(
			"CREATE TABLE IF NOT EXISTS tag_groups (
				id INTEGER PRIMARY KEY AUTOINCREMENT,
				group_name TEXT NOT NULL,
				priority INTEGER DEFAULT 0);")
	
	database.query(
			"CREATE TABLE IF NOT EXISTS group_tag_map (
				group_id INTEGER,
				tag_id INTEGER,
				tag_weight INTEGER DEFAULT 100,
				PRIMARY KEY (group_id, tag_id),
				FOREIGN KEY (group_id) REFERENCES tag_groups (id) ON DELETE CASCADE,
				FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE);")
	
	database.query(
			"CREATE TABLE IF NOT EXISTS tag_triggers_groups (
				tag_id INTEGER,
				group_id INTEGER,
				triggers_group INTEGER,
				PRIMARY KEY (tag_id, group_id, triggers_group),
				FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE,
				FOREIGN KEY (group_id) REFERENCES tag_groups (id) ON DELETE CASCADE);")
	
	database.query(
			"CREATE TABLE IF NOT EXISTS presets (
				id INTEGER PRIMARY KEY AUTOINCREMENT,
				preset_name TEXT NOT NULL UNIQUE,
				format_template TEXT);")
	
	database.query(
			"CREATE TABLE IF NOT EXISTS preset_groups (
				preset_id INTEGER NOT NULL,
				group_id INTEGER NOT NULL,
				draw_count INTEGER DEFAULT -1,
				selection_state INTEGER DEFAULT 0,
				PRIMARY KEY (preset_id, group_id),
				FOREIGN KEY (preset_id) REFERENCES presets (id) ON DELETE CASCADE,
				FOREIGN KEY (group_id) REFERENCES tag_groups (id) ON DELETE CASCADE);")
	
	database.query(
			"CREATE TABLE IF NOT EXISTS preset_tags (
				group_id INTEGER NOT NULL,
				preset_id INTEGER NOT NULL,
				tag_id INTEGER NOT NULL,
				tag_enabled INTEGER DEFAULT 1,
				PRIMARY KEY (preset_id, group_id, tag_id),
				FOREIGN KEY (group_id) REFERENCES tag_groups (id) ON DELETE CASCADE,
				FOREIGN KEY (preset_id) REFERENCES presets (id) ON DELETE CASCADE,
				FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE);")
	
	database.query("SELECT version FROM schema_info LIMIT 1;")
	
	var version_query: Array[Dictionary] = database.query_result
	
	if version_query.is_empty():
		database.query("INSERT INTO schema_info (version) VALUES (" + str(DB_VERSION) + ");")
	else:
		if version_query[0].version < DB_VERSION:
			update_database_from(version_query[0].version)
			database.update_rows("schema_info", "version = " + str(version_query[0].version), {"version": DB_VERSION})
	
	database.query(
			"DELETE FROM tags 
			WHERE NOT EXISTS (
				SELECT 1 
				FROM group_tag_map 
				WHERE group_tag_map.tag_id = tags.id);")
	
	database.query("VACUUM;")
	
	run_setup()
	
	var cfg_path: String = ProjectSettings.globalize_path("user://main.cfg")
	var cfg: ConfigFile = ConfigFile.new()
	
	if FileAccess.file_exists(cfg_path) and cfg.load(cfg_path) == OK:
		var time: int = cfg.get_value("MAIN", "timer", 0)
		enable_nsfw_chk_btn.button_pressed = cfg.get_value("MAIN", "use_nsfw", false)
		spicy_spn_bx.value = cfg.get_value("MAIN", "spicyness", 0.0)
		tag_editor_window.items_per_page = cfg.get_value("TAG_EDITOR", "items_per_page", 12)
		
		if 0 < time:
			var hours: int = floori(time / float(3600))
			time -= hours * 3600
			var minutes: int = floori(time / float(60))
			time -= minutes * 60
		
			hour_spn_bx.value = hours
			min_spn_bx.value = minutes
			sec_spn_bx.value = time
	
	switch_to_window(main_window)
	
	second_timer.timeout.connect(_on_second_timer_timeout)
	
	tag_editor_window.tag_name_changed.connect(_on_tag_name_changed)
	tag_editor_window.spiciness_changed.connect(_on_spiciness_changed)
	tag_editor_window.explicit_changed.connect(_on_explicit_changed)
	tag_editor_window.reference_changed.connect(_on_reference_changed)
	tag_editor_window.tag_searched.connect(_on_tag_searched)
	
	groups_window.tag_triggers_changed.connect(_on_tag_triggers_changed)
	groups_window.tag_weight_changed.connect(_on_tag_weight_changed)
	groups_window.tag_removed.connect(_on_tag_removed_from_group)
	
	roll_tags_btn.pressed.connect(_on_roll_for_tags_pressed)
	
	roll_set_up_window.preset_saved.connect(_on_preset_saved)
	
	roll_done_btn.pressed.connect(_on_roll_done_pressed)
	
	start_timer_btn.pressed.connect(_on_start_timer_pressed)
	submit_tags_btn.pressed.connect(_on_submit_tags_to_add_pressed)
	cancel_submit_tags_btn.pressed.connect(_on_cancel_submit_tags)
	cancel_add_tags_btn.pressed.connect(_on_cancel_tags_to_add_pressed)
	add_tags_btn.pressed.connect(_on_confirm_add_tags_pressed)
	
	tag_editor_search_tag.text_changed.connect(_on_tag_editor_search_tag)
	
	group_opt_btn.item_selected.connect(_on_group_selected, CONNECT_DEFERRED)
	
	sec_spn_bx.value_changed.connect(_on_time_value_updated)
	min_spn_bx.value_changed.connect(_on_time_value_updated)
	hour_spn_bx.value_changed.connect(_on_time_value_updated)
	
	erase_group_btn.pressed.connect(_on_remove_group_pressed)
	preset_opt_btn.item_selected.connect(_on_preset_selected)
	group_done_btn.pressed.connect(_on_group_done_button_pressed)
	config_roll_btn.pressed.connect(switch_to_window.bind(roll_set_up_window))
	edit_tags_done_button.pressed.connect(_on_edit_tags_done_button_pressed)
	edit_menu_btn.get_popup().id_pressed.connect(_on_edit_menu_id_pressed)
	add_tag_to_group_btn.pressed.connect(_on_add_tags_to_grp_btn_pressed)
	new_group_btn.pressed.connect(_on_create_group_pressed)
	return_btn.pressed.connect(_on_return_timer_pressed)
	pause_time_btn.pressed.connect(_on_pause_timer_pressed)
	stop_time_btn.pressed.connect(_on_stop_timer_pressed)
	selected_tags_rtl.meta_clicked.connect(_on_timer_label_meta_clicked)


func run_setup() -> void:
	var tag_map: Dictionary[int, Dictionary] = {}
	var group_relations: Dictionary[int, Dictionary] = {} # group_id: {tag_id: weight}
	
	database.query(
			"SELECT id, tag_name, explicit, spicy_level 
			FROM tags;")
	for row in database.query_result:
		tag_map[row["id"]] = {
			"tag_name": row["tag_name"],
			"explicit": row["explicit"],
			"spicy_level": row["spicy_level"]}
	
	database.query("SELECT * FROM group_tag_map;")
	for relationship_row in database.query_result:
		if not group_relations.has(relationship_row["group_id"]):
			group_relations[relationship_row["group_id"]] = {}
		group_relations[relationship_row["group_id"]][relationship_row["tag_id"]] = relationship_row["tag_weight"]
	
	var roll_data: Dictionary = {}
	database.query("SELECT * FROM tag_groups;")
	for group_column in database.query_result:
		var tags: Array[Dictionary] = []
		var group_id: int = group_column["id"]
		
		for tag_id in group_relations[group_id].keys():
			tags.append({
				"id": tag_id,
				"tag_name": tag_map[tag_id]["tag_name"],
				"tag_enabled": true,
				"spicy_level": tag_map[tag_id]["spicy_level"],
				"explicit": tag_map[tag_id]["explicit"],
				"weight": group_relations[group_id][tag_id]})
		
		roll_data[group_id] = {
			"group_name": group_column["group_name"],
			"priority": group_column["priority"],
			"status": 0,
			"tags": tags}
	
	var triggers: Dictionary[int, Dictionary] = {} # {group_id: {tag_id: [trigger_id,...] } }
	database.query("SELECT * FROM tag_triggers_groups;")
	
	for trigger_row in database.query_result:
		if not triggers.has(trigger_row["group_id"]):
			triggers[trigger_row["group_id"]] = {}
		if not triggers[trigger_row["group_id"]].has(trigger_row["tag_id"]):
			triggers[trigger_row["group_id"]][trigger_row["tag_id"]] = Array([], TYPE_INT, &"", null)
		triggers[trigger_row["group_id"]][trigger_row["tag_id"]].append(trigger_row["triggers_group"])
	
	database.query("SELECT id, preset_name FROM presets;")
	for preset in database.query_result:
		preset_opt_btn.add_item(preset["preset_name"], preset["id"])
	
	for group_id in roll_data.keys():
		groups_window.add_group(
				group_id,
				roll_data[group_id]["group_name"])
		
		active_preset.add_group(group_id, -1, roll_data[group_id]["priority"])
		for tag_dict in roll_data[group_id]["tags"]:
			var tag_triggers: Array[int] = []
			if triggers.has(group_id) and triggers[group_id].has(tag_dict["id"]):
				tag_triggers.assign(triggers[group_id][tag_dict["id"]])
			active_preset.set_group_tag(
				group_id,
				tag_dict["id"],
				tag_dict["weight"],
				tag_triggers)
	
	if group_opt_btn.selected != -1:
		_on_group_selected(0)
	erase_group_btn.disabled = group_opt_btn.item_count <= 0
	add_tags_to_grp_btn.disabled = erase_group_btn.disabled
	select_count_spn_bx.editable = not erase_group_btn.disabled
	prio_spn_bx.editable = not erase_group_btn.disabled
	roll_set_up_window.set_groups(roll_data)


func update_database_from(_version: int) -> void:
	pass


func switch_to_window(window: Control) -> void:
	var window_id: int = window.get_index()
	for window_item:Control in [main_window, groups_window, add_tags_window, countdown_window, tag_editor_window, roll_set_up_window]:
		window_item.visible = window_item.get_index() == window_id


func save_groups_to_active_preset() -> void:
	var id: int = groups_window.get_current_group()
	#var target: Dictionary = default_preset._enabled_groups[groups_window.get_current_group()]
	var data: Dictionary = groups_window.get_group_data()
	#var group_mode: int = roll_set_up_window.get_group_mode()
	
	active_preset.set_group_priority(id, data["priority"])
	active_preset.set_group_draw_count(id, data["select_count"])
	
	for tag:Dictionary in data["tags"]:
		active_preset.set_group_tag(id, tag["id"], tag["weight"], tag["triggers"])


func save_setup_group_to_active_preset() -> void:
	var modes: Dictionary = roll_set_up_window.get_groups_mode()
	for group in modes.keys():
		active_preset.set_group_mode(group, modes[group])


func save_setup_tags_to_active_preset() -> void:
	var id: int = roll_set_up_window.selected_group_id()
	var tags: Dictionary[int, bool] = roll_set_up_window.get_tags_enabled()
	
	for tag_id in tags.keys():
		if tag_id == -1:
			continue
		
		active_preset.set_tag_enabled(id, tag_id, tags[tag_id])


func load_custom_preset(preset_id: int) -> void:
	database.query(
			"SELECT format_template FROM presets WHERE id = " + str(preset_id) + ";")
	var result: Array[Dictionary] = database.query_result
		
	database.query(
			"SELECT group_id, draw_count, selection_state
			FROM preset_groups 
			WHERE preset_id = " + str(preset_id) + ";")
	
	var groups_result: Array[Dictionary] = database.query_result
	var roll_data: Dictionary = {}
	
	for row in groups_result:
		database.query(
				"SELECT tag_id, tag_enabled 
				FROM preset_tags 
				WHERE group_id = " + str(row["group_id"]) +\
				" AND preset_id = " + str(preset_id) + ";")
		var tags_result: Array[Dictionary] = database.query_result
		var tags: Array[Dictionary] = []
		
		for tag_row in tags_result:
			tags.append({
				"id": tag_row["tag_id"],
				"tag_enabled": tag_row["tag_enabled"]})
		
		active_preset.set_group_draw_count(
				row["group_id"],
				row["draw_count"])
		
		roll_data[row["group_id"]] = {
			"selection_state": row["selection_state"],
			"tags": tags}
	
	if not result.is_empty():
		if typeof(result[0]["format_template"]) == TYPE_STRING:
			roll_set_up_window.set_prompt(result[0]["format_template"])
	
	roll_set_up_window.set_state(roll_data)
	
	if groups_window.is_group_selected():
		var selected_group_id: int = groups_window.get_current_group()
		
		select_count_spn_bx.set_value_no_signal(active_preset.get_draw_count(selected_group_id))


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


func parse_prompt_template(template_string: String) -> Dictionary:
	if template_string.is_empty():
		return {
		"format_string": "",
		"tasks": Array([], TYPE_DICTIONARY, &"", null)}
	
	var rgx: RegEx = RegEx.new()
	var processed_string: String = ""
	
	var draw_task: Array[Dictionary] = []
	
	var last_pos: int = 0
	var idx: int = -1
	
	rgx.compile("\\{([^\\}]+)\\}")
	
	for result in rgx.search_all(template_string):
		var result_parts: PackedStringArray = result.get_string().trim_prefix("{").trim_suffix("}").split(":", false)
		var include_chance: float = 100.0
		var draw_override: int = -1
		var tag_name: String = ""
		
		if 1 < result_parts.size(): # We have arguments
			for part in result_parts:
				if part.ends_with("%"):
					if part.trim_suffix("%").is_valid_float(): # It's a draw chance
						include_chance = part.trim_suffix("%").to_float()
				else:
					if part.is_valid_float():
						draw_override = part.to_int()
					elif result_parts[1] == part:
						tag_name = part
			
			# Correction
			if draw_override <= 0:
				draw_override = maxi(0, draw_override)
			include_chance = maxf(0.0, include_chance)
		
		idx += 1
		processed_string += template_string.substr(last_pos, result.get_start() - last_pos)
		processed_string += "{" + str(idx) + "}"
		
		var group_name: String = result_parts[0]
		
		if group_name.begins_with("!"): # Ignore draw override
			draw_task.append({
				"group_name": group_name.trim_prefix("!"),
				"chance": include_chance,
				"tag_name": tag_name})
		else:
			draw_task.append({
				"group_name": group_name,
				"count": draw_override,
				"chance": include_chance})
		
		last_pos = result.get_end()
	
	processed_string += template_string.substr(last_pos)
	
	return {
		"format_string": processed_string,
		"tasks": draw_task}


func get_trigger_groups_string_of(group_id: int, tag_id: int, group_modes: Dictionary[int, int], prefix_whitespace: bool = true, _history: Array[StringName] = []) -> String:
	var state_key: StringName = StringName(str(group_id, "-", tag_id))
	if _history.has(state_key):
		push_error("Error message here")
		return ""
	
	var next_history: Array[StringName] = _history.duplicate()
	next_history.append(state_key)
	
	var string_items: Array[String] = []
	var trigger_groups: Array[int] = active_preset.get_trigger_groups(group_id, tag_id)
	
	for group_key in trigger_groups:
		if not group_modes.has(group_key) or group_modes[group_key] == 2: # Skip off groups
			continue
		
		# Draw the tags
		#{
		#"id": tag_id,
		#"name": tag_name,
		#"reference": reference_url,
		#"explicit": explicit,
		#"spicy_level": spicy_level}
		var tags_drawn:Array[Dictionary] = prompt_tags_tree.tag_pool.pick_from_group_pool(
				group_key,
				active_preset.get_draw_count(group_key))
		#var tags: Dictionary[int, String] = roll_set_up_window.get_tags_from_group_with_id(
				#group_key,
				#active_preset.get_draw_count(group_key),
				#int(spicy_spn_bx.value),
				#enable_nsfw_chk_btn.button_pressed)
		
		# Add to final string
		for drawn_item in tags_drawn:
			var tag_name: String = ""
			if not drawn_item["reference"].is_empty():
				tag_name =  str("[color=LIGHT_SKY_BLUE][url=", drawn_item["reference"], "]", drawn_item["name"], "[/url][/color]")
			else:
				tag_name = drawn_item["name"]
			
			var subtriggers: String = get_trigger_groups_string_of(
				group_key,
				drawn_item["id"],
				group_modes,
				prefix_whitespace,
				next_history)
			
			string_items.append(tag_name + subtriggers)
	
	if string_items.is_empty():
		return ""
	else:
		var last_item: String = string_items.pop_back()
		var commad: String = ", ".join(string_items)
		var prefix: String = " " if prefix_whitespace else ""
		
		if commad.is_empty():
			return prefix + "(" + last_item + ")"
		else:
			return prefix + "(" + commad + " and " + last_item + ")"


func array_to_promt(items: Array[String]) -> String:
	if items.is_empty():
		return ""
	else:
		var last_item: String = items[-1]
		var commad: String = ", ".join(items.slice(0, -1))
		
		if not commad.is_empty():
			commad += " and "
		
		return commad + last_item


func get_tags_from_db(max_spice: int, explicit: bool) -> TagPool:
	var pool: TagPool = TagPool.new()
	var spice_str: String = str(max_spice)
	var explicit_str: String = "(0, 1)" if explicit else "(0)"
	var groups: Dictionary = roll_set_up_window.get_groups_mode()
	database.query(
			"SELECT t.*, gtm.group_id  
			FROM tags t 
			JOIN group_tag_map gtm ON t.id = gtm.tag_id
			WHERE t.explicit IN " + explicit_str + " 
				AND t.spicy_level <= " + spice_str + ";")
	
	for tag_dict in database.query_result:
		if not pool.has_tag(tag_dict["id"]): # Hash lookup
			pool.set_tag(
					tag_dict["id"],
					tag_dict["tag_name"],
					tag_dict["reference_url"] if typeof(tag_dict["reference_url"]) == TYPE_STRING else "",
					tag_dict["explicit"],
					tag_dict["spicy_level"])
		if groups.has(tag_dict["group_id"]) and groups[tag_dict["group_id"]] != 2:
			pool.add_tag_to_group(
					tag_dict["group_id"],
					tag_dict["id"],
					active_preset.get_tag_weight(tag_dict["group_id"], tag_dict["id"]),
					roll_set_up_window.is_tag_enabled(
							tag_dict["group_id"],
							tag_dict["id"]))
	
	#database.query("SELECT * FROM group_tag_map;")
	#
	#for group_map in database.query_result:
		#if not roll_set_up_window.is_tag_enabled(group_map["group_id"], group_map["tag_id"]):
			#continue
		#pool.add_tag_to_group(
				#group_map["group_id"],
				#group_map["tag_id"],
				#group_map["tag_weight"],
				#roll_set_up_window.is_tag_enabled(
						#group_map["group_id"],
						#group_map["tag_id"]))
	
	return pool


#func roll_from_db_picks(items: Array[Dictionary], amount: int, allow_repeats: bool) -> Array[Dictionary]:
	#var bag: Array[Dictionary] = items.duplicate()
	#var picked: Array[Dictionary] = []
	#var pick_count: int = 0
	#var total_weight: int = 0
	#
	#for item in items:
		#total_weight += item["tag_weight"]
	#
	#while not bag.is_empty() and pick_count < amount and 0 < total_weight:
		#var weight_step: int = 0
		#var random_weight: int = randi_range(0, total_weight)
		#for item_idx in range(bag.size()):
			#if random_weight <= bag[item_idx]["tag_weight"] + weight_step:
				#picked.append(bag[item_idx])
				#pick_count += 1
				#if not allow_repeats:
					#total_weight -= bag[item_idx]["tag_weight"]
					#bag[item_idx] = bag[-1]
					#bag.pop_back()
				#break
	#return picked


func _on_preset_selected(idx: int) -> void:
	erase_preset_btn.disabled = idx < 2
	
	if idx == 1 or idx == 0:
		preset_idx = idx - 1
		roll_set_up_window.preset_id = -1
		roll_set_up_window.preset_name = ""
		return
	elif preset_idx == idx:
		return
	
	if 1 < idx:
		load_custom_preset(preset_opt_btn.get_item_id(idx))
	
	if groups_window.is_group_selected():
		var group_id: int = groups_window.get_current_group()
		var data: Dictionary = {}
		
		for tag_id in active_preset.tags(group_id):
			data[tag_id] = {
				"weight": active_preset.get_tag_weight(group_id, tag_id),
				"triggers": active_preset.get_trigger_groups(group_id, tag_id)}
		
		groups_window.set_group_status(
			{
				"priority": active_preset.get_priority(group_id),
				"select_count": active_preset.get_draw_count(group_id),
				"tags": data})
	
	preset_idx = idx
	
	roll_set_up_window.preset_id = preset_opt_btn.get_item_id(idx)
	roll_set_up_window.preset_name = preset_opt_btn.get_item_text(idx)


func mark_trigger_dirty(group_id: int, tag_id: int) -> void:
	if not _dirty_trigger_pairs.has(group_id):
		_dirty_trigger_pairs[group_id] = {}
	_dirty_trigger_pairs[group_id][tag_id] = null


#func has_trigger_updates() -> bool:
	#return not _trigger_updates.is_empty()
#
#
#func trigger_update_groups() -> Array[int]:
	#return _trigger_updates.keys()
#
#
#func get_updated_trigger_tags(from_group: int) -> Dictionary[int, Array]:
	#var t: Dictionary = {}
	#if _trigger_updates.has(from_group):
		#t.assign(_trigger_updates[from_group].duplicate(true))
	#return t
#
#
#func _set_trigger_update(group: int, tag: int, trigger_group: int, triggers: bool) -> void:
	#if triggers:
		#if not _trigger_updates.has(group):
			#_trigger_updates[group] = {}
		#if not _trigger_updates[group].has(tag):
			#_trigger_updates[group][tag] = Array([], TYPE_INT, &"", null)
		#if not _trigger_updates[group][tag].has(trigger_group):
			#_trigger_updates[group][tag].append(trigger_group)
	#else:
		#if _trigger_updates.has(group) and _trigger_updates[group].has(tag):
			#_trigger_updates[group][tag].erase(trigger_group)
			#
			#if _trigger_updates[group][tag].is_empty():
				#_trigger_updates[group].erase(tag)
				#if _trigger_updates[group].is_empty():
					#_trigger_updates.erase(group)



func _on_time_value_updated(_value: float) -> void:
	if hour_spn_bx.value == 0.0 and min_spn_bx.value == 0.0:
		sec_spn_bx.min_value = 1.0
	else:
		sec_spn_bx.min_value = 0.0


func _on_edit_menu_id_pressed(id: int) -> void:
	if id == EditMenuIDs.TAGS:
		switch_to_window(tag_editor_window)
	elif id == EditMenuIDs.GROUPS:
		switch_to_window(groups_window)


func _on_group_selected(group_idx: int) -> void:
	var group_id: int = group_opt_btn.get_item_id(group_idx)
	
	if selected_group == group_id:
		return
	
	if -1 < selected_group:
		active_preset.set_group_draw_count(selected_group, int(select_count_spn_bx.value))
		active_preset.set_group_priority(selected_group, int(prio_spn_bx.value))
	selected_group = group_id
	
	database.query(
			"SELECT priority 
			FROM tag_groups 
			WHERE id = " + str(group_id) + ";")
	
	var query_result: Array[Dictionary] = database.query_result
	var group_data: Dictionary = query_result[0]
	
	database.query(
			"SELECT t.id, t.tag_name
			FROM group_tag_map gtm 
			JOIN tags t ON gtm.tag_id = t.id 
			WHERE gtm.group_id = " + str(group_id) + ";")
	
	var tags_in_group: Array[Dictionary] = database.query_result
	var tags: Array[Dictionary] = []
	
	for item in tags_in_group:
		tags.append({
			"id": item["id"],
			"name": item["tag_name"],
			"weight": active_preset.get_tag_weight(group_id, item["id"]),
			"triggers": active_preset.get_trigger_groups(group_id, item["id"])})
	
	var data: Dictionary = {
		"select_count": active_preset.get_draw_count(group_id),
		"priority": group_data["priority"],
		"tags": tags}
	
	groups_window.set_group_data(data)


func _on_group_tag_name_changed(tag_id: int, new_name: String) -> void:
	database.update_rows("tags", "id = " + str(tag_id), {"tag_name": new_name})


func _on_group_done_button_pressed() -> void:
	if -1 < selected_group:
		active_preset.set_group_draw_count(selected_group, int(select_count_spn_bx.value))
		active_preset.set_group_priority(selected_group, int(prio_spn_bx.value))
	switch_to_window(main_window)


func _on_edit_tags_done_button_pressed() -> void:
	switch_to_window(main_window)


func _on_tag_editor_search_tag(text: String) -> void:
	text = text.strip_edges()
	var empty: bool = text.is_empty()
	
	for item:TagItemEntry in tag_editor_entries.get_children():
		item.visible = empty or item.tag_name().containsn(text)


func _on_add_tags_to_grp_btn_pressed() -> void:
	tags_reader_subwindow.visible = true
	tags_confirmation_subwindow.visible = false
	add_tags_txt_edt.text = ""
	
	switch_to_window(add_tags_window)
	
	add_tags_txt_edt.grab_focus()


func _on_cancel_submit_tags() -> void:
	switch_to_window(groups_window)


func _on_submit_tags_to_add_pressed() -> void:
	var existing: Array[String] = groups_window.get_group_tag_names()
	var to_add: Array[String] = []
	
	for line in add_tags_txt_edt.text.split("\n", false):
		var clean: String = line.strip_edges()
		if clean.is_empty() or _arrstr_containsn(existing, clean) or _arrstr_containsn(to_add, clean):
			continue
		to_add.append(clean)
	
	if to_add.is_empty():
		return
	
	tags_reader_subwindow.visible = false
	tags_confirmation_subwindow.visible = true
	new_tags_tree.set_tags(to_add)


func _on_cancel_tags_to_add_pressed() -> void:
	tags_reader_subwindow.visible = true
	tags_confirmation_subwindow.visible = false


#func _on_add_tags_to_group_pressed() -> void:
	#var db_tag_rows: Array = database.select_rows("tags", "", ["tag_name"])
	#var db_tags: PackedStringArray = []


func _on_confirm_add_tags_pressed() -> void:
	var new: Array[Dictionary] = new_tags_tree.get_tags()
	var new_data: Array[Dictionary] = []
	var group_id: int = group_opt_btn.get_selected_id()
	var roller_tags: Array[Dictionary] = []
	
	for new_tag in new:
		var id: int = 0
		database.query_with_bindings("SELECT id FROM tags WHERE tag_name = ? LIMIT 1;", [new_tag["tag_name"]])
		var result: Array[Dictionary] = database.query_result
		
		if result.is_empty():
			var success: bool = database.insert_row(
					"tags",
					{
						"tag_name": new_tag["tag_name"],
						"explicit": new_tag["explicit"],
						"spicy_level": new_tag["spicy_level"]})
			if not success:
				push_error("Error while trying to create tag: " + new_tag["tag_name"])
				continue
			id = database.last_insert_rowid
		else:
			id = result[0]["id"]
		
		roller_tags.append({"id": id, "tag_name": new_tag["tag_name"], "tag_enabled": true})
		
		database.insert_row(
				"group_tag_map",
				{"group_id": group_id, "tag_id": id, "tag_weight": 100})
		
		active_preset.set_group_tag(
				group_id,
				id,
				100,
				[])
		
		new_data.append({
			"id": id,
			"name": new_tag["tag_name"]})
	
	if not roller_tags.is_empty():
		roll_set_up_window.add_tags_to_group(group_id, roller_tags)
	groups_window.add_tags(new_data)
	
	switch_to_window(groups_window)


func _arrstr_containsn(where: Array[String], what: String) -> bool:
	for item in where:
		if item.nocasecmp_to(what) == 0:
			return true
	return false


func _on_tag_triggers_changed(on_group: int, for_tag: int, target_group: int, triggers: bool) -> void:
	active_preset.set_trigger_on_tag(
			on_group,
			for_tag,
			target_group,
			triggers)
	mark_trigger_dirty(on_group, for_tag)


#{"id": 0, "tag_name": "Yoshi", spicy_level: 10, explicit: false}
func _on_tag_searched(tag_string: String) -> void:
	var results: Array[Dictionary] = []
	var query_result: Array[Dictionary] = []
	
	if tag_string.is_empty():
		database.query(
				"SELECT * 
				FROM tags;")
	else:
		var pattern: String = tag_string + "%"
		database.query_with_bindings(
			"SELECT * FROM tags WHERE tag_name LIKE ?;",
			[pattern])
	
	for row in database.query_result:
		results.append({
			"id": row["id"],
			"tag_name": row["tag_name"],
			"explicit": row["explicit"] == 1,
			"spicy_level": row["spicy_level"],
			"reference": row["reference_url"] if typeof(row["reference_url"]) == TYPE_STRING else ""})
	
	tag_editor_window.set_tags(results)


func _on_create_group_pressed() -> void:
	var group_creator := preload("res://scripts/line_edit_confirmation_dialog.gd").new()
	group_creator.allow_empty = false
	group_creator.use_blacklist = true
	for idx in range(group_opt_btn.item_count):
		group_creator.text_blacklist.append(group_opt_btn.get_item_text(idx))
	add_child(group_creator)
	group_creator.popup()
	group_creator.grab_text_focus()
	
	var result: Array = await group_creator.dialog_finished
	
	if result[0]:
		if database.insert_row("tag_groups", {"group_name": result[1], "priority": 0}):
			var id: int = database.last_insert_rowid
			#group_opt_btn.add_item(result[1], id)
			active_preset.add_group(id, -1, 0)
			roll_set_up_window.add_group(id, result[1])
			add_tag_to_group_btn.disabled = false
			erase_group_btn.disabled = false
			prio_spn_bx.editable = true
			select_count_spn_bx.editable = true
			groups_window.add_group(
					id,
					result[1])
			group_opt_btn.select(group_opt_btn.item_count - 1)
			_on_group_selected(group_opt_btn.item_count - 1)
	
	group_creator.queue_free()


func _on_remove_group_pressed() -> void:
	selected_group = -1
	var group_id: int = group_opt_btn.get_selected_id()
	if database.query_with_bindings(
			"DELETE FROM tag_groups WHERE id = ?;",
			[group_id]):
		var next_selected: int = -1 if group_opt_btn.item_count - 1 == 0 else maxi(0, group_opt_btn.selected - 1)
		groups_window.remove_group(group_id)
		roll_set_up_window.remove_group(group_id)
		if -1 < next_selected:
			group_opt_btn.select(next_selected)
			_on_group_selected(next_selected)
		else:
			erase_group_btn.disabled = true
			add_tags_to_grp_btn.disabled = true
			groups_window.set_group_data({"select_count": 0, "priority": 0, "tags": []})


func _on_tag_removed_from_group(group_id: int, tag_id: int) -> void:
	database.query_with_bindings(
			"DELETE FROM group_tag_map WHERE group_id = ? AND tag_id = ?;",
			[group_id, tag_id])
	active_preset.remove_group_tag(group_id, tag_id)


func _on_tag_name_changed(tag_id: int, new_name: String) -> void:
	var success: bool = database.query_with_bindings(
			"UPDATE tags SET tag_name = ? WHERE id = ?;",
			[new_name, tag_id])
	
	if success:
		roll_set_up_window.set_tag_name(tag_id, new_name)
		groups_window.set_tag_name(tag_id, new_name)
	else:
		push_error("Error while updating tag: " + str(tag_id) + " to " + new_name)


func _on_spiciness_changed(tag_id: int, new_level: int) -> void:
	var success: bool = database.query_with_bindings(
			"UPDATE tags SET spicy_level = ? WHERE id = ?;",
			[new_level, tag_id])
	
	if not success:
		push_error("Error while updating spice from tag " + str(tag_id) + " to " + str(new_level))


func _on_explicit_changed(tag_id: int, is_explicit: bool) -> void:
	var success: bool = database.query_with_bindings(
			"UPDATE tags SET spicy_level = ? WHERE id = ?;",
			[int(is_explicit), tag_id])
	
	if not success:
		push_error("Error while updating Explicit for tag " + str(tag_id) + " to " + "True" if is_explicit else "False")


func _on_reference_changed(tag_id: int, url: String) -> void:
	var success: bool = database.query_with_bindings(
			"UPDATE tags SET reference_url = ? WHERE id = ?;",
			[url, tag_id])
	
	if not success:
		push_error("Error while updating reference for tag " + str(tag_id) + " to " + url)


func _on_tag_weight_changed(group_id: int, tag_id: int, new_weight: int) -> void:
	active_preset.set_tag_weight(group_id, tag_id, new_weight)


func _on_preset_saved(preset_id: int, preset_name: String, format_template: String, preset_data: Dictionary) -> void:
	var success: bool = true
	var abort_msg: String = "Associated Data Tables"
	
	for group_id in preset_data.keys():
		preset_data[group_id]["draw_count"] = active_preset.get_draw_count(group_id)
		for tag_dict in preset_data[group_id]["tags"]:
			tag_dict["tag_weight"] = active_preset.get_tag_weight(group_id, tag_dict["tag_id"])
			tag_dict["triggers"] = active_preset.get_trigger_groups(group_id, tag_dict["tag_id"])
	
	database.query("BEGIN TRANSACTION;")

# 1. UPSERT the main preset
	@warning_ignore("incompatible_ternary")
	var p_id_val = preset_id if preset_id != -1 else null
	success = database.query_with_bindings(
		"INSERT OR REPLACE INTO presets (id, preset_name, format_template) VALUES (?, ?, ?);",
		[p_id_val, preset_name, format_template])

	if not success:
		_abort_save("Main Preset Table")
		return

	# 2. Capture the actual ID we are working with
	# If we just inserted a brand-new preset, last_insert_rowid gives us the new ID.
	# If we overwrote, preset_id is our working ID.
	var working_id: int = database.last_insert_rowid if preset_id == -1 else preset_id

# 2. NUKE existing associations
	database.query_with_bindings("DELETE FROM preset_groups WHERE preset_id = ?;", [working_id])
	database.query_with_bindings("DELETE FROM preset_tags WHERE preset_id = ?;", [working_id])
#{group_id: {selection_state: 0, tags: {tag_id: 1, tag_enabled: 1}}} 
# 3. REBUILD
	for group_id in preset_data.keys():
		var g_data: Dictionary = preset_data[group_id]
	
	# Save Group Settings
		success = database.insert_row("preset_groups", {
			"preset_id": working_id,
			"group_id": group_id,
			"draw_count": active_preset.get_draw_count(group_id),
			"selection_state": g_data["selection_state"]})
	
		if not success:
			abort_msg = "Preset Groups Table"
			break
	
		for tag_dict in g_data["tags"]:
			var tag_id: int = tag_dict["tag_id"]
		
		# Save Tag selection
			success = database.insert_row("preset_tags", {
				"preset_id": working_id,
				"group_id": group_id,
				"tag_id": tag_id,
				"tag_enabled": tag_dict["tag_enabled"]})
			
			if not success:
				abort_msg = "Preset Tags Table"
				break
		
		# Global Weight Sync
			success = database.query_with_bindings(
				"UPDATE group_tag_map SET tag_weight = ? WHERE group_id = ? AND tag_id = ?;",
				[active_preset.get_tag_weight(group_id, tag_id), group_id, tag_id])
			
			if not success:
				abort_msg = "Group Tag Map Table"
				break
		
		# Trigger Refresh
			success = database.query_with_bindings(
				"DELETE FROM tag_triggers_groups WHERE tag_id = ? AND group_id = ?;",
				[tag_id, group_id])
			
			if not success:
				abort_msg = "Tag Trigger Groups Refresh"
			
			var triggers: Array[int] = active_preset.get_trigger_groups(group_id, tag_id)
			for target_group_id in triggers:
				database.insert_row(
						"tag_triggers_groups",
						{
						"tag_id": tag_id,
						"group_id": group_id,
						"triggers_group": target_group_id})
			
			if not success:
				abort_msg = "Tag Triggers Table"
				break
	
		if not success:
			break

# 4. FINAL VERDICT
	if success:
		database.query("COMMIT;")
		if preset_id == -1:
			preset_opt_btn.add_item(preset_name, working_id)
			preset_opt_btn.select(preset_opt_btn.item_count - 1)
	else:
		_abort_save(abort_msg)


func _abort_save(location: String) -> void:
	database.query("ROLLBACK;")
	push_error("DATABASE CRITICAL: Save failed at %s. Rollback initiated." % location)


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
	
	#[[{"tag_id": 1, "tag_name": "", group_id: 3}], []...]
	var format_tags: Array[Array] = prompt_tags_tree.get_tags(true)
	#[[{"tag_id": 1, "tag_name": "", group_id: 3}, {}...]]
	var extra_tags: Array[Array] = prompt_tags_tree.get_tags(false)
	
	var jobs_strings: Array[Array] = []
	var extra_strings: Array[String] = []
	
	var format_strings: Array[String] = []
	
	for format_job in format_tags:
		var job_array: Array[String] = []
		for tag_dict:Dictionary in format_job:
			if tag_dict["tag_id"] == -1:
				job_array.append("")
				continue
			var trigger_string: String = get_trigger_groups_string_of(
					tag_dict["group_id"],
					tag_dict["tag_id"],
					prompt_tags_tree.group_modes)
			
			var tag_text: String = ""
			if prompt_tags_tree.tag_pool.has_tag_reference(tag_dict["tag_id"]):
				tag_text = str(
						"[color=LIGHT_SKY_BLUE][url=",
						prompt_tags_tree.tag_pool.get_tag_reference(tag_dict["tag_id"]),
						"]",
						tag_dict["tag_name"],
						"[/url][/color]")
			else:
				tag_text = tag_dict["tag_name"]
			
			job_array.append(tag_text + trigger_string)
		jobs_strings.append(job_array)
	
	if not extra_tags.is_empty():
		for extra_job:Dictionary in extra_tags[0]:
			var extra_trigger: String = get_trigger_groups_string_of(
					extra_job["group_id"],
					extra_job["tag_id"],
					prompt_tags_tree.group_modes)
			var extra_tag_name: String = ""
			if prompt_tags_tree.tag_pool.has_tag_reference(extra_job["tag_id"]):
				extra_tag_name = str(
					"[color=LIGHT_SKY_BLUE][url=",
					prompt_tags_tree.tag_pool.get_tag_reference(extra_job["tag_id"]),
					"]",
					extra_job["tag_name"],
					"[/url][/color]")
			else:
				extra_tag_name = extra_job["tag_name"]
			
			extra_strings.append(extra_tag_name + extra_trigger)
	
	for string_array in jobs_strings:
		format_strings.append(
				array_to_promt(string_array))
	
	var formated_prompt: String = prompt_tags_tree.target_prompt.format(
		format_strings)
	
	var extra_prompt: String = ", ".join(extra_strings)
	var final_text: String = formated_prompt
	if not extra_prompt.is_empty():
		final_text += ("" if formated_prompt.is_empty() else "\n") + extra_prompt
		#selected_tags_txt_edt.text += ("" if formated_prompt.is_empty() else "\n") + extra_prompt
	
	selected_tags_rtl.text = final_text
	
	second_timer.start.call_deferred()
	switch_to_window(countdown_window)


func _on_roll_done_pressed() -> void:
	roll_set_up_window._save_current_state()
	switch_to_window(main_window)


func _on_pause_timer_pressed() -> void:
	second_timer.paused = not second_timer.paused
	if second_timer.paused:
		pause_time_btn.text = "Resume Timer"
	else:
		pause_time_btn.text = "Pause Timer"


func _on_stop_timer_pressed() -> void:
	if not second_timer.is_stopped():
		second_timer.stop()
	if second_timer.paused:
		second_timer.paused = false
	stop_time_btn.visible = false
	pause_time_btn.visible = false
	pause_time_btn.text = "Pause Timer"
	return_btn.visible = true


func _on_return_timer_pressed() -> void:
	switch_to_window(main_window)
	if not OS.has_feature("editor"):
		var window: Window = get_window()
		if window.size.y == 270:
			window.size.y = 600
		window.min_size.y = 600


func _on_timer_label_meta_clicked(meta: Variant) -> void:
	if typeof(meta) != TYPE_STRING:
		return
	if meta.is_empty():
		return
	
	var url: String = meta.strip_edges().replace("\\", "/")
	if url[1] == ":" and url[2] == "/": # It's a path
		var extension: String = url.get_extension()
		
		if extension in ["exe", "bat", "sh", "msi", "cmd"]:
			push_error("WARNING: Execution of binaries is prohibited. Stopped ", url, " from executing.")
			return
		elif not extension.is_empty():
			if FileAccess.file_exists(url):
				OS.shell_open(url) # Should be safe files now.
			else:
				push_error("ERROR: File " + url + " wasn't found.")
		else: # It's a folder path. Safe to open. Check first
			if DirAccess.dir_exists_absolute(url): # Directory exists. We're sure. Open it
				OS.shell_open(url)
			else:
				push_error("ERROR: Directory " + url + " wasn't found.")
	else: # It's not a file, it's an url.
		var sanitized_url: String = url
		if not sanitized_url.begins_with("http"):
			sanitized_url = "https://" + url
		OS.shell_open(sanitized_url) # Pass to browser. It is more secure than us.


func _on_roll_for_tags_pressed() -> void:
	prompt_tags_tree.clear_tags()
	
	var group_map: Dictionary[String, int] = {} # Maps the text to the group ID
	var group_modes: Dictionary[int, int] = {} # Group ID: mode
	var used_groups: Dictionary[int, bool] = {} # Group ID: used
	var group_priorities: Array[int] = []
	var use_preset: bool = preset_opt_btn.selected != 1
	#var preset_format_items: Array[String] = []
	#var extra_tags: Array[String] = []
	#var prompt: String = 
	
	var possible_tags: TagPool = get_tags_from_db(
			int(spicy_spn_bx.value),
			enable_nsfw_chk_btn.button_pressed) 
	
	# {"id": item.group_id, "name": item.get_group_name(), "mode": item.current_mode}
	# Since we passed true, only groups with mode 0 and 1 will be included
	for item in roll_set_up_window.get_group_names_mode(use_preset):
		group_map[item["name"]] = item["id"]
		group_modes[item["id"]] = item["mode"] if use_preset else 0
		used_groups[item["id"]] = false #target_preset.get_draw_count(item["id"])
	
	var groups_query: String = "(" + ", ".join(used_groups.keys()) + ")"
	database.query(
			"SELECT id, priority 
			FROM tag_groups 
			WHERE id IN " + groups_query + " 
			ORDER BY priority DESC;")
	
	for result in database.query_result:
		group_priorities.append(result["id"])
	#{
		#"format_string": "{0} {1}",
		#"tasks": [
			#{"group_name": "n", "count": 1, "chance": 100.0}],
			#["group_name": "y", "chance": 50.0, "tag_name": "a"]}
	var template_data: Dictionary = parse_prompt_template(roll_set_up_window.get_prompt())
	
	prompt_tags_tree.target_prompt = template_data["format_string"]
	prompt_tags_tree.group_modes = group_modes
	prompt_tags_tree.tag_pool = possible_tags
	
	var task_idx: int = -1
	for task in template_data["tasks"]:
		task_idx += 1
		if task.has("count"):
			if not group_map.has(task["group_name"]) or task["count"] == 0:
				prompt_tags_tree.add_tag("", -1, -1, task_idx)
				continue
			
			var group_id: int = group_map[task["group_name"]]
			# task.count == -1 -> Use the defined amount on the preset
			if task["chance"] < 100.0:
				if task["chance"] <= 0:
					prompt_tags_tree.add_tag("", -1, -1, task_idx)
					continue
				else:
					var chance_roll: float = randf_range(0.0, 100.0)
					if task["chance"] < chance_roll:
						prompt_tags_tree.add_tag("", -1, -1, task_idx)
						continue
		
			var picked_items: Array[Dictionary] = possible_tags.pick_from_group_pool(
					group_id,
					active_preset.get_draw_count(group_id) if task["count"] < 0 else task["count"])
		
			if picked_items.is_empty():
				prompt_tags_tree.add_tag("", -1, -1, task_idx)
			else:
				for tag_dict in picked_items:
					prompt_tags_tree.add_tag(
							tag_dict["name"],
							tag_dict["id"],
							group_id,
							task_idx)#items[item_id], item_id, group_id, task_idx)
			used_groups[group_map[task["group_name"]]] = true
		else:
			var group_id: int = -1
			var tag_id: int = -1
			
			if not group_map.has(task["group_name"]):
				group_id = roll_set_up_window.get_group_id_by_name(task["group_name"])
			else:
				group_id = group_map[task["group_name"]]
			
			tag_id = roll_set_up_window.get_tag_id_by_name_and_group(group_id, task["tag_name"])
			
			if group_id == -1 or tag_id == -1:
				prompt_tags_tree.add_tag("", -1, -1, task_idx)
				continue
			elif task["chance"] < 100.0:
				if task["chance"] <= 0:
					prompt_tags_tree.add_tag("", -1, -1, task_idx)
					continue
				else:
					var chance_roll: float = randf_range(0.0, 100.0)
					if task["chance"] < chance_roll:
						prompt_tags_tree.add_tag("", -1, -1, task_idx)
						continue
		
			prompt_tags_tree.add_tag(
					task["tag_name"],
					tag_id,
					group_id,
					task_idx,
					false)
			
			used_groups[group_id] = true
	
	for group_id in group_priorities:
		if group_modes[group_id] != 0 or used_groups[group_id]:
			continue
		
		var extra_items: Array[Dictionary] = possible_tags.pick_from_group_pool(
				group_id,
				active_preset.get_draw_count(group_id))
		
		if extra_items.is_empty():
			continue
		
		for extra_dict in extra_items:
			prompt_tags_tree.add_tag(
					extra_dict["name"],
					extra_dict["id"],
					group_id,
					-1)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if database != null:
			if active_preset.priorities_updated:
				var commit: bool = true
				database.query("BEGIN TRANSACTION;")
				for group_row:Dictionary in database.select_rows("tag_groups", "", ["id", "priority"]):
					if group_row["priority"] != active_preset.get_priority(group_row["id"]):
						if not database.query_with_bindings(
								"UPDATE tag_groups SET priority = ? WHERE id = ?;",
								[active_preset.get_priority(group_row["id"]), group_row["id"]]):
							commit = false
							break
				if commit:
					database.query("COMMIT;")
				else:
					database.query("ROLLBACK;")
			
			if not _dirty_trigger_pairs.is_empty():
				var success: bool = true
				database.query("BEGIN TRANSACTION;")
				for group_id in _dirty_trigger_pairs.keys():
					var tag_ids: Array = _dirty_trigger_pairs[group_id].keys()
					for tag_id in tag_ids:
						success = database.query_with_bindings(
								"DELETE FROM tag_triggers_groups WHERE group_id = ? AND tag_id = ?;",
								[group_id, tag_id])
						if not success:
							break
						
						var triggers: Array[int] = active_preset.get_trigger_groups(group_id, tag_id)
						
						if not triggers.is_empty():
							#var new_rows: Array[Dictionary] = []
							for trigger_group in triggers:
								success = database.insert_row(
									"tag_triggers_groups",
									{
										"tag_id": tag_id,
										"group_id": group_id,
										"triggers_group": trigger_group})
								if not success:
									break
							
							if not success:
								break
					if not success:
						break
				if success:
					database.query("COMMIT;")
				else:
					database.query("ROLLBACK;")
			
			database.close_db()
		
		if not second_timer.is_stopped():
			second_timer.stop()
		
		var time: int = 0
		time += int(hour_spn_bx.value) * 3600
		time += int(min_spn_bx.value) * 60
		time += int(sec_spn_bx.value)
		
		var cfg: ConfigFile = ConfigFile.new()
		cfg.set_value("MAIN", "use_nsfw", enable_nsfw_chk_btn.button_pressed)
		cfg.set_value("MAIN", "spicyness", int(spicy_spn_bx.value))
		cfg.set_value("MAIN", "timer", time)
		cfg.set_value("TAG_EDITOR", "items_per_page", tag_editor_window.items_per_page)
		
		cfg.save(ProjectSettings.globalize_path("user://main.cfg"))
		
		get_tree().quit()
