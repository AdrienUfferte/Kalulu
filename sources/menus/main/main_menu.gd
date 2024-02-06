extends Control

const next_scene_path := "res://sources/menus/login/login.tscn"
const register_scene_path := "res://sources/menus/register/register.tscn"

@onready var version_label : Label = $Informations/BuildVersionValue
@onready var teacher_label : Label = $Informations/TeacherValue
@onready var device_id_label : Label = $Informations/DeviceIDValue

@onready var kalulu : Control = $Kalulu
@onready var user_selection : Control = $UserSelection
@onready var login : Control = $Login


func _ready():
	version_label.text = ProjectSettings.get_setting("application/config/version")
	teacher_label.text = UserDataManager.get_device_settings().teacher
	device_id_label.text = str(UserDataManager.get_device_settings().device_id)


func _on_main_button_pressed():
	if UserDataManager.get_device_settings().teacher:
		get_tree().change_scene_to_file(next_scene_path)
	else:
		kalulu.hide()
		kalulu.stop_speech()
		user_selection.show()


func _on_sign_in_teacher_pressed():
	user_selection.hide()
	login.show()


func _on_back_button_pressed():
	login.hide()
	kalulu.show()
	kalulu.start_speech()


func _on_login_in():
	get_tree().change_scene_to_file(next_scene_path)


func _on_register_pressed():
	get_tree().change_scene_to_file(register_scene_path)
