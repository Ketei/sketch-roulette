extends VBoxContainer

signal tag_name_changed(tag_id: int, new_name: String)
signal spiciness_changed(tag_id: int, new_level: int)
signal explicit_changed(tag_id: int, is_explicit: bool)
signal reference_changed(tag_id: int, url: String)
signal tag_searched(tag_string: String)

const TAG_ITEM_ENTRY = preload("res://scenes/tag_item_entry.tscn")

var items_per_page: int = 12
var pages: Array[Dictionary] = []
var step: int = 1
var page_count: int = 1

@onready var tag_editor_entries: VBoxContainer = $ScrollContainer/TagEditorEntries
@onready var page_counter_label: Label = $HBoxContainer/PageCounterLabel
@onready var prev_page_btn: Button = $HBoxContainer/PrevPageBtn
@onready var next_page_btn: Button = $HBoxContainer/NextPageBtn
@onready var search_tag: LineEdit = $SearchTag


func _ready() -> void:
	prev_page_btn.pressed.connect(_on_prev_page_pressed)
	next_page_btn.pressed.connect(_on_next_page_pressed)
	search_tag.text_submitted.connect(_on_search_tag_text_submitted)


#{"id": 0, "tag_name": "Yoshi", spicy_level: 10, explicit: false, reference: ""}
func set_tags(tags: Array[Dictionary]) -> void:
	for item in tag_editor_entries.get_children():
		item.tag_name_changed.disconnect(_on_item_entry_tag_name_changed)
		item.spiciness_changed.disconnect(_on_item_entry_spiciness_changed)
		item.explicitness_changed.disconnect(_on_hornyness_changed)
		item.reference_changed.disconnect(_on_reference_changed)
		tag_editor_entries.remove_child(item)
		item.queue_free()
	
	pages.assign(tags)
	step = 1
	
	page_count = maxi(1, ceili(float(tags.size()) / float(items_per_page)))
	
	var first_slice: Array = tags.slice(0, 12)
	
	for item in first_slice:
		var new_item: TagItemEntry = TAG_ITEM_ENTRY.instantiate()
		tag_editor_entries.add_child(new_item)
		new_item.set_data(item["id"], item["tag_name"], item["spicy_level"], item["explicit"], item["reference"])
		new_item.tag_name_changed.connect(_on_item_entry_tag_name_changed)
		new_item.spiciness_changed.connect(_on_item_entry_spiciness_changed)
		new_item.explicitness_changed.connect(_on_hornyness_changed)
		new_item.reference_changed.connect(_on_reference_changed)
	
	page_counter_label.text = str(step, "/", page_count)
	
	prev_page_btn.disabled = true
	next_page_btn.disabled = page_count <= 1


func _on_search_tag_text_submitted(text: String) -> void:
	tag_searched.emit(text.strip_edges())


func _on_next_page_pressed() -> void:
	var from_slice: int = items_per_page * step
	var to_slice: int = items_per_page * (step + 1)
	
	var new_slice: Array = pages.slice(from_slice, to_slice)
	
	for item in tag_editor_entries.get_children():
		item.tag_name_changed.disconnect(_on_item_entry_tag_name_changed)
		item.spiciness_changed.disconnect(_on_item_entry_spiciness_changed)
		tag_editor_entries.remove_child(item)
		item.queue_free()
	
	for item in new_slice:
		var new_item: TagItemEntry = TAG_ITEM_ENTRY.instantiate()
		tag_editor_entries.add_child(new_item)
		new_item.set_data(item["id"], item["tag_name"], item["spicy_level"], item["explicit"])
		new_item.tag_name_changed.connect(_on_item_entry_tag_name_changed)
		new_item.spiciness_changed.connect(_on_item_entry_spiciness_changed)
	
	page_counter_label.text = str(step + 1, "/", page_count)
	
	prev_page_btn.disabled = false
	next_page_btn.disabled = step + 1 < page_count
	
	step += 1


func _on_prev_page_pressed() -> void:
	var from_slice: int = items_per_page * (step - 2)
	var to_slice: int = items_per_page * (step - 1)
	
	var new_slice: Array = pages.slice(from_slice, to_slice)
	
	for item in tag_editor_entries.get_children():
		item.tag_name_changed.disconnect(_on_item_entry_tag_name_changed)
		item.spiciness_changed.disconnect(_on_item_entry_spiciness_changed)
		tag_editor_entries.remove_child(item)
		item.queue_free()
	
	for item in new_slice:
		var new_item: TagItemEntry = TAG_ITEM_ENTRY.instantiate()
		tag_editor_entries.add_child(new_item)
		new_item.set_data(item["id"], item["tag_name"], item["spicy_level"], item["explicit"])
		new_item.tag_name_changed.connect(_on_item_entry_tag_name_changed)
		new_item.spiciness_changed.connect(_on_item_entry_spiciness_changed)
	
	page_counter_label.text = str(step - 1, "/", page_count)
	
	prev_page_btn.disabled = step - 1 <= 1
	next_page_btn.disabled = false
	
	step -= 1


func _on_item_entry_tag_name_changed(tag_id: int, new_name: String) -> void:
	tag_name_changed.emit(tag_id, new_name)


func _on_item_entry_spiciness_changed(tag_id: int, new_level: int) -> void:
	spiciness_changed.emit(tag_id, new_level)


func _on_hornyness_changed(tag_id: int, is_explicit: bool) -> void:
	explicit_changed.emit(tag_id, is_explicit)


func _on_reference_changed(tag_id: int, url: String) -> void:
	reference_changed.emit(tag_id, url)
