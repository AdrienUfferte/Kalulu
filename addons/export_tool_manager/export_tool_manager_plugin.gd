@tool
extends EditorPlugin

const EXPORTER_PATH: String = "res://addons/export_tool_manager/export_tool_exporter.gd"

var tool_selector: OptionButton
var exporter_plugin: EditorExportPlugin
var export_button: Button

func _enter_tree() -> void:
	# Tool Selector UI
	tool_selector = OptionButton.new()
	tool_selector.name = "Tool Exporter"
	tool_selector.add_item("Game")
	tool_selector.add_item("Prof Tool")
	tool_selector.connect("item_selected", _on_tool_selected)
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, tool_selector)

	var settings: EditorSettings = get_editor_interface().get_editor_settings()
	var current := settings.get_setting("export_tool_manager/current_tool")
	var current_tool := "game"

	if typeof(current) == TYPE_STRING and current.strip_edges() != "":
		current_tool = current.strip_edges()

	match current_tool:
		"prof_tool":
			tool_selector.select(1)
		"game", _:
			tool_selector.select(0)

	# Exporter plugin
	exporter_plugin = load(EXPORTER_PATH).new()
	add_export_plugin(exporter_plugin)

	# Export All Button
	export_button = Button.new()
	export_button.text = "Export All (Game)"
	export_button.pressed.connect(_on_export_all_game_pressed)
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, export_button)

func _exit_tree() -> void:
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, tool_selector)
	tool_selector.queue_free()

	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, export_button)
	export_button.queue_free()

	remove_export_plugin(exporter_plugin)

func _on_tool_selected(index: int) -> void:
	var tool := "game"
	match index:
		1:
			tool = "prof_tool"
		0, _:
			tool = "game"

	var settings := get_editor_interface().get_editor_settings()
	settings.set_setting("export_tool_manager/current_tool", tool)

func _on_export_all_game_pressed():
	export_all_game_presets()

func export_all_game_presets():
	var godot_path := OS.get_executable_path()
	var presets := {
		"Android Kalulu AAB": "../Export/autobuilds/Android/kalulu_app.aab",
		"Android Kalulu APK": "../Export/autobuilds/Android/kalulu_app.apk",
		"Windows Kalulu": "../Export/autobuilds/Windows/Kalulu.exe",
		"Linux Kalulu": "../Export/autobuilds/Linux/Kalulu.x86_64",
		
		# Apple in last because it's always the most complicated
		#"iOS Kalulu": "../Export/autobuilds/iOS/KaluluApp.ipa",
		#"macOS Kalulu": "../Export/autobuilds/macOS/Kalulu.dmg"
	}

	for preset_name in presets.keys():
		await get_tree().create_timer(1).timeout
		var output_path: String = presets[preset_name]
		DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())

		var args := ["--headless", "--export-release", preset_name, output_path]
		var output := []
		var result := OS.execute(godot_path, args, output, true)

		if result != OK:
			push_error("Export failed for %s (%s)\nOutput:\n%s" % [
				preset_name, output_path, "\n".join(PackedStringArray(output))
			])
			return
		else:
			print("✔ Export success : %s → %s" % [preset_name, output_path])
