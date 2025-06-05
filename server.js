import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';

// 環境に応じた設定ファイルを読み込み
const env = process.env.NODE_ENV || 'local';
if (env === 'local') {
  dotenv.config({ path: '.env.local' });
} else {
  dotenv.config({ path: '.env.production' });
}

const app = express();
const PORT = process.env.PORT || 3000;

// Supabaseクライアント設定
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('Supabase環境変数が設定されていません');
  console.error('必要な環境変数: SUPABASE_URL, SUPABASE_ANON_KEY');
  process.exit(1);
}

console.log(`環境: ${env}`);
console.log(`Supabase URL: ${supabaseUrl}`);

// ミドルウェア
app.use(cors());
app.use(express.json());

// Supabaseクライアント作成のヘルパー関数
const createSupabaseClient = (accessToken = null) => {
  if (accessToken) {
    return createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: {
          Authorization: `Bearer ${accessToken}`
        }
      }
    });
  }
  return createClient(supabaseUrl, supabaseAnonKey);
};

// 認証ミドルウェア
const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'アクセストークンが必要です' });
    }

    const token = authHeader.split(' ')[1];
    const supabase = createSupabaseClient(token);
    
    const { data: { user }, error } = await supabase.auth.getUser();
    
    if (error || !user) {
      return res.status(401).json({ error: '無効なトークンです' });
    }

    req.user = user;
    req.supabase = supabase;
    next();
  } catch (error) {
    console.error('認証エラー:', error);
    res.status(500).json({ error: '認証処理でエラーが発生しました' });
  }
};

// ===== 認証関連のエンドポイント =====

// ユーザー登録
app.post('/auth/signup', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ error: 'メールアドレスとパスワードが必要です' });
    }

    const supabase = createSupabaseClient();
    const { data, error } = await supabase.auth.signUp({
      email,
      password
    });

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.json({
      message: 'ユーザー登録が完了しました',
      user: data.user,
      session: data.session
    });
  } catch (error) {
    console.error('登録エラー:', error);
    res.status(500).json({ error: 'ユーザー登録でエラーが発生しました' });
  }
});

// ログイン
app.post('/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ error: 'メールアドレスとパスワードが必要です' });
    }

    const supabase = createSupabaseClient();
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.json({
      message: 'ログインしました',
      user: data.user,
      session: data.session
    });
  } catch (error) {
    console.error('ログインエラー:', error);
    res.status(500).json({ error: 'ログインでエラーが発生しました' });
  }
});

// ログアウト
app.post('/auth/logout', authMiddleware, async (req, res) => {
  try {
    const { error } = await req.supabase.auth.signOut();
    
    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.json({ message: 'ログアウトしました' });
  } catch (error) {
    console.error('ログアウトエラー:', error);
    res.status(500).json({ error: 'ログアウトでエラーが発生しました' });
  }
});

// ===== データ操作のエンドポイント =====

// データ保存・更新（UPSERT）
app.put('/data/:key', authMiddleware, async (req, res) => {
  try {
    const { key } = req.params;
    const { json_data } = req.body;
    
    if (!key) {
      return res.status(400).json({ error: 'キーが必要です' });
    }
    
    if (!json_data) {
      return res.status(400).json({ error: 'json_dataが必要です' });
    }

    const { data, error } = await req.supabase
      .from('user_data')
      .upsert(
        {
          user_id: req.user.id,
          key: key,
          json_data: json_data
        },
        {
          onConflict: 'user_id,key'
        }
      )
      .select();

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.status(200).json({
      message: 'データを保存しました',
      data: data[0]
    });
  } catch (error) {
    console.error('データ保存エラー:', error);
    res.status(500).json({ error: 'データ保存でエラーが発生しました' });
  }
});

/*
// データ一覧取得（全ユーザのデータを取得可能）
app.get('/data', authMiddleware, async (req, res) => {
  try {
    const { page = 1, limit = 50, user_id, key_pattern } = req.query;
    const offset = (page - 1) * limit;

    let query = req.supabase
      .from('user_data')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    // 特定のユーザーのデータのみフィルタリング（オプション）
    if (user_id) {
      query = query.eq('user_id', user_id);
    }
    
    // キーパターンでフィルタリング
    if (key_pattern) {
      query = query.ilike('key', `%${key_pattern}%`);
    }

    const { data, error, count } = await query;

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.json({
      message: 'データを取得しました',
      data: data,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count
      }
    });
  } catch (error) {
    console.error('データ取得エラー:', error);
    res.status(500).json({ error: 'データ取得でエラーが発生しました' });
  }
});
*/

// 自分のデータ一覧取得
app.get('/data/my', authMiddleware, async (req, res) => {
  try {
    const { page = 1, limit = 50, key_pattern } = req.query;
    const offset = (page - 1) * limit;

    let query = req.supabase
      .from('user_data')
      .select('*', { count: 'exact' })
      .eq('user_id', req.user.id)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);
    
    // キーパターンでフィルタリング
    if (key_pattern) {
      query = query.ilike('key', `%${key_pattern}%`);
    }

    const { data, error, count } = await query;

    if (error) {
      console.error('自分のデータ取得エラー:', error);
      return res.status(400).json({ error: error.message });
    }

    if (data.length === 0) {
      return res.status(404).json({ error: '自分:'+req.user.id+'のデータが見つかりません' });
    }

    console.log('自分のデータ取得成功:', {
      user_id: req.user.id,
      data_count: data.length,
      total_count: count
    });

    res.json({
      message: '自分のデータを取得しました',
      data: data,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count
      }
    });
  } catch (error) {
    console.error('データ取得エラー:', error);
    res.status(500).json({ error: 'データ取得でエラーが発生しました' });
  }
});

