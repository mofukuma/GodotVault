# GodotVault

Supabaseを使用したユーザー認証とJSONデータ管理システム。  
ユーザーごとにJSONデータを保存・管理できるREST APIとGodotクライアントのサンプル実装です。

## 🌟 主な機能

- **ユーザー認証**: JWT ベースのサインアップ・ログイン・ログアウト
- **データストア**: ユーザーごとにJSONデータを管理
- **データ共有**: 他ユーザーのデータも読み取り可能（編集は自分のデータのみ）
- **ページネーション**: 大量データの効率的な取得
- **Godotクライアント**: Godot Engineでの実装サンプル

## 🛠️ 技術スタック

- **Backend**: Node.js + Express.js
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth (JWT)
- **Security**: Row Level Security (RLS)
- **Client**: Godot Engine 4.x

## 📋 前提条件

- Node.js 16.x 以上
- npm または yarn
- Supabase CLI（ローカル開発の場合）
- Supabaseプロジェクト（クラウド使用の場合）
- Godot Engine 4.x（クライアント実行の場合）

## 🚀 セットアップ

### ローカル開発環境

1. **リポジトリのクローンと依存関係のインストール**
   ```bash
   git clone https://github.com/mofukuma/GodotVault
   cd GodotVault
   npm install
   ```

2. **Supabase CLIのインストールと初期化**
   ```bash
   npm i supabase --save-dev
   supabase init
   ```
   最新情報はこちら：https://github.com/supabase/cli#install-the-cli

3. **ローカルSupabaseの起動**
   ```bash
   supabase start
   ```

4. **環境変数の設定**
   ```bash
   # .env.local ファイルを作成
   cp .env.local.example .env.local
   # 必要に応じて .env.local の値を編集
   ```

5. **データベースマイグレーション**
   ```bash
   # マイグレーションスクリプトを使用（推奨）
   ./scripts/migrate.sh local
   
   # または手動実行
   supabase db reset
   ```

6. **サーバー起動**
   ```bash
   npm run dev:local  # 自動リロード機能付き
   ```

### 本番環境（Supabaseクラウド）

1. **Supabaseプロジェクトの作成**
   - [supabase.com](https://supabase.com) でプロジェクト作成
   - プロジェクト設定からAPI情報を取得

2. **環境変数の設定**
   ```bash
   # .env.production ファイルを作成
   cp .env.production.example .env.production
   # .env.production を編集して実際の値を設定
   ```

3. **プロジェクトのリンクとマイグレーション**
   ```bash
   # マイグレーションスクリプトを使用（推奨）
   ./scripts/migrate.sh production
   
   # または手動実行
   supabase link --project-ref YOUR_PROJECT_REF
   supabase db push
   ```

4. **本番サーバー起動**
   ```bash
   npm run start
   ```

## 📡 API エンドポイント

### 認証

| Method | Endpoint | 説明 | パラメータ |
|--------|----------|------|---------|
| POST | `/auth/signup` | ユーザー登録 | `{ "email": "string", "password": "string" }` |
| POST | `/auth/login` | ログイン | `{ "email": "string", "password": "string" }` |
| POST | `/auth/logout` | ログアウト | 認証ヘッダー必須 |

### データ管理

| Method | Endpoint | 説明 | パラメータ |
|--------|----------|------|---------|
| PUT | `/data/:key` | データ保存・更新（UPSERT） | `{ "json_data": object }` + 認証ヘッダー |
| GET | `/data/my` | 自分のデータ一覧 | クエリ: `page`, `limit`, `key_pattern` + 認証ヘッダー |
| GET | `/data/my/:key` | 自分の特定キーのデータ | 認証ヘッダー必須 |
| GET | `/data/user/:userId` | 特定ユーザーのデータ一覧 | クエリ: `page`, `limit`, `key_pattern` + 認証ヘッダー |
| GET | `/data/user/:userId/:key` | 他ユーザーの特定キーのデータ | 認証ヘッダー必須 |
| GET | `/data/key/:key` | 特定キーを持つ全ユーザーのデータ | クエリ: `page`, `limit` + 認証ヘッダー |
| DELETE | `/data/my/:key` | 自分のデータ削除 | 認証ヘッダー必須 |

### ヘルスチェック・API情報

| Method | Endpoint | 説明 |
|--------|----------|------|
| GET | `/health` | サーバー状態確認 |
| GET | `/api/info` | API情報取得 |

### クエリパラメータ

- `page`: ページ番号（デフォルト: 1）
- `limit`: 1ページあたりの件数（デフォルト: 50）
- `user_id`: 特定ユーザーでフィルタリング
- `key_pattern`: キー名での部分一致検索

## 🔧 使用例

### 1. ユーザー登録とログイン

```javascript
// ユーザー登録
const signupResponse = await fetch('http://localhost:3000/auth/signup', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: 'user@example.com',
    password: 'securepassword123'
  })
});

// ログイン
const loginResponse = await fetch('http://localhost:3000/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: 'user@example.com',
    password: 'securepassword123'
  })
});

const { session } = await loginResponse.json();
const accessToken = session.access_token;
```

### 2. データの保存

```javascript
// キー指定でのデータ保存・更新（推奨）
await fetch('http://localhost:3000/data/profile', {
  method: 'PUT',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${accessToken}`
  },
  body: JSON.stringify({
    json_data: {
      playerName: 'John Doe',
      level: 25,
      score: 15750,
      settings: {
        theme: 'dark',
        language: 'ja'
      }
    }
  })
});

