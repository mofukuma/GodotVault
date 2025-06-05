extends Control

# NetTesterシーン用スクリプト
# Net.gdモジュールのテスト用UI

@onready var url_input = $VBoxContainer/URLContainer/URLRow/URLInput
@onready var prompt_input = $VBoxContainer/GPTContainer/PromptRow/PromptInput
@onready var api_key_input = $VBoxContainer/APIKeyContainer/APIKeyRow/APIKeyInput
@onready var log_text = $VBoxContainer/LogSection/LogScroll/LogText

var net: Net

func _ready():
	# Netモジュールを作成
	net = preload("res://Net.gd").new()
	add_child(net)
	
	# デフォルト値を設定
	url_input.text = "https://progsha.org/test"
	prompt_input.text = "アイテムのデータをつくって。回答をJSONで返して。"
	
	add_log("[color=green]Net Tester が開始されました[/color]")
	add_log("[color=blue]まずOpenAI APIキーを設定してください[/color]")

func add_log(message: String):
	var timestamp = Time.get_datetime_string_from_system()
	log_text.text += "\n[" + timestamp + "] " + message
	# 自動スクロール
	await get_tree().process_frame
	var scroll = log_text.get_parent()
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func _on_set_api_key_button_pressed():
	var api_key = api_key_input.text.strip_edges()
	if api_key == "":
		add_log("[color=red]APIキーを入力してください[/color]")
		return
	
	net.set_openai_api_key(api_key)
	add_log("[color=green]OpenAI APIキーを設定しました[/color]")
	api_key_input.text = ""

func _on_test_url_button_pressed():
	var url = url_input.text.strip_edges()
	if url == "":
		add_log("[color=red]URLを入力してください[/color]")
		return
	
	add_log("[color=blue]URL取得テスト開始: " + url + "[/color]")
	var data = await net.get_url(url)
	
	if data != "":
		add_log("[color=green]URL取得成功[/color]")
		add_log("[color=cyan]取得データ（最初の200文字）: " + data.substr(0, 200) + "...[/color]")
	else:
		add_log("[color=red]URL取得に失敗しました[/color]")

func _on_test_gpt_button_pressed():
	var prompt = prompt_input.text.strip_edges()
	if prompt == "":
		add_log("[color=red]プロンプトを入力してください[/color]")
		return
	
	add_log("[color=blue]OpenAI GPT API テスト開始[/color]")
	add_log("[color=blue]プロンプト: " + prompt + "[/color]")
	
	var response = await net.gpt(prompt)
	
	if "error" in response:
		add_log("[color=red]GPT API呼び出しに失敗: " + response.error + "[/color]")
	elif response.success:
		add_log("[color=green]GPT API呼び出し成功[/color]")
		add_log("[color=cyan]応答: " + response.content + "[/color]")
		
		if response.data != null:
			add_log("[color=yellow]JSON解析成功: " + JSON.stringify(response.data) + "[/color]")
		else:
			add_log("[color=orange]応答はJSONではありません[/color]")
	else:
		add_log("[color=red]不明なエラーが発生しました[/color]")

func _on_test_gpt_json_button_pressed():
	var prompt = prompt_input.text.strip_edges()
	if prompt == "":
		add_log("[color=red]プロンプトを入力してください[/color]")
		return
	
	add_log("[color=blue]OpenAI GPT JSON API テスト開始[/color]")
	add_log("[color=blue]プロンプト: " + prompt + "[/color]")
	
	var response = await net.gpt_json(prompt)
	
	if "error" in response:
		add_log("[color=red]GPT JSON API呼び出しに失敗: " + response.error + "[/color]")
	elif response.success:
		add_log("[color=green]GPT JSON API呼び出し成功[/color]")
		add_log("[color=cyan]応答: " + response.content + "[/color]")
		
		if response.data != null:
			add_log("[color=green]JSON解析成功: " + JSON.stringify(response.data) + "[/color]")
		else:
			add_log("[color=orange]JSON解析に失敗（応答がJSONではない可能性）[/color]")
	else:
		add_log("[color=red]不明なエラーが発生しました[/color]")

func _on_test_parallel_button_pressed():
	var urls = [
		"https://progsha.org",
		"https://progsha.org/godotter/",
		"https://progsha.org/news/"
	]
	
	add_log("[color=blue]並列URL取得テスト開始[/color]")
	add_log("[color=blue]対象URL: " + str(urls) + "[/color]")
	
	var results = await net.get_urls_parallel(urls)
	
	add_log("[color=green]並列URL取得完了[/color]")
	for result in results:
		if result.success:
			add_log("[color=green]" + result.url + ": 成功[/color]")
			add_log("[color=cyan]データ: " + result.data.substr(0, 100) + "...[/color]")
		else:
			add_log("[color=red]" + result.url + ": 失敗 - " + result.error + "[/color]")

func _on_clear_log_button_pressed():
	log_text.text = "[color=green]ログがクリアされました[/color]"
