#!/bin/bash

set -x

# radian: A 21 century R console.

# Ubuntu 24.04はPEP 668に従ってシステムPythonにインストールしようとするとエラーになるので
# 素直にvirtual envを使用する
/rocker_scripts/install_python.sh
source /opt/venv/bin/activate

# bash起動時にvenvを有効にする
echo "source /opt/venv/bin/activate" > /root/.bashrc
echo "source /opt/venv/bin/activate" > /home/rstudio/.bashrc
chown rstudio:rstudio /home/rstudio/.bashrc

cat << EOF > /home/rstudio/.bash_profile
if [ -f ~/.profile ]; then
  . ~/.profile
fi

. ~/.bashrc
EOF
chown rstudio:rstudio /home/rstudio/.bash_profile

# pandas, seabornをインストール
python3 -m pip --no-cache-dir install pandas seaborn

# radianのインストール
python3 -m pip --no-cache-dir install radian jedi

# radianの設定
cat > /home/rstudio/.radian_profile << EOF
#options(radian.color_scheme = "monokai")
options(radian.auto_match = TRUE)
options(radian.highlight_matching_bracket = TRUE)
options(radian.prompt = "\033[0;32mr$>\033[0m ")
options(radian.escape_key_map = list(
  list(key = "-", value = " <- "),
  list(key = "m", value = " |> ")
))
options(radian.force_reticulate_python = TRUE)
EOF

cp /home/rstudio/.radian_profile /root
chown rstudio:rstudio /home/rstudio/.radian_profile
