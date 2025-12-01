class_name NotificationDialog
extends AcceptDialog


signal dialog_finished


func _ready() -> void:
	confirmed.connect(_on_confirmed)
	canceled.connect(_on_canceled)


func _on_confirmed() -> void:
	dialog_finished.emit()


func _on_canceled() -> void:
	dialog_finished.emit()
