class_name  TagItemEntry
extends HBoxContainer


signal tag_name_changed(tag_id: int, new_name: String)
signal spiciness_changed(tag_id: int, new_level: int)
signal explicitness_changed(tag_id: int, is_explicit: bool)
signal reference_changed(tag_id: int, url: String)

var _tag_id: int = 0
var _spice_level: int = 0
var _reference_path: String = ""
var data_ref: Dictionary = {}

@onready var name_container: HBoxContainer = $NamePanel/NameContainer
@onready var edit_container: HBoxContainer = $NamePanel/EditContainer
@onready var spicy_spn_bx: SpinBox = $SpicyContainer/SpicySpnBx
@onready var nsfw_check: CheckBox = $NSFWCheck

@onready var edit_btn: Button = $NamePanel/NameContainer/EditBtn
@onready var tag_label: Label = $NamePanel/NameContainer/TagLabel
@onready var save_btn: Button = $NamePanel/EditContainer/SaveBtn
@onready var tag_ln_edt: LineEdit = $NamePanel/EditContainer/TagLnEdt
@onready var reference_button: Button = $ReferenceButton




func _ready() -> void:
	edit_btn.pressed.connect(_on_edit_tag_pressed)
	tag_ln_edt.text_submitted.connect(_on_name_text_submitted)
	save_btn.pressed.connect(_on_save_name_pressed)
	nsfw_check.pressed.connect(_on_hornyness_toggled)
	reference_button.pressed.connect(_on_reference_button_pressed)
	spicy_spn_bx.value_changed.connect(_on_spiciness_level_value_changed)


func tag_id() -> int:
	return _tag_id


func tag_name() -> String:
	return tag_label.text


func set_data(id: int, new_name: String, spiciness: int, horny: bool, url: String = "") -> void:
	_tag_id = id
	tag_label.text = new_name
	_reference_path = url
	spicy_spn_bx.set_value_no_signal(spiciness)
	nsfw_check.set_pressed_no_signal(horny)


func _on_reference_button_pressed() -> void:
	var path_selector := preload("res://scripts/line_file_browser.gd").new()
	path_selector.allow_empty = false
	path_selector.title = "Reference"
	add_child(path_selector)
	path_selector.line_placeholder_text = "File path/URL"
	if not _reference_path.is_empty():
		path_selector.set_line_text(_reference_path)
	path_selector.popup()
	
	path_selector.grab_text_focus()
	path_selector.caret_to_end()
	path_selector.select_all_text()
	
	var result: Array = await path_selector.dialog_finished
	
	if result[0]:
		_reference_path = result[1]
		data_ref["reference"] = result[1]
		reference_changed.emit(_tag_id, result[1])
	path_selector.queue_free()


func _on_hornyness_toggled(is_toggled: bool) -> void:
	explicitness_changed.emit(_tag_id, is_toggled)
	data_ref["explicit"] = is_toggled


func _on_edit_tag_pressed() -> void:
	tag_ln_edt.text = tag_label.text
	
	name_container.visible = false
	edit_container.visible = true
	
	tag_ln_edt.grab_focus()
	tag_ln_edt.caret_column = tag_ln_edt.text.length()
	tag_ln_edt.select_all()


func _on_spiciness_level_value_changed(value: float) -> void:
	if int(value) == _spice_level:
		return
	_spice_level = int(value)
	data_ref["spicy_level"] = _spice_level
	spiciness_changed.emit(_tag_id, _spice_level)


func _on_name_text_submitted(new_text: String) -> void:
	new_text = new_text.strip_edges()
	name_container.visible = true
	edit_container.visible = false
	
	if new_text == tag_label.text or new_text.is_empty():
		return
	
	data_ref["tag_name"] = new_text
	tag_label.text = new_text
	tag_name_changed.emit(_tag_id, new_text)


func _on_save_name_pressed() -> void:
	_on_name_text_submitted(tag_ln_edt.text)
