class_name GodotVault
extends Node

# GodotVault - Supabase APIクライアント
# 使用方法:
# 1. シーンにGodotVaultノードを追加
# 2. await login(email, password) でログイン
# 3. await save_data(key, data) でデータ保存
# 4. var data = await load_data(key) でデータ読み込み

signal login_completed(success: bool)
signal logout_completed(success: bool)

const API_BASE_URL = "http://localhost:3000"

var current_email: String = ""
var current_password: String = ""
var access_token: String = ""
var is_logged_in: bool = false

func _ready():
	load_session()

# セッション情報を保存
func save_session():
	var config = ConfigFile.new()
	config.set_value("auth", "email", current_email)
	config.set_value("auth", "password", current_password)
	config.set_value("auth", "access_token", access_token)
	config.save("user://godot_vault_session.cfg")

# セッション情報を読み込み
func load_session():
	var config = ConfigFile.new()
	var err = config.load("user://godot_vault_session.cfg")
	if err == OK:
		current_email = config.get_value("auth", "email", "")
		current_password = config.get_value("auth", "password", "")
		access_token = config.get_value("auth", "access_token", "")
		if current_email != "" and access_token != "":
			is_logged_in = true
			print("GodotVault: セッション復元完了")
		else:
			is_logged_in = false

# セッション情報をクリア
func clear_session():
	current_email = ""
	current_password = ""
	access_token = ""
	is_logged_in = false
	var config = ConfigFile.new()
	config.save("user://godot_vault_session.cfg")

# ランダムメールアドレス生成
func generate_random_email() -> String:
	var chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	var result = ""
	for i in range(8):
		result += chars[randi() % chars.length()]
	return result + "@example.com"

# ランダムパスワード生成
func generate_random_password() -> String:
	var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var result = ""
	for i in range(12):
		result += chars[randi() % chars.length()]
	return result

# ユーザー登録
func signup(email: String = "", password: String = "") -> bool:
	if email == "":
		email = generate_random_email()
	if password == "":
		password = generate_random_password()
	
	current_email = email
	current_password = password
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var data = {
		"email": email,
		"password": password
	}
	var json_string = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	var url = API_BASE_URL + "/auth/signup"
	
	print("GodotVault: ユーザー登録中... (", email, ")")
	http_request.request(url, headers, HTTPClient.METHOD_POST, json_string)
	
	var response = await http_request.request_completed
	http_request.queue_free()
	
	var result: int = response[0]
	var response_code: int = response[1]
	var response_headers: PackedStringArray = response[2]
	var body: PackedByteArray = response[3]
	
	if response_code == 200:
		var response_text = body.get_string_from_utf8()
		var json = JSON.new()
		var parse_result = json.parse(response_text)
		if parse_result == OK:
			var response_data = json.data
			if "session" in response_data and response_data.session != null:
				access_token = response_data.session.access_token
				is_logged_in = true
				save_session()
				login_completed.emit(true)
				print("GodotVault: ユーザー登録完了")
				return true
			else:
				login_completed.emit(false)
				return false
		else:
			login_completed.emit(false)
			return false
	else:
		login_completed.emit(false)
		return false

# ログイン
func login(email: String, password: String) -> bool:
	current_email = email
	current_password = password
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var data = {
		"email": email,
		"password": password
	}
	var json_string = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	var url = API_BASE_URL + "/auth/login"
	
	print("GodotVault: ログイン中...")
	http_request.request(url, headers, HTTPClient.METHOD_POST, json_string)
	
	var response = await http_request.request_completed
	http_request.queue_free()
	
	var result: int = response[0]
	var response_code: int = response[1]
	var response_headers: PackedStringArray = response[2]
	var body: PackedByteArray = response[3]
	
	if response_code == 200:
		var response_text = body.get_string_from_utf8()
		var json = JSON.new()
		var parse_result = json.parse(response_text)
		if parse_result == OK:
			var response_data = json.data
			if "session" in response_data and response_data.session != null:
				access_token = response_data.session.access_token
				is_logged_in = true
				save_session()
				login_completed.emit(true)
				print("GodotVault: ログイン完了")
				return true
			else:
				login_completed.emit(false)
				return false
		else:
			login_completed.emit(false)
			return false
	else:
		login_completed.emit(false)
		return false

# ログアウト
func logout() -> bool:
	if not is_logged_in:
		logout_completed.emit(false)
		return false
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + access_token
	]
	var url = API_BASE_URL + "/auth/logout"
	
	print("GodotVault: ログアウト中...")
	http_request.request(url, headers, HTTPClient.METHOD_POST)
	
	var response = await http_request.request_completed
	http_request.queue_free()
	
	clear_session()
	logout_completed.emit(true)
	print("GodotVault: ログアウト完了")
	return true

# データ保存
func save_data(key: String, data) -> bool:
	if not is_logged_in:
		return false
	
	if key == "":
		return false
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var request_data = {
		"json_data": data
	}
	var json_string = JSON.stringify(request_data)
	
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + access_token
	]
	var url = API_BASE_URL + "/data/" + key
	
	print("GodotVault: データ保存中... (key: ", key, ")")
	http_request.request(url, headers, HTTPClient.METHOD_PUT, json_string)
	
	var response = await http_request.request_completed
	http_request.queue_free()
	
	var result: int = response[0]
	var response_code: int = response[1]
	var response_headers: PackedStringArray = response[2]
	var body: PackedByteArray = response[3]
	
	if response_code == 200:
		print("GodotVault: データ保存完了 (key: ", key, ")")
		return true
	else:
		var response_text = body.get_string_from_utf8()
		print("GodotVault: データ保存に失敗: ", response_text)
		return false

