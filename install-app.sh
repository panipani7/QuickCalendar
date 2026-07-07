#!/bin/bash
# ビルドして /Applications にインストールし、アプリを起動する
set -euo pipefail
cd "$(dirname "$0")"

# 仮想環境がない・壊れている場合は作り直す
if ! ./venv/bin/python -c '' 2>/dev/null; then
    echo "初回セットアップ中..."
    rm -rf venv
    python3 -m venv venv
    ./venv/bin/python -m pip install -q -r requirements.txt
fi
./venv/bin/python -m pip install -q py2app

echo "アプリをビルド中..."
rm -rf build dist
./venv/bin/python setup.py py2app >/dev/null

DEST="/Applications/QuickCalendar.app"
pkill -x QuickCalendar 2>/dev/null || true
rm -rf "$DEST"
cp -R dist/QuickCalendar.app "$DEST"
open "$DEST"

echo "インストール完了: $DEST"
echo "以後は Launchpad / Spotlight / Finder のアプリケーションフォルダから起動できます。"
