#!/usr/bin/bash

# Node.js / npm / pnpm のセットアップ

# 一旦 apt にある Node.js と npm をインストール
apt-get update
apt-get install -y --no-install-recommends nodejs npm

# Node バージョン管理ツールの n を導入し、2025-06 時点の最新 LTS = v22系をインストール
npm install -g n
n v22

# apt で入れた古い Node.js と npm をアンイストール
apt-get purge -y nodejs npm
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

# pnpm をインストール
source ~/.bashrc
npm install -g pnpm

# ユーザー rstudio 用に pnpm を設定
# 安全のため、リリース後1週間以上経ったパッケージのみインストールできるようにする
su rstudio <<-EOF
pnpm setup
source ~/.bashrc
pnpm config set --location=global minimumReleaseAge 10080
EOF
