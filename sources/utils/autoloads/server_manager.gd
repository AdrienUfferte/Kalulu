extends CanvasLayer
signal request_completed(code: int, body: Dictionary)
signal internet_check_completed(has_acces: bool)

@onready var internet_check: HTTPRequest = $InternetCheck
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var loading_rect: TextureRect = $TextureRect

const INTERNET_CHECK_URL: = "https://google.com"
const URL: = "https://uqkpbayw1k.execute-api.eu-west-3.amazonaws.com/prod/"

# Response from the last request
var code: int
var json: Dictionary


func check_email(email: String) -> Dictionary:
	loading_rect.show()
	await _get_request("checkemail", {"mail" : email})
	return _response()


func register(data: Dictionary) -> Dictionary:
	loading_rect.show()
	await _post_json_request("register", data)
	return _response()


func login(mail: String, password: String) -> Dictionary:
	loading_rect.show()
	await _get_request("login", {"mail": mail, "password": password})
	return _response()


func get_configuration() -> Dictionary:
	await _get_request("configuration", {})
	return _response()


func delete_account() -> Dictionary:
	loading_rect.show()
	await _delete_request("delete_account")
	return _response()


func get_language_pack_url(locale: String) -> Dictionary:
	await _get_request("language", {"locale": locale})
	return _response()

# p_student must have a device key
# it can contain a name, level and age key for parents
func add_student(p_student: Dictionary) -> Dictionary:
	await _post_request("add_student", p_student)
	return _response()


func update_student(p_name: String, level: StudentData.Level, age: int) -> Dictionary:
	await _post_request("update_student", {"name": p_name, "level": level, "age": age})
	return _response()


func remove_student(p_code: int) -> Dictionary:
	await _delete_request("remove_student", {"code": p_code})
	return _response()
	
#region Sender functions

func check_internet_access() -> bool:
	var res: = internet_check.request("https://google.com")
	if res == 0:
		return await internet_check_completed
	return false


func _create_URI_with_parameters(URI: String, params: Dictionary) -> String:
	var is_first_param: bool = true
	for key: String in params.keys():
		if is_first_param:
			URI += "?"
			is_first_param = false
		else:
			URI += "&"
		URI += str(key) + "=" + str(params[key])
	return URI

func _create_request_headers() -> PackedStringArray:
	var headers: PackedStringArray = []
	var teacher_settings: TeacherSettings = UserDataManager.teacher_settings
	if teacher_settings and teacher_settings.token:
		headers.append("Authorization: Bearer " + teacher_settings.token)
	return headers


func _response() -> Dictionary:
	var res: = {
			"code" : code,
			"body" : json
		}
	return res


func _get_request(URI: String, params: Dictionary) -> void:
	code = 0
	json = {}
	
	if http_request.request(_create_URI_with_parameters(URL + URI, params), _create_request_headers()) == 0:
		await request_completed
	else:
		code = 500
		json = {message = "Internal Server Error"}


func _post_request(URI: String, params: Dictionary) -> void:
	code = 0
	json = {}
	
	if http_request.request(_create_URI_with_parameters(URL + URI, params), _create_request_headers(), HTTPClient.METHOD_POST, "") == 0:
		await request_completed
	else:
		code = 500
		json = {message = "Internal Server Error"}


func _post_json_request(URI: String, data: Dictionary) -> void:
	code = 0
	json = {}
	
	var req: = URL + URI
	var headers: = _create_request_headers()
	headers.append("Content-Type: application/json")
	
	if http_request.request(req, headers, HTTPClient.METHOD_POST, JSON.stringify(data)) == 0:
		await request_completed
	else:
		code = 500
		json = {message = "Internal Server Error"}


func _delete_request(URI: String, params: Dictionary = {}) -> void:
	code = 0
	json = {}
	
	var req: = _create_URI_with_parameters(URL + URI, params)
	var headers: = _create_request_headers()
	
	if http_request.request(req, headers, HTTPClient.METHOD_DELETE, "") == 0:
		await request_completed
	else:
		code = 500
		json = {message = "Internal Server Error"}

#endregion

func _on_http_request_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	code = response_code
	if body:
		json = JSON.parse_string(body.get_string_from_utf8())
	request_completed.emit(response_code, json)
	
	loading_rect.hide()


func _on_internet_check_request_completed(_result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	internet_check_completed.emit(response_code == 200)
