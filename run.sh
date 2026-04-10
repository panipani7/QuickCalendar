#!/bin/bash
# カレンダーアプリ起動スクリプト
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 仮想環境がなければ作成
if [ ! -d "$SCRIPT_DIR/venv" ]; then
    echo "初回セットアップ中..."
    python3 -m venv "$SCRIPT_DIR/venv"
    "$SCRIPT_DIR/venv/bin/pip" install -q -r "$SCRIPT_DIR/requirements.txt"
    echo "セットアップ完了！"
fi

# アプリ起動
"$SCRIPT_DIR/venv/bin/python" "$SCRIPT_DIR/calendar_app.py"
