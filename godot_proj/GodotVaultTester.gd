extends Node

# GodotVault API Tester
# すべてのGodotVault機能をテストするためのUI

@onready var vault = $GodotVault
@onready var status_label = $VBoxContainer/AuthSection/StatusLabel
@onready var key_input = $VBoxContainer/DataSection/SaveContainer/KeyContainer/KeyInput
@onready var value_input = $VBoxContainer/DataSection/SaveContainer/ValueContainer/ValueInput
@onready var load_key_input = $VBoxContainer/DataSection/LoadContainer/LoadKeyContainer/LoadKeyInput
@onready var log_text = $VBoxContainer/LogSection/LogScroll/LogText

# ボタン参照
@onready var signup_button = $VBoxContainer/AuthSection/AuthButtons/SignupButton
@onready var login_button = $VBoxContainer/AuthSection/AuthButtons/LoginButton
@onready var save_button = $VBoxContainer/DataSection/SaveContainer/SaveButton
@onready var load_button = $VBoxContainer/DataSection/LoadContainer/LoadKeyContainer/LoadButton
@onready var delete_button = $VBoxContainer/DataSection/LoadContainer/LoadKeyContainer/DeleteButton
@onready var save_profile_button = $VBoxContainer/DataSection/QuickTestContainer/QuickTestButtons/SaveProfileButton
@onready var save_settings_button = $VBoxContainer/DataSection/QuickTestContainer/QuickTestButtons/SaveSettingsButton
@onready var save_score_button = $VBoxContainer/DataSection/QuickTestContainer/QuickTestButtons/SaveScoreButton
@onready var get_my_list_button = $VBoxContainer/DataSection/ListContainer/ListButtons/GetMyListButton
@onready var search_profile_button = $VBoxContainer/DataSection/ListContainer/ListButtons/SearchProfileButton
@onready var search_score_button = $VBoxContainer/DataSection/ListContainer/ListButtons/SearchScoreButton
@onready var clear_log_button = $VBoxContainer/LogSection/ClearLogButton

func _ready():
	# GodotVaultノードを作成して追加
	vault = preload("res://GodotVault.gd").new()
	add_child(vault)
	
	# シグナル接続
	vault.login_completed.connect(_on_login_completed)
	vault.logout_completed.connect(_on_logout_completed)
	
	update_ui_state()
	add_log("[color=green]GodotVault API Tester が開始されました[/color]")
	add_log("[color=blue]現在のログイン状態: " + ("ログイン中" if vault.is_logged_in else "ログアウト中") + "[/color]")

func update_ui_state():
	if vault.is_logged_in:
		status_label.text = "ログイン中 (Email: " + vault.current_email + ")"
		login_button.text = "ログアウト"
		enable_data_buttons(true)
	else:
		status_label.text = "ログアウト中"
		login_button.text = "保存されたアカウントでログイン"
		enable_data_buttons(false)

func enable_data_buttons(enabled: bool):
	save_button.disabled = not enabled
	load_button.disabled = not enabled
	delete_button.disabled = not enabled
	save_profile_button.disabled = not enabled
	save_settings_button.disabled = not enabled
	save_score_button.disabled = not enabled
	get_my_list_button.disabled = not enabled
	search_profile_button.disabled = not enabled
	search_score_button.disabled = not enabled

func add_log(message: String):
	var timestamp = Time.get_datetime_string_from_system()
	log_text.text += "\n[" + timestamp + "] " + message
	# 自動スクロール（少し遅延させる）
	await get_tree().process_frame
	var scroll = log_text.get_parent()
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

# === ボタンイベント ===

func _on_signup_button_pressed():
	add_log("[color=yellow]新規ユーザー登録を開始...[/color]")
	var success = await vault.signup()
	if success:
		add_log("[color=green]ユーザー登録が成功しました[/color]")
	else:
		add_log("[color=red]ユーザー登録に失敗しました[/color]")
	update_ui_state()

func _on_login_button_pressed():
	if vault.is_logged_in:
		add_log("[color=yellow]ログアウト中...[/color]")
		var success = await vault.logout()
		if success:
			add_log("[color=green]ログアウトしました[/color]")
		else:
			add_log("[color=red]ログアウトに失敗しました[/color]")
	else:
		if vault.current_email != "":
			add_log("[color=yellow]保存されたアカウントでログイン中...[/color]")
			var success = await vault.login(vault.current_email, vault.current_password)
			if success:
				add_log("[color=green]ログインしました[/color]")
			else:
				add_log("[color=red]ログインに失敗しました[/color]")
		else:
			add_log("[color=red]保存されたアカウント情報がありません。先に新規登録を行ってください。[/color]")
	update_ui_state()

