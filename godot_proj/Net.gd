class_name Net
extends Node

# Net - ネットワーク通信モジュール
# 使用方法:
# @onready var net = $Net
# var data = await net.get_url("https://progsha.org/")
# var response = await net.gpt("アイテムのデータをつくって。")

# OpenAI API設定
const OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"
var openai_api_key: String = ""

func _ready():
	# 環境変数またはファイルからAPIキーを読み込み
	load_openai_api_key()

# OpenAI APIキーを読み込み
func load_openai_api_key():
	# まず環境変数を確認
	if OS.has_environment("OPENAI_API_KEY"):
		openai_api_key = OS.get_environment("OPENAI_API_KEY")
		print("Net: OpenAI APIキーを環境変数から読み込みました")
		return
	
	# 設定ファイルから読み込み
	var config = ConfigFile.new()
	var err = config.load("user://net_config.cfg")
	if err == OK:
		openai_api_key = config.get_value("openai", "api_key", "")
		if openai_api_key != "":
			print("Net: OpenAI APIキーを設定ファイルから読み込みました")
		else:
			print("Net: 設定ファイルにAPIキーが設定されていません")
	else:
		print("Net: 設定ファイルが見つかりません。APIキーを設定してください")

# OpenAI APIキーを設定
func set_openai_api_key(api_key: String):
	openai_api_key = api_key
	
	# 設定ファイルに保存
	var config = ConfigFile.new()
	config.set_value("openai", "api_key", api_key)
	config.save("user://net_config.cfg")
	print("Net: OpenAI APIキーを設定しました")

# URL取得関数
func get_url(url: String, headers: Array = []) -> String:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	print("Net: URL取得中... (", url, ")")
	http_request.request(url, headers, HTTPClient.METHOD_GET)
	
	var response = await http_request.request_completed
	http_request.queue_free()
	
	var result: int = response[0]
	var response_code: int = response[1]
	var response_headers: PackedStringArray = response[2]
	var body: PackedByteArray = response[3]
	
	if response_code == 200:
		var response_text = body.get_string_from_utf8()
		print("Net: URL取得完了 (", url, ")")
		return response_text
	else:
		var error_text = body.get_string_from_utf8()
		print("Net: URL取得に失敗: ", response_code, " - ", error_text)
		return ""

# POST リクエスト関数
func post_url(url: String, data: String, headers: Array = []) -> String:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	print("Net: POST送信中... (", url, ")")
	http_request.request(url, headers, HTTPClient.METHOD_POST, data)
	
	var response = await http_request.request_completed
	http_request.queue_free()
	
	var result: int = response[0]
	var response_code: int = response[1]
	var response_headers: PackedStringArray = response[2]
	var body: PackedByteArray = response[3]
	
	if response_code == 200:
		var response_text = body.get_string_from_utf8()
		print("Net: POST送信完了 (", url, ")")
		return response_text
	else:
		var error_text = body.get_string_from_utf8()
		print("Net: POST送信に失敗: ", response_code, " - ", error_text)
		return ""

# OpenAI GPT API関数
func gpt(prompt: String, model: String = "o4-mini", max_tokens: int = 1000) -> Dictionary:
	if openai_api_key == "":
		print("Net: OpenAI APIキーが設定されていません")
		return {"error": "APIキーが設定されていません"}
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var request_data = {
		"model": model,
		"messages": [
			{
				"role": "user",
				"content": prompt
			}
		],
		"max_tokens": max_tokens,
		"temperature": 0.7
	}
	
	var json_string = JSON.stringify(request_data)
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + openai_api_key
	]
	
	print("Net: OpenAI GPT API呼び出し中...")
	print("Net: プロンプト: ", prompt)
	http_request.request(OPENAI_API_URL, headers, HTTPClient.METHOD_POST, json_string)
	
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
			if "choices" in response_data and response_data.choices.size() > 0:
				var content = response_data.choices[0].message.content
				print("Net: OpenAI GPT API応答完了")
				print("Net: 応答: ", content)
				
				# JSON応答を試行パース
				var content_json = JSON.new()
				var content_parse_result = content_json.parse(content)
				if content_parse_result == OK:
					return {
						"success": true,
						"content": content,
						"data": content_json.data,
						"raw_response": response_data
					}
				else:
					return {
						"success": true,
						"content": content,
						"data": null,
						"raw_response": response_data
					}
			else:
				print("Net: OpenAI GPT API応答にchoicesが含まれていません")
				return {"error": "無効な応答形式"}
		else:
			print("Net: OpenAI GPT API応答のJSONパースに失敗")
			return {"error": "JSONパースエラー"}
	else:
		var error_text = body.get_string_from_utf8()
		print("Net: OpenAI GPT API呼び出しに失敗: ", response_code, " - ", error_text)
		return {"error": "API呼び出しエラー: " + str(response_code)}

# JSON付きでGPT API呼び出し（JSON応答を強制）
func gpt_json(prompt: String, model: String = "gpt-3.5-turbo", max_tokens: int = 1000) -> Dictionary:
	var json_prompt = prompt + "\n\n必ず有効なJSON形式で回答してください。説明文は含めず、JSONのみを返してください。"
	return await gpt(json_prompt, model, max_tokens)

# 複数のURLを並列取得
func get_urls_parallel(urls: Array) -> Array:
	var http_requests = []
	var responses = []
	responses.resize(urls.size())
	var completed_count = [0]
	
	# 複数のHTTPRequestを作成
	for i in range(urls.size()):
		var url = urls[i]
		var http_request = HTTPRequest.new()
		add_child(http_request)
		http_requests.append(http_request)
		
		# シグナル接続 - 正しい引数数で接続
		var callback = func(result: int, response_code: int, response_headers: PackedStringArray, body: PackedByteArray, index: int = i):
			responses[index] = [result, response_code, response_headers, body]
			completed_count[0] += 1
		
		http_request.request_completed.connect(callback, CONNECT_ONE_SHOT)
		
		print("Net: 並列URL取得開始... (", url, ")")
		http_request.request(url, [], HTTPClient.METHOD_GET)
	
	# すべてのリクエストが完了するまで待機
	while completed_count[0] < urls.size():
		await Engine.get_main_loop().process_frame
	
	# 結果を処理
	var results = []
	for i in range(responses.size()):
		var response = responses[i]
		var url = urls[i]
		var http_request = http_requests[i]
		
		var result: int = response[0]
		var response_code: int = response[1]
		var response_headers: PackedStringArray = response[2]
		var body: PackedByteArray = response[3]
		
		if response_code == 200:
			var response_text = body.get_string_from_utf8()
			results.append({"url": url, "success": true, "data": response_text})
			print("Net: 並列URL取得完了 (", url, ")")
		else:
			var error_text = body.get_string_from_utf8()
			results.append({"url": url, "success": false, "error": error_text})
			print("Net: 並列URL取得に失敗 (", url, "): ", response_code)
		
		http_request.queue_free()
	
	return results
