extends FileDialog


signal dialog_finished(success: bool, resource_path: String)


func _ready() -> void:
	add_filter("*.png, *.jpg, *.jpeg, *.webp", "Images")
	use_native_dialog = true
	access = FileDialog.ACCESS_FILESYSTEM
	file_mode = FileDialog.FILE_MODE_OPEN_FILE
	size = Vector2i(850, 600)
	initial_position = WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	file_selected.connect(on_file_selected)
	canceled.connect(on_canceled)


func on_file_selected(file_path: String) -> void:
	dialog_finished.emit(true, file_path)


func on_canceled() -> void:
	dialog_finished.emit(false, "")
