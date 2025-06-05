-- ユーザデータを保存するテーブル（キーベース）
CREATE TABLE user_data (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  key TEXT NOT NULL,
  json_data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (user_id, key)
);

-- インデックスを追加（パフォーマンス向上）
CREATE INDEX idx_user_data_user_id ON user_data(user_id);
CREATE INDEX idx_user_data_key ON user_data(key);
CREATE INDEX idx_user_data_created_at ON user_data(created_at);

-- RLS (Row Level Security) を有効化
ALTER TABLE user_data ENABLE ROW LEVEL SECURITY;

-- 認証済みユーザは全てのデータを読み出し可能
CREATE POLICY "Authenticated users can view all data" ON user_data
  FOR SELECT USING (auth.role() = 'authenticated');

-- ユーザは自分のデータのみ作成可能
CREATE POLICY "Users can insert own data" ON user_data
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ユーザは自分のデータのみ更新可能
CREATE POLICY "Users can update own data" ON user_data
  FOR UPDATE USING (auth.uid() = user_id);

-- ユーザは自分のデータのみ削除可能
CREATE POLICY "Users can delete own data" ON user_data
  FOR DELETE USING (auth.uid() = user_id);

-- updated_atを自動更新する関数とトリガー
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$ language 'plpgsql';

CREATE TRIGGER update_user_data_updated_at 
    BEFORE UPDATE ON user_data 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
