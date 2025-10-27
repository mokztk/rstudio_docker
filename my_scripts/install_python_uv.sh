#!/bin/bash
set -x

# uv を使った python セットアップ

# uv 関係の保存先
mkdir -p /opt/uv/bin /opt/uv/cache /opt/uv/python
chown -R root:staff /opt/uv
chmod -R 777 /opt/uv

# uv のインストール
# curl -LsSf https://astral.sh/uv/install.sh | sh
# cp /root/.local/bin/uv /opt/uv/bin
#
# 本番の Dockerfile ではインストーラーの代わりに
# COPY --from=ghcr.io/astral-sh/uv:0.9.4 /uv /opt/uv/bin/

export UV_CACHE_DIR=/opt/uv/cache
export UV_PYTHON_INSTALL_DIR=/opt/uv/python
export PATH="/opt/uv/bin:${PATH}"

# /opt/venv に仮想環境を作る
uv venv --python 3.12.12 /opt/venv
chown -R root:staff /opt/venv
chmod -R g+ws /opt/venv
source /opt/venv/bin/activate
uv pip install pip pandas seaborn
# uv pip install jedi radian

# reticulate インストール（pak でシステム依存パッケージも導入）
Rscript -e "install.packages('pak'); pak::pak('reticulate')"

# clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/downloaded_packages
strip /usr/local/lib/R/site-library/*/libs/*.so

rm -rf /opt/uv/cache/*

# reticulate が上記でインストールした python 3.12.12 を参照するようにする
cat << EOF >> /home/rstudio/.Renviron
#RETICULATE_PYTHON=/opt/uv/python/cpython-3.12.12-linux-x86_64-gnu/bin/python3.12
RETICULATE_PYTHON_ENV="/opt/venv"
EOF
chown rstudio:rstudio /home/rstudio/.Renviron

# RStudio server で起動した R セッションでも uv, python にパスが通るようにする
cat << EOF >> /home/rstudio/.Rprofile
# add uv to PATH
if (!("/opt/uv/bin" %in% unlist(strsplit(Sys.getenv("PATH"), ":")))) {
  Sys.setenv(PATH = paste0("/opt/uv/bin:", Sys.getenv("PATH")))
}

# add python to PATH
if (!("/opt/venv/bin" %in% unlist(strsplit(Sys.getenv("PATH"), ":")))) {
  Sys.setenv(PATH = paste0("/opt/venv/bin:", Sys.getenv("PATH")))
}
EOF
chown rstudio:rstudio /home/rstudio/.Rprofile

# bash起動時にvenvを有効にする
echo "source /opt/venv/bin/activate" >> /root/.bashrc
echo "source /opt/venv/bin/activate" >> /home/rstudio/.bashrc
chown rstudio:rstudio /home/rstudio/.bashrc

cat << EOF >> /home/rstudio/.bash_profile
if [ -f ~/.profile ]; then
  . ~/.profile
fi

. ~/.bashrc
EOF
chown rstudio:rstudio /home/rstudio/.bash_profile

cat << EOF >> /home/rstudio/.bashrc
# add uv to PATH
case ":\$PATH:" in
  *"/opt/uv/bin"*) ;;
  *) export PATH="/opt/uv/bin:\$PATH" ;;
esac
EOF

# # radianの設定
# cat << EOF > /home/rstudio/.radian_profile
# #options(radian.color_scheme = "monokai")
# options(radian.auto_match = TRUE)
# options(radian.highlight_matching_bracket = TRUE)
# options(radian.prompt = "\033[0;32mr$>\033[0m ")
# options(radian.escape_key_map = list(
#   list(key = "-", value = " <- "),
#   list(key = "m", value = " |> ")
# ))
# options(radian.force_reticulate_python = TRUE)
# EOF
# 
# cp /home/rstudio/.radian_profile /root
# chown rstudio:rstudio /home/rstudio/.radian_profile