// 特定キーのデータ取得
app.get('/data/:key', authMiddleware, async (req, res) => {
  try {
    const { key } = req.params;
    const { user_id } = req.query;
    
    let query = req.supabase
      .from('user_data')
      .select('*')
      .eq('key', key);
    
    // 特定ユーザーのデータを取得する場合
    if (user_id) {
      query = query.eq('user_id', user_id);
    }
    
    const { data, error } = await query;

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    if (data.length === 0) {
      return res.status(404).json({ error: 'そのキーのデータが見つかりません' });
    }

    res.json({
      message: 'データを取得しました',
      data: user_id ? data[0] : data
    });
  } catch (error) {
    console.error('データ取得エラー:', error);
    res.status(500).json({ error: 'データ取得でエラーが発生しました' });
  }
});

// 自分の特定キーのデータ取得
app.get('/data/my/:key', authMiddleware, async (req, res) => {
  try {
    const { key } = req.params;
    
    const { data, error } = await req.supabase
      .from('user_data')
      .select('*')
      .eq('user_id', req.user.id)
      .eq('key', key)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({ error: '自分の'+key+'のデータが見つかりません' });
      }
      return res.status(400).json({ error: error.message });
    }

    res.json({
      message: 'データを取得しました',
      data: data
    });
  } catch (error) {
    console.error('データ取得エラー:', error);
    res.status(500).json({ error: 'データ取得でエラーが発生しました' });
  }
});



// 他ユーザーの特定キーのデータ取得
app.get('/data/user/:userId/:key', authMiddleware, async (req, res) => {
  try {
    const { userId, key } = req.params;
    
    const { data, error } = await req.supabase
      .from('user_data')
      .select('*')
      .eq('user_id', userId)
      .eq('key', key)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({ error: '他のユーザの対象データが見つかりません' });
      }
      return res.status(400).json({ error: error.message });
    }

    res.json({
      message: 'データを取得しました',
      data: data
    });
  } catch (error) {
    console.error('データ取得エラー:', error);
    res.status(500).json({ error: 'データ取得でエラーが発生しました' });
  }
});


// 特定ユーザーのデータ一覧取得
app.get('/data/user/:userId', authMiddleware, async (req, res) => {
  try {
    const { userId } = req.params;
    const { page = 1, limit = 50, key_pattern } = req.query;
    const offset = (page - 1) * limit;

    let query = req.supabase
      .from('user_data')
      .select('*', { count: 'exact' })
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);
    
    // キーパターンでフィルタリング
    if (key_pattern) {
      query = query.ilike('key', `%${key_pattern}%`);
    }

    const { data, error, count } = await query;

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.json({
      message: '指定ユーザーのデータを取得しました',
      data: data,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count
      }
    });
  } catch (error) {
    console.error('データ取得エラー:', error);
    res.status(500).json({ error: 'データ取得でエラーが発生しました' });
  }
});

// 特定キーを持つ全ユーザーのデータ取得
app.get('/data/key/:key', authMiddleware, async (req, res) => {
  try {
    const { key } = req.params;
    const { page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;

    const { data, error, count } = await req.supabase
      .from('user_data')
      .select('*', { count: 'exact' })
      .eq('key', key)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.json({
      message: '指定キーのデータを取得しました',
      data: data,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count
      }
    });
  } catch (error) {
    console.error('データ取得エラー:', error);
    res.status(500).json({ error: 'データ取得でエラーが発生しました' });
  }
});
// 自分のデータ削除
app.delete('/data/my/:key', authMiddleware, async (req, res) => {
  try {
    const { key } = req.params;
    
    const { data, error } = await req.supabase
      .from('user_data')
      .delete()
      .eq('user_id', req.user.id)
      .eq('key', key)
      .select();

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    if (data.length === 0) {
      return res.status(404).json({ error: '削除対象データが見つかりません' });
    }

    res.json({
      message: 'データを削除しました',
      data: data[0]
    });
  } catch (error) {
    console.error('データ削除エラー:', error);
    res.status(500).json({ error: 'データ削除でエラーが発生しました' });
  }
});

// ヘルスチェック
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// API情報エンドポイント
app.get('/api/info', (req, res) => {
  res.json({
    name: 'GodotVault API',
    version: '1.0.0',
    description: 'Supabase-based user authentication and key-value JSON data management system',
    endpoints: {
      auth: [
        'POST /auth/signup',
        'POST /auth/login',
        'POST /auth/logout'
      ],
      data: [
        'PUT /data/:key',
        'POST /data',
        'GET /data',
        'GET /data/:key',
        'GET /data/my',
        'GET /data/my/:key',
        'GET /data/user/:userId',
        'GET /data/user/:userId/:key',
        'GET /data/key/:key',
        'DELETE /data/my/:key'
      ],
      utility: [
        'GET /health',
        'GET /api/info'
      ]
    }
  });
});

// サーバー起動
app.listen(PORT, () => {
  console.log(`サーバーがポート${PORT}で起動しました`);
  console.log(`環境: ${env}`);
  console.log(`Supabase URL: ${supabaseUrl}`);
  console.log(`アクセス URL: http://localhost:${PORT}`);
});