# データ読み込み
func load_data(key: String):
	if not is_logged_in:
		return null
	
	if key == "":
		return null
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var headers = [
		"Authorization: Bearer " + access_token
	]
	var url = API_BASE_URL + "/data/my/" + key
	
	print("GodotVault: データ読み込み中... (key: ", key, ")")
	http_request.request(url, headers, HTTPClient.METHOD_GET)
	
	var response = await http_request.request_completed
	http_request.queue_free()
	
	var result: int = response[0]
	var response_code: int = response[1]
	var response_headers: PackedStringArray = response[2]
	var body: PackedByteArray = response[3]
	
	if response_code == 200:
		var response_text = body.get_string_from_utf8()
		var json = JSON.new()
		var parse_result = json.parse(response_text)
		if parse_result == OK:
			var response_data = json.data
			if "data" in response_data:
				var json_data = response_data.data.json_data
				print("GodotVault: データ読み込み完了 (key: ", key, ")")
				return json_data
			else:
				print("GodotVault: データが見つかりません (key: ", key, ")")
				return null
		else:
			print("GodotVault: レスポンスの解析に失敗しました")
			return null
	else:
		var response_text = body.get_string_from_utf8()
		print("GodotVault: データの読み込みに失敗: ", response_text)
		return null

# データ削除
func delete_data(key: String) -> bool:
	if not is_logged_in:
		return false
	
	if key == "":
		return false
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var headers = [
		"Authorization: Bearer " + access_token
	]
	var url = API_BASE_URL + "/data/my/" + key
	
	print("GodotVault: データ削除中... (key: ", key, ")")
	http_request.request(url, headers, HTTPClient.METHOD_DELETE)
	
	var response = await http_request.request_completed
	http_request.queue_free()
	
	var result: int = response[0]
	var response_code: int = response[1]
	var response_headers: PackedStringArray = response[2]
	var body: PackedByteArray = response[3]
	
	if response_code == 200:
		print("GodotVault: データ削除完了 (key: ", key, ")")
		return true
	else:
		var response_text = body.get_string_from_utf8()
		print("GodotVault: データ削除に失敗: ", response_text)
		return false

# 自分のデータ一覧取得
func get_my_data_list(page: int = 1, limit: int = 50, key_pattern: String = ""):
	if not is_logged_in:
		return null
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var query = "?page=" + str(page) + "&limit=" + str(limit)
	if key_pattern != "":
		query += "&key_pattern=" + key_pattern
	
	var headers = [
		"Authorization: Bearer " + access_token
	]
	var url = API_BASE_URL + "/data/my" + query
	
	print("GodotVault: 自分のデータ一覧取得中...")
	http_request.request(url, headers, HTTPClient.METHOD_GET)
	
	var response = await http_request.request_completed
	http_request.queue_free()
	
	var result: int = response[0]
	var response_code: int = response[1]
	var response_headers: PackedStringArray = response[2]
	var body: PackedByteArray = response[3]
	
	if response_code == 200:
		var response_text = body.get_string_from_utf8()
		var json = JSON.new()
		var parse_result = json.parse(response_text)
		if parse_result == OK:
			var response_data = json.data
			print("GodotVault: 自分のデータ一覧取得完了")
			return response_data
		else:
			print("GodotVault: レスポンスの解析に失敗しました")
			return null
	else:
		var response_text = body.get_string_from_utf8()
		print("GodotVault: 自分のデータ一覧取得に失敗: ", response_text)
		return null

# 特定キーの全ユーザーデータ取得
func get_all_data_by_key(key: String, page: int = 1, limit: int = 50):
	if not is_logged_in:
		return null
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var query = "?page=" + str(page) + "&limit=" + str(limit)
	
	var headers = [
		"Authorization: Bearer " + access_token
	]
	var url = API_BASE_URL + "/data/key/" + key + query
	
	print("GodotVault: 特定キーの全ユーザーデータ取得中... (key: ", key, ")")
	http_request.request(url, headers, HTTPClient.METHOD_GET)
	
	var response = await http_request.request_completed
	http_request.queue_free()
	
	var result: int = response[0]
	var response_code: int = response[1]
	var response_headers: PackedStringArray = response[2]
	var body: PackedByteArray = response[3]
	
	if response_code == 200:
		var response_text = body.get_string_from_utf8()
		var json = JSON.new()
		var parse_result = json.parse(response_text)
		if parse_result == OK:
			var response_data = json.data
			print("GodotVault: 特定キーの全ユーザーデータ取得完了 (key: ", key, ")")
			return response_data
		else:
			print("GodotVault: レスポンスの解析に失敗しました")
			return null
	else:
		var response_text = body.get_string_from_utf8()
		print("GodotVault: 特定キーの全ユーザーデータ取得に失敗: ", response_text)
		return null
