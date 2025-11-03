#!/usr/bin/bash

# Node.js / npm / pnpm のセットアップ

# # 一旦 apt にある Node.js と npm をインストール
# apt-get update
# apt-get install -y --no-install-recommends nodejs npm
# 
# # Node バージョン管理ツールの n を導入し、2025-10-30 時点の Active LTS = v24系をインストール
# npm install -g n
# n v24
# hash -r
# source ~/.bashrc
# 
# # apt で入れた古い Node.js と npm をアンイストール
# apt-get purge -y nodejs npm
# apt-get autoremove -y
# apt-get clean
# rm -rf /var/lib/apt/lists/*

# 公式の npm 不要のインストールスクリプトで 2025-10-30 時点の Active LTS = v24系をインストール
# n 自身も改めて入れておく
wget -qO- https://raw.githubusercontent.com/tj/n/master/bin/n | bash -s install v24
npm install -g n

# pnpm をインストール
npm install -g pnpm

# ユーザー rstudio 用に pnpm を設定
# 安全のため、リリース後1週間以上経ったパッケージのみインストールできるようにする
su rstudio <<-EOF
pnpm setup
pnpm config set --location=global minimumReleaseAge 10080
EOF
