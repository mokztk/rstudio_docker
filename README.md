# About this image

- **rocker/r-ver** を元に rocker/tidyverse 相当のパッケージと日本語設定、頻用パッケージをインストールした作業用イメージ
    - rocker/tidyverse 相当のうち、容量の大きな dbplyr database backend は RSQLite 以外を省略
- 使用方法別に、2つのイメージを生成
    - **RStudio server**: rocker project オリジナルのインストールスクリプトで rocker/rstudio 相当の機能を追加
    - **SSH server**: RStudio server は導入せず、[Positron](https://positron.posit.co/) などから remote SSH 接続するため SSH server を起動
- CLI作業用に、[radian: A 21 century R console](https://github.com/randy3k/radian) と [Microsoft Edit](https://github.com/microsoft/edit) を追加する
- `reticulate` で最低限の python 連携も使用できるようにする
- [rocker-org/rocker-versioned2](https://github.com/rocker-org/rocker-versioned2) のように、目的別のスクリプトを使って Dockerfile 自体は極力シンプルにしてみる

```
# RStudio server, SSH server まとめて作成・起動
docker compose build
docker compose up -d

# 個別に build
docker compose rstudio
docker compose ssh

# または、docker compose を使わずに個別 build する場合
docker image build --target rstudio -t "mokztk/rstudio:4.5.0" .
docker image build --target ssh -t "mokztk/r_remote:4.5.0" .

# 個別に起動
docker run --rm -d -p 8787:8787 --name rstudio mokztk/rstudio:4.5.0
docker run --rm -d -p 2222:22 --name r_remote mokztk/r_remote:4.5.0
```

## 詳細

### Ubuntu mirror

arm64 が置かれていないミラーサーバーも多いので変更しない

### 日本語環境、フォント

- Ubuntu の `language-pack-ja`, `language-pack-ja-base`
- 環境変数で `ja_JP.UTF-8` ロケールとタイムゾーン `Asia/Tokyo` を指定
- 以下の日本語フォントを導入
    - **[Noto Sans/Serif JP](https://fonts.google.com/noto/fonts)**（"CJK"なし）
        - `fonts-noto-cjk-extra` は KR, SC, TC のフォントも含むので用途に対して大きすぎる（インストールサイズ 300MBほど）
        - Windows 11 に搭載された Noto Sans/Serif JP（"CJK"なし）と作図コードに互換性が確保できる
        - Github [notofonts/noto-cjk](https://github.com/notofonts/noto-cjk) から個別のOTF版をダウンロードして、XeLaTeX + BXjscls で "noto-jp" を指定する場合に必要な ７フォントと Noto Sans Mono CJK JP を手動でインストール
        - serif/sans/monospace の標準日本語フォントとして設定
        - 過去コードの文字化け回避のため、Noto Sans/Serif CJK JP を Noto Sans/Serif JP の別名として登録しておく
    - **[UDEV Gothic](https://github.com/yuru7/udev-gothic)**
        - BIZ UD Gothic + JetBrains Mono の合成フォント
        - 半角:全角 3:5版ではなく、通常の1:2でリガチャ有効のバージョン（UDEVGothicLG-*.ttf）を使用
        - RStudio Serverのエディタ用カスタムフォントとして導入

### R の頻用パッケージ

- [インストール済みのパッケージ一覧](package_list.md)
- 容量節約のため、`dependencies = NA` の指定とし、インストール後にDLしたアーカイブは削除
- rockerのスクリプトに倣い、インストール後にRSPMのバイナリパッケージで導入された *.so を整理

### Python3 & [radian: A 21 century R console](https://github.com/randy3k/radian)

- rocker project で用意されている `/rocker_scripts/install_python.sh` を利用して Python3 をインストール
- 上記スクリプトで作成される仮想環境 `/opt/venv` に以下をインストールする
    - `pansdas` (Numpy)
    - `seaborn` (Matplotlib)
    - `radian`
    - `jedi` （radian でのコード補完に必要）

radian をホストPCで使うときは

```
docker exec -it <container name> /opt/venv/bin/radian
```

### Node.js / npm / pnpm

[Gemini CLI](https://github.com/google-gemini/gemini-cli) などを導入できるよう、 n（Node.js のバージョンマネージャー）経由で Ubuntu の apt にあるバージョンより新しいものを導入

- 2025-06現在の LTS である Node v22系＋ npm v10系
- [pnpm](https://pnpm.io/ja/): ユーザー rstudio が利用する場合、リリース後1週間以上経過したパッケージのみに制限

### [Microsoft Edit](https://github.com/microsoft/edit)

- CLI用のテキストエディタがないので、`msedit` の名前で使用できるように導入しておく

### TinyTeX

- Quarto-Typst で日本語PDFも作成できほぼ使わななくなったため、TinyTeX はパッケージはインストールしてあるがセットアップをしていない状態
- 必要に応じてユーザー `rstudio` 権限でセットアップスクリプト `/my_script/install_tinytex.sh` を実行する（RStudio の Terminal で可）
    - R4.3系以降メンテナンスしていないが、TeX Live 2022 frozen ベースで LuaLaTeX / XeLaTeX で日本語PDFを作成できる環境が準備できるはず

### 環境変数 PASSWORD の仮設定（RStudio Server 版）

- 初期パスワード `rstudio` のままでは RStudio Server が使用できないので、Docker Desktop など -e PASSWORD=... が設定できないGUIでも起動テストできるように仮のパスワード `password` を埋め込んでおく
- 更に、普段使いのため `DISABLE_AUTH=true` を埋め込む。パスワードが必要なときは、起動時に `-e DISABLE_AUTH=false`

### rootless モードの解除 (RStudio server 版)

- arm64版の rocker/rstudio は rootless モードで動いており、起動時にユーザー rstudio が削除される
- amd64(x86_64)版と設定ファイルなどを共用するために rootless モードを解除して、従来どおりユーザー rstudio を使用する
- 今後、amd64 も rootless になるようならば要検討

### 公開鍵暗号による remote SSH 接続（SSH server 版）

パスワード認証（ユーザー・パスワードとも `rstudio`）での SSH 接続に加えて、`/home/rstudio/.ssh/authorized_keys` に公開鍵を登録すればパスワード不要の公開鍵暗号での接続も可能になる。

## History

- **2020-11-02** [Gist: mokztk/R4.0_2020Oct.Docerfile](https://gist.github.com/mokztk/be9e0d8982fd32987dbb5c9552a9d4a7) から改めてレポジトリとして編集を開始
- **2020-11-02** 🔖[4.0.2_2020Oct](https://github.com/mokztk/RStudio_docker/releases/tag/4.0.2_2020Oct) : `rocker/tidyverse:4.0.2` 対応版 
- **2021-01-14** 🔖[4.0.2_update2101](https://github.com/mokztk/RStudio_docker/releases/tag/4.0.2_update2101) : 4.0.2_2020Oct の修正版 
- **2021-03-06** 🔖[4.0.2_2021Jan](https://github.com/mokztk/RStudio_docker/releases/tag/4.0.2_2021Jan) : `rocker/tidyverse:4.0.2` ベースのままパッケージを更新
- **2021-03-11** 🔖[4.0.3_2020Feb](https://github.com/mokztk/RStudio_docker/releases/tag/4.0.3_2021Feb) : `rocker/tidyverse:4.0.3` にあわせて更新
- **2021-04-01**  ブランチ構成を再編（GitHub flow モドキ）
- **2021-04-04** 🔖[4.0.3_TL2020](https://github.com/mokztk/RStudio_docker/releases/tag/4.0.3_TL2020) : TeX を TeX Live 2020 (frozen) に固定
- **2021-04-13** 🔖[4.0.3_update2104](https://github.com/mokztk/RStudio_docker/releases/tag/4.0.3_update2104) : 4.0.3_TL2020 の修正版
- **2021-08-30** 🔖[4.1.0_2021Aug](https://github.com/mokztk/RStudio_docker/releases/tag/4.1.0_2021Aug) : `rocker/tidyverse:4.1.0` にあわせて更新。coding font 追加
- **2021-09-22** 🔖[4.1.0_2021Aug_r2](https://github.com/mokztk/RStudio_docker/releases/tag/4.1.0_2021Aug_r2) : PlemolJP フォントを最新版に差し替え（記号のズレ対策）
- **2021-11-11** 🔖[4.1.1_2021Oct](https://github.com/mokztk/RStudio_docker/releases/tag/4.1.1_2021Oct) : `rocker/tidyverse:4.1.1` にあわせて更新。フォント周りを中心に整理
- **2022-06-07** 🔖[4.2.0_2022Jun](https://github.com/mokztk/RStudio_docker/releases/tag/4.2.0_2022Jun) : ベースを `rocker/tidyverse:4.2.0` （2022-06-02版）に更新。Quartoの導入、フォントの変更など
- **2022-06-24** 🔖[4.2.0_2022Jun_2](https://github.com/mokztk/RStudio_docker/releases/tag/4.2.0_2022Jun_2) : ベースを `rocker/tidyverse:4.2.0` snapshot確定版に更新。Quarto関係を修正
- **2023-04-06** 🔖[4.2.2_2023Mar](https://github.com/mokztk/RStudio_docker/releases/tag/4.2.2_2023Mar) : `rocker/tidyverse:4.2.2` にあわせて更新。ARM64版を試作
- **2023-06-21** 🔖[4.2.2_2023Mar_2](https://github.com/mokztk/RStudio_docker/releases/tag/4.2.2_2023Mar_2) : Noto Sans JP フォントの導入に失敗していたのを修正
- **2023-06-23** 🔖[4.3.0_2023Jun](https://github.com/mokztk/RStudio_docker/releases/tag/4.3.0_2023Jun) : `rocker/tidyverse:4.3.0` にあわせて更新
- **2024-04-26** 🔖[4.3.3_2024Apr](https://github.com/mokztk/RStudio_docker/releases/tag/4.3.3_2024Apr) : `rocker/rstudio:4.3.3` をベースにQuarto 1.4を追加。Amd64/Arm64のDockerfileを1本化
- **2025-03-06** 🔖[4.4.2_2025Mar](https://github.com/mokztk/RStudio_docker/releases/tag/4.4.2_2025Mar) : `rocker/rstudio:4.4.2` ベースに更新
- **2025-06-15** 🔖[4.5.0_2025Jun](https://github.com/mokztk/RStudio_docker/releases/tag/4.5.0_2025Jun) : `rocker/rstudio:4.5.0` ベースに更新。remote SSH接続できるよう設定を追加
- **2025-10-15** RStudio server版（こちらからは remote SSH 接続を削除）と remote SSH 版を一本化
