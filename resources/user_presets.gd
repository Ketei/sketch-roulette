class_name TagPresets
extends Resource


const FILE_PATH: String = "user://user_presets.tres"


@export var presets: Dictionary[StringName, Dictionary] = {
	#&"UUID": {
		#"name": "",
		#"categories": {
			#&"UUID_G": {
				#"active": false,
				#"count": 0,
				#"tags": {&"UUID": true}}}}
}


static func load_or_new() -> TagPresets:
	var pre: TagPresets = null
	var global_path: String = ProjectSettings.globalize_path(FILE_PATH)
	if FileAccess.file_exists(global_path):
		var res_pre: Resource = load(global_path)
		if res_pre is TagPresets:
			pre = res_pre
	
	if pre == null:
		pre = TagPresets.new()
	
	return pre


func sort_custom_name(a: StringName, b: StringName) -> bool:
	if not presets.has(a) or not presets.has(b):
		return false
	return presets[a]["name"].naturalnocasecmp_to(presets[b]["name"]) < 0


func create_preset(preset_name: String, data: Dictionary[StringName, Dictionary]) -> StringName:
	var uuid: StringName = StringName(UUID.generate_new())
	presets[uuid] = {
		"name": preset_name,
		"categories": data.duplicate(true)}
	return uuid


func set_preset_data(preset_id: StringName, data: Dictionary[StringName, Dictionary]) -> void:
	if presets.has(preset_id):
		presets[preset_id]["categories"].clear()
		presets[preset_id]["categories"].assign(data.duplicate(true))


func set_preset_name(preset_id: StringName, new_name: String) -> void:
	if presets.has(preset_id):
		presets[preset_id]["name"] = new_name


func erase_preset(preset_id: StringName) -> void:
	presets.erase(preset_id)


func save() -> void:
	ResourceSaver.save(
			self,
			ProjectSettings.globalize_path(FILE_PATH))