// ゲーム設定の保存
await fetch('http://localhost:3000/data/settings', {
  method: 'PUT',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${accessToken}`
  },
  body: JSON.stringify({
    json_data: {
      theme: 'dark',
      language: 'ja',
      soundEnabled: true
    }
  })
});
```

### 3. データの取得

```javascript
// 自分の特定キーのデータ取得
const myProfileResponse = await fetch('http://localhost:3000/data/my/profile', {
  headers: { 'Authorization': `Bearer ${accessToken}` }
});

// 自分のデータ一覧取得
const myDataResponse = await fetch('http://localhost:3000/data/my', {
  headers: { 'Authorization': `Bearer ${accessToken}` }
});

// 特定キーを持つ全ユーザーのデータ取得
const allProfilesResponse = await fetch('http://localhost:3000/data/key/profile', {
  headers: { 'Authorization': `Bearer ${accessToken}` }
});

// キーパターンで検索（自分のデータ）
const searchResponse = await fetch('http://localhost:3000/data/my?key_pattern=config&page=1&limit=10', {
  headers: { 'Authorization': `Bearer ${accessToken}` }
});

// 他ユーザーの特定キーのデータ取得
const userProfileResponse = await fetch('http://localhost:3000/data/user/USER_ID/profile', {
  headers: { 'Authorization': `Bearer ${accessToken}` }
});
```

## 🎮 Godotクライアント

### GodotVaultモジュール

`godot_proj/GodotVault.gd` にSupabase APIクライアントモジュールがあります。

#### 主な機能
- シンプルなキー・辞書型データの保存・読み込み
- 自動セッション管理
- awaitベースの非同期処理
- 最小限のシグナル（login_completed、logout_completed）
- エラーハンドリング

#### 基本的な使用方法

```gdscript
# ノードを追加
var vault = preload("res://GodotVault.gd").new()
add_child(vault)

# シグナル接続（最小限）
vault.login_completed.connect(_on_login_completed)
vault.logout_completed.connect(_on_logout_completed)

# ユーザー登録（ランダムアカウント作成）
var success = await vault.signup()

# データ保存（awaitパターン）
var player_data = {"name": "Player", "level": 10, "score": 1500}
var save_success = await vault.save_data("profile", player_data)

# データ読み込み（awaitパターン）
var loaded_data = await vault.load_data("profile")
```

### GodotVault Tester

`godot_proj/GodotVaultTester.tscn` に全API機能をテストできるUIがあります。

#### 機能
- ユーザー登録・ログイン・ログアウト
- データ保存・読み込み・削除
- クイックテスト（プロフィール、設定、スコア）
- データ一覧取得・検索
- リアルタイムログ表示

#### 使用方法

1. Godot Engine 4.xでプロジェクトを開く
2. サーバーを起動（`npm run dev:local`）
3. Godotで`GodotVaultTester.tscn`を実行
4. 「ランダムユーザー登録」でアカウント作成
5. 各種API機能をテスト

## 🏗️ データベース構造

```sql
CREATE TABLE user_data (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  key TEXT NOT NULL,
  json_data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (user_id, key)
);
```

### 主な特徴
- **複合主キー**: `(user_id, key)` により、ユーザーごとにキーの一意性を保証
- **UPSERT対応**: 同じキーでのデータ保存時は自動的に更新される
- **JSONB型**: 効率的なJSONデータ格納・検索が可能

## 🔒 セキュリティ

### Row Level Security (RLS)

- **読み取り**: 認証済みユーザーは全データを読み取り可能
- **作成**: ユーザーは自分のデータのみ作成可能
- **更新**: ユーザーは自分のデータのみ更新可能
- **削除**: ユーザーは自分のデータのみ削除可能

### 認証

- JWT トークンベースの認証
- Bearer トークンをAuthorizationヘッダーで送信
- 認証が必要なエンドポイントには認証ミドルウェアを適用

## 📝 スクリプト

```json
{
  "scripts": {
    "dev": "nodemon server.js",
    "dev:local": "NODE_ENV=local nodemon server.js",
    "start": "NODE_ENV=production node server.js",
    "supabase:start": "supabase start",
    "supabase:stop": "supabase stop",
    "supabase:reset": "supabase db reset",
    "supabase:link": "supabase link --project-ref YOUR_PROJECT_REF",
    "supabase:push": "supabase db push",
    "supabase:deploy": "supabase functions deploy"
  }
}
```

### 開発用コマンド
- `npm run dev` または `npm run dev:local`: 自動リロード機能付きでサーバー起動
- `npm run start`: 本番環境でサーバー起動

## 🌐 実用的な使用ケース

### ゲーム進行状況管理

```javascript
PUT /data/profile
{
  "json_data": {
    "playerName": "Player1",
    "level": 25,
    "experience": 15750,
    "achievements": ["first_login", "level_10"],
    "inventory": [
      { "item": "sword", "quantity": 1 },
      { "item": "potion", "quantity": 5 }
    ]
  }
}
```

### アプリケーション設定管理

```javascript
PUT /data/settings
{
  "json_data": {
    "theme": "dark",
    "language": "ja",
    "timezone": "Asia/Tokyo",
    "notifications": {
      "email": true,
      "push": false
    }
  }
}
```

## 🐛 トラブルシューティング

### よくある問題

1. **Supabase接続エラー**
   - 環境変数の確認（SUPABASE_URL, SUPABASE_ANON_KEY）
   - ネットワーク接続の確認

2. **認証エラー**
   - トークンの有効期限確認
   - Authorizationヘッダーの形式確認

3. **データアクセスエラー**
   - RLSポリシーの確認
   - ユーザーIDの一致確認

4. **Godotクライアントエラー**
   - サーバーの起動状態確認
   - APIエンドポイントのURL確認

## 📄 ライセンス

MIT License

## 🔗 参考リンク

- [Supabase Documentation](https://supabase.com/docs)
- [Godot Engine Documentation](https://docs.godotengine.org/)
- [Express.js Documentation](https://expressjs.com/)