func _on_save_button_pressed():
	var key = key_input.text.strip_edges()
	var value_text = value_input.text.strip_edges()
	
	if key == "":
		add_log("[color=red]キーを入力してください[/color]")
		return
	
	if value_text == "":
		add_log("[color=red]データを入力してください[/color]")
		return
	
	# JSONパースを試行
	var json = JSON.new()
	var parse_result = json.parse(value_text)
	var data
	if parse_result == OK:
		data = json.data
		add_log("[color=blue]JSON形式として保存: " + key + "[/color]")
	else:
		data = value_text
		add_log("[color=blue]テキストとして保存: " + key + "[/color]")
	
	var success = await vault.save_data(key, data)
	if success:
		add_log("[color=green]データの保存が成功しました (key: " + key + ")[/color]")
		key_input.text = ""
		value_input.text = ""
	else:
		add_log("[color=red]データの保存に失敗しました (key: " + key + ")[/color]")

func _on_load_button_pressed():
	var key = load_key_input.text.strip_edges()
	
	if key == "":
		add_log("[color=red]読み込むキーを入力してください[/color]")
		return
	
	add_log("[color=blue]データ読み込み中: " + key + "[/color]")
	var data = await vault.load_data(key)
	if data != null:
		add_log("[color=green]データの読み込みが成功しました (key: " + key + ")[/color]")
		add_log("[color=cyan]取得データ: " + JSON.stringify(data) + "[/color]")
	else:
		add_log("[color=red]データの読み込みに失敗しました (key: " + key + ")[/color]")

func _on_delete_button_pressed():
	var key = load_key_input.text.strip_edges()
	
	if key == "":
		add_log("[color=red]削除するキーを入力してください[/color]")
		return
	
	add_log("[color=blue]データ削除中: " + key + "[/color]")
	var success = await vault.delete_data(key)
	if success:
		add_log("[color=green]データの削除が成功しました (key: " + key + ")[/color]")
	else:
		add_log("[color=red]データの削除に失敗しました (key: " + key + ")[/color]")

func _on_save_profile_button_pressed():
	var profile_data = {
		"name": "テストプレイヤー",
		"level": randi() % 100 + 1,
		"class": "戦士",
		"created_at": Time.get_datetime_string_from_system()
	}
	add_log("[color=blue]プロフィールデータを保存中...[/color]")
	var success = await vault.save_data("profile", profile_data)
	if success:
		add_log("[color=green]プロフィールデータの保存が成功しました[/color]")
	else:
		add_log("[color=red]プロフィールデータの保存に失敗しました[/color]")

func _on_save_settings_button_pressed():
	var settings_data = {
		"volume": randf(),
		"difficulty": ["easy", "normal", "hard"][randi() % 3],
		"graphics_quality": ["low", "medium", "high"][randi() % 3],
		"controls": {
			"move_speed": randf() * 2.0,
			"mouse_sensitivity": randf() * 3.0
		}
	}
	add_log("[color=blue]設定データを保存中...[/color]")
	var success = await vault.save_data("settings", settings_data)
	if success:
		add_log("[color=green]設定データの保存が成功しました[/color]")
	else:
		add_log("[color=red]設定データの保存に失敗しました[/color]")

func _on_save_score_button_pressed():
	var score_data = {
		"high_score": randi() % 1000000,
		"play_time": randi() % 10000,
		"achievements": ["first_win", "speed_runner", "collector"],
		"last_played": Time.get_datetime_string_from_system()
	}
	add_log("[color=blue]スコアデータを保存中...[/color]")
	var success = await vault.save_data("score", score_data)
	if success:
		add_log("[color=green]スコアデータの保存が成功しました[/color]")
	else:
		add_log("[color=red]スコアデータの保存に失敗しました[/color]")

func _on_get_my_list_button_pressed():
	add_log("[color=blue]自分のデータ一覧を取得中...[/color]")
	var data = await vault.get_my_data_list()
	if data != null:
		add_log("[color=green]自分のデータ一覧取得が成功しました[/color]")
		add_log("[color=cyan]取得データ: " + JSON.stringify(data) + "[/color]")
	else:
		add_log("[color=red]自分のデータ一覧取得に失敗しました[/color]")

func _on_search_profile_button_pressed():
	add_log("[color=blue]全ユーザーのプロフィールデータを検索中...[/color]")
	var data = await vault.get_all_data_by_key("profile")
	if data != null:
		add_log("[color=green]プロフィールデータ検索が成功しました[/color]")
		add_log("[color=cyan]取得データ: " + JSON.stringify(data) + "[/color]")
	else:
		add_log("[color=red]プロフィールデータ検索に失敗しました[/color]")

func _on_search_score_button_pressed():
	add_log("[color=blue]全ユーザーのスコアデータを検索中...[/color]")
	var data = await vault.get_all_data_by_key("score")
	if data != null:
		add_log("[color=green]スコアデータ検索が成功しました[/color]")
		add_log("[color=cyan]取得データ: " + JSON.stringify(data) + "[/color]")
	else:
		add_log("[color=red]スコアデータ検索に失敗しました[/color]")

func _on_clear_log_button_pressed():
	log_text.text = "[color=green]ログがクリアされました[/color]"

# === GodotVaultイベント ===

func _on_login_completed(success: bool):
	# awaitベースなので、ここでは何もしない
	pass

func _on_logout_completed(success: bool):
	# awaitベースなので、ここでは何もしない
	pass
