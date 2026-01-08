extends HBoxContainer


signal group_selected(node)


var current_mode: int = 0
var group_id: int = 0

@onready var group_button: Button = $GroupButton
@onready var menu_button: MenuButton = $MenuButton


func _ready() -> void:
	menu_button.get_popup().id_pressed.connect(_on_popup_id_pressed)
	group_button.toggled.connect(_on_group_button_toggled)


func set_group_name(group_name: String) -> void:
	group_button.text = group_name
	group_button.set_meta(&"group_format", "{" + group_name + "}")


func get_group_name() -> String:
	return group_button.text


func set_group_mode(mode: int) -> void:
	var pp: PopupMenu = menu_button.get_popup()
	menu_button.icon = pp.get_item_icon(pp.get_item_index(mode))
	current_mode = mode


func set_group_selected(selected: bool) -> void:
	group_button.set_pressed_no_signal(selected)
	if selected == false:
		group_button.button_mask = MOUSE_BUTTON_MASK_LEFT


func _on_group_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		group_selected.emit(self)
	else:
		group_button.set_pressed_no_signal(true)


func _on_popup_id_pressed(id: int) -> void:
	if id == current_mode:
		return
	set_group_mode(id)
