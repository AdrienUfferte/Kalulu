@tool
extends Resource
class_name DeviceSettings


const supported_locales: Array[String] = [
	# French France
	"fr_FR",
	# Spanish Argentina
	"es_AR",
	# Spanish Uruguay
	"es_UY",
	# Spanish Colombia
	"es_CO",
	# Portuguese Brazil
	"pt_BR"
]

@export var language : String :
	set(value):
		language = value
		Database.language = value
		TranslationServer.set_locale(value)
		print("DeviceSettings: language SET: " + TranslationServer.get_locale())
@export var teacher : String
@export var device_id : int
@export var language_versions: Dictionary = {} # locale : datetime

@export var master_volume: float = 0.0 :
	set(volume):
		master_volume = volume
		var ind: int = AudioServer.get_bus_index("Master")
		AudioServer.set_bus_volume_db(ind, volume)

@export var music_volume: float = 0.0 :
	set(volume):
		music_volume = volume
		var ind: int = AudioServer.get_bus_index("Music")
		AudioServer.set_bus_volume_db(ind, volume)

@export var voice_volume: float = 0.0 :
	set(volume):
		voice_volume = volume
		var ind: int = AudioServer.get_bus_index("Voice")
		AudioServer.set_bus_volume_db(ind, volume)

@export var effects_volume: float = 0.0 :
	set(volume):
		effects_volume = volume
		var ind: int = AudioServer.get_bus_index("Effects")
		AudioServer.set_bus_volume_db(ind, volume)


func init_OS_language() -> void:
	# Gets the OS language and checks if it is supported
	var osLanguage: String = OS.get_locale();
	if osLanguage and osLanguage in supported_locales:
		language = osLanguage
	
	if not language:
		language = supported_locales[0]


func get_folder_path() -> String:
	var file_path: String = "user://".path_join(teacher).path_join(str(device_id)).path_join(language)
	return file_path


func validate() -> bool:
	if language not in supported_locales:
		init_OS_language()
		return false
	return true
