#!/bin/bash

# --- 1. ユーザーからの入力 ---
echo "--- Unison 双方向同期設定スクリプト ---"
read -p "プロファイル名を入力してください (例: project_a): " PROFILE
read -p "同期元ディレクトリ (SOURCE) を入力してください (例: /workspace/my_project): " SOURCE
read -p "同期先ディレクトリ (TARGET) を入力してください (例: /home/rstudio/backup): " TARGET

# パスの展開 (チルダ等をフルパスに変換)
SOURCE_FULL=$(eval echo $SOURCE)
TARGET_FULL=$(eval echo $TARGET)

# ディレクトリの存在確認
if [ ! -d "$SOURCE_FULL" ]; then
    echo "エラー: 同期元 $SOURCE_FULL が見つかりません。"
    exit 1
fi
mkdir -p "$TARGET_FULL"

# --- 2. ~/.unison/$PROFILE.prf の作成 ---
mkdir -p ~/.unison

cat << EOF > ~/.unison/${PROFILE}.prf
# Unison Profile: $PROFILE
root = $SOURCE_FULL
root = $TARGET_FULL

# --- 動作設定 ---
batch = true
terse = true
# 競合時は、一旦スキップしてログに残す（手動実行で解決させる）
confirmbigdeletes = true

# --- 権限・属性の設定 ---
perms = 0
dontchmod = true

# --- 除外設定 (Quarto/Git/Python等に対応) ---
ignore = Path {.git,.quarto,.Rproj.user,.ipynb_checkpoints}
ignore = Name {*_cache,__pycache__,*.tmp,*.log,.DS_Store}
EOF

echo "設定ファイル ~/.unison/${PROFILE}.prf を作成しました。"

# --- 3. 同期用実行スクリプト (sync_$PROFILE.sh) の作成 ---
SYNC_SCRIPT="$HOME/sync_${PROFILE}.sh"

cat << EOF > "$SYNC_SCRIPT"
#!/bin/bash
# 自動生成された同期スクリプト

echo "Starting initial sync for $PROFILE..."
unison $PROFILE

echo "Monitoring changes in $SOURCE_FULL..."
fswatch -o "$SOURCE_FULL" | while read f; do
    # タイムスタンプを表示して同期実行
    echo "\$(date '+%Y-%m-%d %H:%M:%S') Change detected. Syncing..."
    unison $PROFILE
done
EOF

chmod +x "$SYNC_SCRIPT"
echo "実行スクリプト $SYNC_SCRIPT を作成しました。"

# --- 4. 同期スクリプトをバックグラウンドで起動 ---
# nohup を使うことで、ターミナルを閉じても動き続けるようにします
LOG_FILE="$HOME/unison_${PROFILE}.log"
nohup "$SYNC_SCRIPT" > "$LOG_FILE" 2>&1 &

echo "------------------------------------------------"
echo "同期をバックグラウンドで開始しました。"
echo "プロファイル: $PROFILE"
echo "ログファイル: $LOG_FILE"
echo "停止するには 'pkill -f sync_${PROFILE}.sh' を実行してください。"
echo "------------------------------------------------"
