#!/bin/bash

# sshd を起動時に実行する

mkdir /var/run/sshd
# mkdir /etc/services.d/sshd
#
# cat << EOF > /etc/services.d/sshd/run
# #!/usr/bin/execlineb -P
# /usr/sbin/sshd -D -e
# EOF
#
# chmod 755 /etc/services.d/sshd/run

# 公開鍵を置くディレクトリをユーザー rstudio で作っておく
mkdir /home/rstudio/.ssh/
chown -R rstudio:rstudio /home/rstudio/.ssh/

# 作業用ディレクトリ
mkdir /workspace
chmod 777 /workspace
