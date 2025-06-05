#!/bin/bash

# Supabaseマイグレーションスクリプト
# 使用方法: ./scripts/migrate.sh [local|production]

set -e

ENV=${1:-local}

echo "🚀 Supabaseマイグレーションを開始します (環境: $ENV)"

# 現在のディレクトリを確認
if [ ! -f "package.json" ]; then
    echo "❌ エラー: プロジェクトルートディレクトリで実行してください"
    exit 1
fi

# Supabase CLIがインストールされているかチェック
if ! command -v supabase &> /dev/null; then
    echo "❌ エラー: Supabase CLIがインストールされていません"
    echo "インストール方法: npm install -g supabase"
    exit 1
fi

case $ENV in
    "local")
        echo "📍 ローカル環境にマイグレーションを実行します"
        
        # ローカルSupabaseが起動しているかチェック
        if ! supabase status &> /dev/null; then
            echo "⚠️  ローカルSupabaseが起動していません。起動します..."
            supabase start
        fi
        
        # マイグレーションを実行
        echo "🔄 マイグレーションを実行中..."
        supabase db reset
        
        echo "✅ ローカル環境のマイグレーションが完了しました"
        echo "📊 データベースの状態を確認..."
        supabase status
        ;;
        
    "production")
        echo "📍 本番環境にマイグレーションを実行します"
        
        # プロジェクトがリンクされているかチェック
        if [ ! -f ".env.production" ]; then
            echo "❌ エラー: .env.productionファイルが見つかりません"
            echo "本番環境の設定を行ってください"
            exit 1
        fi
        
        # 環境変数を読み込み
        source .env.production
        
        if [ -z "$SUPABASE_PROJECT_REF" ]; then
            echo "❌ エラー: SUPABASE_PROJECT_REFが設定されていません"
            echo ".env.productionに以下を追加してください:"
            echo "SUPABASE_PROJECT_REF=your-project-ref"
            exit 1
        fi
        
        # プロジェクトにリンク（既にリンクされている場合はスキップ）
        echo "🔗 プロジェクトをリンク中..."
        supabase link --project-ref $SUPABASE_PROJECT_REF || true
        
        # マイグレーションを実行
        echo "🔄 本番環境にマイグレーションを実行中..."
        supabase db push
        
        echo "✅ 本番環境のマイグレーションが完了しました"
        ;;
        
    *)
        echo "❌ エラー: 無効な環境です"
        echo "使用方法: $0 [local|production]"
        exit 1
        ;;
esac

echo ""
echo "🎉 マイグレーションが完了しました！"
echo "次のステップ:"
echo "  - ローカル環境: npm run dev:local"
echo "  - 本番環境: npm run start"