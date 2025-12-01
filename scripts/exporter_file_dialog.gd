class_name DBExporter
extends FileDialog


signal path_selected(success: bool, path: String)


func _ready() -> void:
	file_mode = FileDialog.FILE_MODE_SAVE_FILE
	access = FileDialog.ACCESS_FILESYSTEM
	add_filter("*.json", "JSON files")
	use_native_dialog = true
	file_selected.connect(_on_file_selected)
	canceled.connect(_on_canceled)


func _on_canceled() -> void:
	path_selected.emit(false, "")


func _on_file_selected(path: String) -> void:
	if path.get_extension() != "json":
		path = path.get_basename() + ".json"
	
	path_selected.emit(true, path)
